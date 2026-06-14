import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../mock/mock_growth_data.dart';

final selectedBatchIdProvider = StateProvider<String>((ref) => 'batch-ctrl-01');

final filteredGrowthRecordsProvider = Provider<List<GrowthRecordModel>>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  return mockGrowthRecords.where((r) => r.batchId == batchId).toList()
    ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
});

final chartDataProvider = Provider<List<FlSpot>>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  final now = DateTime.now();
  final spots = <FlSpot>[];

  for (int i = 13; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final record = mockGrowthRecords.where((r) =>
      r.batchId == batchId &&
      r.recordedAt.year == date.year &&
      r.recordedAt.month == date.month &&
      r.recordedAt.day == date.day
    ).toList();

    if (record.isNotEmpty) {
      spots.add(FlSpot((14 - i).toDouble(), record.first.plantHeight));
    }
  }
  return spots;
});

final hasTodayRecordProvider = Provider<bool>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  final now = DateTime.now();
  return mockGrowthRecords.any((r) =>
    r.batchId == batchId &&
    r.recordedAt.year == now.year &&
    r.recordedAt.month == now.month &&
    r.recordedAt.day == now.day
  );
});

final observationCountProvider = Provider<int>((ref) {
  return mockGrowthRecords.where((r) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return r.recordedAt.isAfter(weekAgo);
  }).length;
});
