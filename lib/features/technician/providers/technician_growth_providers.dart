library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../tasks/providers/measurement_batch_providers.dart';
import '../../tasks/providers/measurement_definition_provider.dart';
import '../../tasks/providers/measurement_record_providers.dart';
import 'technician_my_tasks_provider.dart';

/// State: `batchCode` được chọn để xem growth log. '' = tất cả batches.
final selectedTechnicianGrowthBatchIdProvider =
    StateProvider<String>((ref) => '');

/// Danh sách batchId mà technician có task phụ trách.
final _technicianBatchesFromTasksProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final tasksAsync = ref.watch(technicianMyTasksFlatProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) {
      final ids = <String>{};
      for (final t in tasks) {
        if (t.batchId != null && t.batchId!.isNotEmpty) ids.add(t.batchId!);
      }
      return ids.toList();
    },
    orElse: () => <String>[],
  );
});

/// Set các `batchId` xuất hiện trong growth records (dùng cho lazy fetch).
final _technicianBatchIdsInRecordsProvider =
    Provider.autoDispose<Set<String>>((ref) {
  final records = ref.watch(technicianGrowthRecordsProvider);
  return records.maybeWhen(
    data: (list) =>
        list.map((r) => r.batchId).where((id) => id.isNotEmpty).toSet(),
    orElse: () => <String>{},
  );
});

/// Map `batchId → batchCode` cho Technician. Lazy fetch từ `/batches/{id}`
/// khi backend không populate `batchCode` trong MeasurementRecordModel.
final technicianBatchCodeByBatchIdProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  // 1. Từ technician task list (sync).
  final fromTasks = <String, String>{};
  final tasksAsync = ref.watch(technicianMyTasksFlatProvider);
  tasksAsync.maybeWhen(
    data: (tasks) {
      for (final t in tasks) {
        if (t.batchId != null && t.batchId!.isNotEmpty &&
            t.batchCode != null && t.batchCode!.isNotEmpty) {
          fromTasks[t.batchId!] = t.batchCode!;
        }
      }
    },
    orElse: () {},
  );

  // 2. Lazy fetch các batchId chưa có từ task list.
  final pendingIds =
      ref.watch(_technicianBatchIdsInRecordsProvider).toList()
        ..removeWhere(fromTasks.containsKey);
  final fromApi = <String, String>{};
  await Future.wait(pendingIds.map((id) async {
    try {
      final info = await ref.read(batchInfoProvider(id).future);
      if (info != null &&
          info.batchCode != null &&
          info.batchCode!.isNotEmpty) {
        fromApi[id] = info.batchCode!;
      }
    } catch (_) {
      // ignore: giữ UUID fallback
    }
  }));

  return {...fromTasks, ...fromApi};
});

/// Tất cả records của Technician (mọi batch user phụ trách).
final technicianGrowthRecordsProvider =
    FutureProvider.autoDispose<List<MeasurementRecordModel>>((ref) async {
  final repo = ref.read(measurementRecordRepositoryProvider);

  final batchIds =
      await ref.watch(_technicianBatchesFromTasksProvider.future);
  if (batchIds.isEmpty) return const [];

  final responses = await Future.wait(
    batchIds.map((id) async {
      try {
        return await repo.getRecordsByBatch(id);
      } catch (_) {
        return <MeasurementRecordModel>[];
      }
    }),
  );
  final seen = <String>{};
  final merged = <MeasurementRecordModel>[];
  for (final list in responses) {
    for (final r in list) {
      if (seen.add(r.id)) merged.add(r);
    }
  }
  merged.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  return merged;
});

/// Records đã filter theo batchCode.
final effectiveTechnicianGrowthRecordsProvider =
    Provider<AsyncValue<List<MeasurementRecordModel>>>((ref) {
  final recordsAsync = ref.watch(technicianGrowthRecordsProvider);
  final batchCode = ref.watch(selectedTechnicianGrowthBatchIdProvider);
  if (batchCode.isEmpty) return recordsAsync;
  final batchMapAsync = ref.watch(technicianBatchCodeByBatchIdProvider);
  final batchMap = batchMapAsync.maybeWhen(
    data: (m) => m,
    orElse: () => <String, String>{},
  );
  return recordsAsync.whenData(
    (list) => list.where((r) {
      final code = (r.batchCode != null && r.batchCode!.isNotEmpty)
          ? r.batchCode
          : batchMap[r.batchId];
      return code == batchCode;
    }).toList(),
  );
});

/// Danh sách batch codes duy nhất từ records.
final availableTechnicianBatchCodesProvider = Provider<List<String>>((ref) {
  final records = ref.watch(technicianGrowthRecordsProvider);
  final batchMapAsync = ref.watch(technicianBatchCodeByBatchIdProvider);
  final knownMap = batchMapAsync.maybeWhen(
    data: (m) => m,
    orElse: () => <String, String>{},
  );
  return records.when(
    data: (list) {
      final codes = list
          .map((r) => (r.batchCode != null && r.batchCode!.isNotEmpty)
              ? r.batchCode!
              : (knownMap[r.batchId] ??
                  (r.batchId.isNotEmpty ? r.batchId : '')))
          .where((c) => c.isNotEmpty)
          .toSet()
          .cast<String>()
          .toList();
      codes.sort();
      return codes;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Chart data: height theo ngày.
final technicianHeightChartSpotsProvider = Provider<List<FlSpot>>((ref) {
  final records = ref.watch(effectiveTechnicianGrowthRecordsProvider);
  return records.when(
    data: (list) => _buildGrowthSpots(list, 'height'),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Chart data: leafCount theo ngày.
final technicianLeafCountChartSpotsProvider = Provider<List<FlSpot>>((ref) {
  final records = ref.watch(effectiveTechnicianGrowthRecordsProvider);
  return records.when(
    data: (list) => _buildGrowthSpots(list, 'leafCount'),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Tập `experimentId` xuất hiện trong records.
final _technicianExperimentIdsInRecordsProvider =
    Provider.autoDispose<Set<String>>((ref) {
  final records = ref.watch(effectiveTechnicianGrowthRecordsProvider);
  return records.maybeWhen(
    data: (list) =>
        list.map((r) => r.experimentId).where((id) => id.isNotEmpty).toSet(),
    orElse: () => <String>{},
  );
});

/// Map `definitionId → MeasurementDefinitionInfo`.
final technicianGrowthDefinitionsProvider =
    Provider<Map<String, MeasurementDefinitionInfo>?>((ref) {
  final ids = ref.watch(_technicianExperimentIdsInRecordsProvider);
  if (ids.isEmpty) return const {};
  final merged = <String, MeasurementDefinitionInfo>{};
  bool anyLoading = false;
  for (final expId in ids) {
    final async = ref.watch(measurementDefinitionsByExperimentProvider(expId));
    async.when(
      data: (m) => merged.addAll(m),
      loading: () => anyLoading = true,
      error: (_, __) => anyLoading = true,
    );
  }
  return anyLoading && merged.isEmpty ? null : merged;
});

/// Cờ: technician đã ghi nhận hôm nay.
final technicianHasTodayRecordProvider = Provider<bool>((ref) {
  final records = ref.watch(technicianGrowthRecordsProvider);
  return records.when(
    data: (list) {
      final today = DateTime.now();
      return list.any((r) =>
          r.measuredAt.year == today.year &&
          r.measuredAt.month == today.month &&
          r.measuredAt.day == today.day);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// ─── Helpers ────────────────────────────────────────────────────────────────

List<FlSpot> _buildGrowthSpots(
    List<MeasurementRecordModel> records, String metric) {
  final byDate = <String, List<double>>{};
  for (final r in records) {
    if (r.measurementDefinitionName == null) continue;
    final name = r.measurementDefinitionName!.trim().toLowerCase();
    final targetName = metric.toLowerCase();
    if (!name.contains(targetName)) continue;
    final key = DateFormat('yyyy-MM-dd').format(r.measuredAt);
    byDate.putIfAbsent(key, () => []).add(r.value);
  }

  if (byDate.isEmpty) return [];

  final sortedKeys = byDate.keys.toList()..sort();
  return sortedKeys.asMap().entries.map((e) {
    final dayNum = e.key + 1;
    final vals = byDate[e.value]!;
    final avg = vals.isEmpty
        ? 0.0
        : vals.reduce((double a, double b) => a + b) / vals.length;
    return FlSpot(dayNum.toDouble(), avg);
  }).toList();
}
