import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../tasks/data/metric_catalog.dart';
import '../../tasks/providers/measurement_definition_provider.dart';
import '../../tasks/providers/measurement_record_providers.dart';
import '../../tasks/providers/task_providers.dart';

/// State: `batchCode` được chọn để xem growth log. '' = tất cả batches.
final selectedGrowthBatchIdProvider = StateProvider<String>((ref) => '');

/// State: experimentId được chọn. Nếu rỗng → dùng tất cả records.
final selectedGrowthExperimentIdProvider = StateProvider<String>((ref) => '');

/// Danh sách batchId mà student có task (Observation / Measurement) phụ trách.
/// Dùng để load growth log khi user chưa chọn batch.
final _studentBatchesFromTasksProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final tasks = await ref.read(taskRepoProvider).getMyTasks();
  final ids = <String>{};
  for (final t in tasks) {
    if (t.batchId != null && t.batchId!.isNotEmpty) ids.add(t.batchId!);
  }
  return ids.toList();
});

/// Tất cả records của student (mọi batch user phụ trách).
///
/// Logic:
/// 1. Lấy tất cả `batchIds` user có task Observation/Measurement phụ trách.
/// 2. Gọi `getRecordsByBatch(batchId)` cho mỗi batchId song song → dedupe.
/// 3. UI filter theo `selectedGrowthBatchIdProvider` (batchCode) ở client.
final growthRecordsProvider =
    FutureProvider.autoDispose<List<MeasurementRecordModel>>((ref) async {
  final repo = ref.read(measurementRecordRepositoryProvider);

  // Tổng hợp từ tất cả batchIds user phụ trách (parallel).
  final batchIds = await ref.watch(_studentBatchesFromTasksProvider.future);
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

/// Records đã filter theo batchCode client-side.
final effectiveGrowthRecordsProvider =
    Provider<AsyncValue<List<MeasurementRecordModel>>>((ref) {
  final recordsAsync = ref.watch(growthRecordsProvider);
  final batchCode = ref.watch(selectedGrowthBatchIdProvider);
  if (batchCode.isEmpty) return recordsAsync;
  return recordsAsync.whenData(
    (list) => list.where((r) => r.batchCode == batchCode).toList(),
  );
});

/// Records đã filter theo metricName.
final filteredGrowthRecordsProvider =
    Provider<AsyncValue<List<MeasurementRecordModel>>>((ref) {
  return ref.watch(effectiveGrowthRecordsProvider);
});

/// Danh sách batch codes duy nhất từ records để filter.
///
/// Fallback: nếu record trả về `batchId` không null nhưng `batchCode` là null
/// thì dùng `batchId` làm code để đảm bảo strip luôn có dữ liệu.
final availableBatchCodesProvider =
    Provider<List<String>>((ref) {
  final records = ref.watch(growthRecordsProvider);
  return records.when(
    data: (list) {
      final codes = list
          .map((r) => (r.batchCode != null && r.batchCode!.isNotEmpty)
              ? r.batchCode!
              : (r.batchId.isNotEmpty ? r.batchId : ''))
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
final heightChartSpotsProvider = Provider<List<FlSpot>>((ref) {
  final records = ref.watch(effectiveGrowthRecordsProvider);
  return records.when(
    data: (list) => _buildSpots(list, 'height'),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Chart data: leafCount theo ngày.
final leafCountChartSpotsProvider = Provider<List<FlSpot>>((ref) {
  final records = ref.watch(effectiveGrowthRecordsProvider);
  return records.when(
    data: (list) => _buildSpots(list, 'leafCount'),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Tập `experimentId` xuất hiện trong records hiện tại (đã filter theo batch).
final _experimentIdsInRecordsProvider = Provider.autoDispose<Set<String>>((ref) {
  final records = ref.watch(effectiveGrowthRecordsProvider);
  return records.maybeWhen(
    data: (list) => list.map((r) => r.experimentId).where((id) => id.isNotEmpty).toSet(),
    orElse: () => <String>{},
  );
});

/// Map `definitionId → MeasurementDefinitionInfo` (merge từ tất cả experiments
/// xuất hiện trong records). null nếu vẫn đang load.
final growthDefinitionsProvider =
    Provider<Map<String, MeasurementDefinitionInfo>?>((ref) {
  final ids = ref.watch(_experimentIdsInRecordsProvider);
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

/// Cờ: student đã ghi nhận hôm nay.
final hasTodayRecordProvider = Provider<bool>((ref) {
  final records = ref.watch(growthRecordsProvider);
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

List<FlSpot> _buildSpots(List<MeasurementRecordModel> records, String metric) {
  // Nhóm theo ngày → lấy trung bình.
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
  // X = số thứ tự ngày (1, 2, 3...), Y = giá trị trung bình.
  return sortedKeys.asMap().entries.map((e) {
    final dayNum = e.key + 1;
    final vals = byDate[e.value]!;
    final avg = vals.isEmpty
        ? 0.0
        : vals.reduce((double a, double b) => a + b) / vals.length;
    return FlSpot(dayNum.toDouble(), avg);
  }).toList();
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class GrowthLogScreen extends ConsumerWidget {
  const GrowthLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final hasToday = ref.watch(hasTodayRecordProvider);
    final recordsAsync = ref.watch(growthRecordsProvider);
    final heightSpots = ref.watch(heightChartSpotsProvider);
    final leafSpots = ref.watch(leafCountChartSpotsProvider);
    final batchCodes = ref.watch(availableBatchCodesProvider);
    final selectedBatch = ref.watch(selectedGrowthBatchIdProvider);
    final defMap = ref.watch(growthDefinitionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nhật ký tăng trưởng'),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          if (batchCodes.isNotEmpty)
            PopupMenuButton<String>(
              icon: Badge(
                isLabelVisible: selectedBatch.isNotEmpty,
                child: const Icon(Icons.filter_list_rounded),
              ),
              tooltip: 'Lọc theo batch',
              onSelected: (code) {
                ref.read(selectedGrowthBatchIdProvider.notifier).state =
                    code == selectedBatch ? '' : code;
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: '',
                  child: Row(
                    children: [
                      Icon(
                        selectedBatch.isEmpty
                            ? Icons.check_rounded
                            : Icons.crop_square_rounded,
                        size: 18,
                        color: selectedBatch.isEmpty
                            ? AppColors.primary
                            : cs.onSurface,
                      ),
                      const SizedBox(width: 8),
                      const Text('Tất cả batches'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ...batchCodes.map((code) => PopupMenuItem<String>(
                      value: code,
                      child: Row(
                        children: [
                          Icon(
                            selectedBatch == code
                                ? Icons.check_rounded
                                : Icons.crop_square_rounded,
                            size: 18,
                            color: selectedBatch == code
                                ? AppColors.primary
                                : cs.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(code),
                        ],
                      ),
                    )),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Batch selector strip nổi bật — luôn hiển thị khi có ít nhất 1 record.
          if (recordsAsync.maybeWhen(
              data: (l) => l.isNotEmpty, orElse: () => false))
            _BatchSelectorStrip(
              batchCodes: batchCodes,
              selectedBatch: selectedBatch,
              onChanged: (code) => ref
                      .read(selectedGrowthBatchIdProvider.notifier)
                      .state =
                  code == selectedBatch ? '' : code,
            ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text('Lỗi tải dữ liệu', style: tt.titleMedium),
                    const SizedBox(height: 4),
                    Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(growthRecordsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return _EmptyRecordsState(tt: tt, cs: cs);
                }
                return _GrowthLogContent(
                  records: records,
                  heightSpots: heightSpots,
                  leafSpots: leafSpots,
                  defMap: defMap,
                  tt: tt,
                  cs: cs,
                  hasToday: hasToday,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Strip nổi bật cho phép chọn batch trực tiếp (không cần mở popup).
class _BatchSelectorStrip extends StatelessWidget {
  const _BatchSelectorStrip({
    required this.batchCodes,
    required this.selectedBatch,
    required this.onChanged,
  });

  final List<String> batchCodes;
  final String selectedBatch;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outline.withAlpha(40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_module_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Xem theo Batch',
                  style: tt.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _BatchChip(
                  label: 'Tất cả',
                  isSelected: selectedBatch.isEmpty,
                  onTap: () => onChanged(''),
                ),
                ...batchCodes.map((code) => _BatchChip(
                      label: code,
                      isSelected: selectedBatch == code,
                      onTap: () => onChanged(code),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchChip extends StatelessWidget {
  const _BatchChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : cs.outline.withAlpha(77),
            ),
          ),
          child: Text(
            label,
            style: tt.labelMedium?.copyWith(
              color: isSelected ? Colors.white : cs.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _GrowthLogContent extends StatelessWidget {
  const _GrowthLogContent({
    required this.records,
    required this.heightSpots,
    required this.leafSpots,
    required this.defMap,
    required this.tt,
    required this.cs,
    required this.hasToday,
  });

  final List<MeasurementRecordModel> records;
  final List<FlSpot> heightSpots;
  final List<FlSpot> leafSpots;
  final Map<String, MeasurementDefinitionInfo>? defMap;
  final TextTheme tt;
  final ColorScheme cs;
  final bool hasToday;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heightSpots.isNotEmpty || leafSpots.isNotEmpty) ...[
            Text('Biểu đồ tăng trưởng',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            _GrowthChart(
              heightSpots: heightSpots,
              leafCountSpots: leafSpots,
              tt: tt,
              cs: cs,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              Text('Lịch sử ghi nhận',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${records.length} bản ghi',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...records.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _GrowthRecordCard(
                  record: r,
                  defMap: defMap,
                  tt: tt,
                  cs: cs,
                ),
              )),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatefulWidget {
  const _GrowthChart({
    required this.heightSpots,
    required this.leafCountSpots,
    required this.tt,
    required this.cs,
  });

  final List<FlSpot> heightSpots;
  final List<FlSpot> leafCountSpots;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  State<_GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<_GrowthChart> {
  bool _showLeafCount = false;

  @override
  Widget build(BuildContext context) {
    final spots = _showLeafCount ? widget.leafCountSpots : widget.heightSpots;
    final color = _showLeafCount ? AppColors.success : AppColors.accent;
    final label = _showLeafCount ? 'Số lá' : 'Chiều cao (cm)';

    return SNMSCard(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(label,
                  style: widget.tt.labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600)),
              const Spacer(),
              ToggleButtons(
                isSelected: [!_showLeafCount, _showLeafCount],
                onPressed: (index) =>
                    setState(() => _showLeafCount = index == 1),
                borderRadius: BorderRadius.circular(8),
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 28),
                fillColor: color.withAlpha(25),
                selectedColor: color,
                color: widget.cs.onSurface.withAlpha(128),
                textStyle: widget.tt.labelSmall,
                children: const [Text('Cao'), Text('Lá')],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text('Chưa có đủ dữ liệu',
                        style: widget.tt.bodyMedium
                            ?.copyWith(color: widget.cs.onSurface.withAlpha(128))))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _showLeafCount ? 2 : 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                            color: widget.cs.outline.withAlpha(51), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: _showLeafCount ? 2 : 5,
                            getTitlesWidget:
                                (value, meta) => Text(
                              '${value.toInt()}',
                              style: widget.tt.labelSmall?.copyWith(
                                  color: widget.cs.onSurface.withAlpha(102)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: (spots.length / 5).ceilToDouble().clamp(1, 10),
                            getTitlesWidget:
                                (value, meta) => Text(
                              'D${value.toInt()}',
                              style: widget.tt.labelSmall?.copyWith(
                                  color: widget.cs.onSurface.withAlpha(102)),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData:
                              BarAreaData(show: true, color: color.withAlpha(25)),
                        ),
                      ],
                      minY: (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) -
                                  2)
                              .clamp(0, double.infinity),
                      maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrowthRecordCard extends StatelessWidget {
  const _GrowthRecordCard({
    required this.record,
    required this.defMap,
    required this.tt,
    required this.cs,
  });

  final MeasurementRecordModel record;
  final Map<String, MeasurementDefinitionInfo>? defMap;
  final TextTheme tt;
  final ColorScheme cs;

  /// Resolve `metricName` theo thứ tự ưu tiên:
  /// 1. Cache definitions (nếu đã load).
  /// 2. Record.measurementDefinitionName (API populate).
  /// 3. Fallback null.
  String? _resolveMetricName() {
    final def = defMap?[record.measurementDefinitionId];
    if (def != null && def.metricName.isNotEmpty) return def.metricName;
    final fromRecord = record.measurementDefinitionName;
    if (fromRecord != null && fromRecord.isNotEmpty) return fromRecord;
    return null;
  }

  /// Label tiếng Việt (ưu tiên MetricCatalog).
  String get _metricLabel {
    final name = _resolveMetricName();
    final display = MetricCatalog.lookup(name);
    if (display != null) return display.label;
    return MetricCatalog.fallback(name).label;
  }

  String get _unit {
    // �u tiên unit từ definition cache (chuẩn nhất).
    final def = defMap?[record.measurementDefinitionId];
    if (def?.unit != null && def!.unit!.isNotEmpty) return def.unit!;
    // Fallback 1: t� MetricCatalog.
    final name = _resolveMetricName();
    final catalogUnit = MetricCatalog.lookup(name)?.unit;
    if (catalogUnit != null && catalogUnit.isNotEmpty) return catalogUnit;
    // Fallback 2: từ extraData.
    final extra = record.extraData;
    if (extra != null && extra.containsKey('unit')) {
      return extra['unit']?.toString() ?? '';
    }
    return '';
  }

  Color _getMetricColor() {
    final name = _metricLabel.toLowerCase();
    if (name.contains('chiều cao') || name.contains('sinh trưởng')) {
      return AppColors.accent;
    }
    if (name.contains('lá')) return AppColors.success;
    if (name.contains('nước') || name.contains('tưới')) return AppColors.info;
    if (name.contains('phân') || name.contains('độ ẩm')) return AppColors.warning;
    if (name.contains('sản lượng') || name.contains('khối lượng')) {
      return AppColors.primary;
    }
    if (name.contains('sống') || name.contains('đậu quả')) return AppColors.success;
    return AppColors.info;
  }

  IconData _getMetricIcon() {
    final name = _metricLabel.toLowerCase();
    if (name.contains('chiều cao') || name.contains('sinh trưởng')) {
      return Icons.height_rounded;
    }
    if (name.contains('lá')) return Icons.eco_rounded;
    if (name.contains('sinh khối') || name.contains('sản lượng')) {
      return Icons.scale_rounded;
    }
    if (name.contains('nước') || name.contains('tưới')) {
      return Icons.water_drop_rounded;
    }
    if (name.contains('phân')) return Icons.science_rounded;
    if (name.contains('độ ẩm')) return Icons.opacity_rounded;
    return Icons.straighten_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMetricColor();
    final dateStr = DateFormat('dd/MM').format(record.measuredAt);
    final timeStr = DateFormat('HH:mm').format(record.measuredAt);
    final hasUnit = _unit.isNotEmpty;
    final isInt = record.value == record.value.roundToDouble();
    final valueStr = record.value.toStringAsFixed(isInt ? 0 : 1);

    return SNMSCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getMetricIcon(), color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _metricLabel,
                        style: tt.labelMedium?.copyWith(
                            color: color, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Builder(builder: (_) {
                      // Ưu tiên batchCode; fallback batchId nếu code rỗng.
                      final code = (record.batchCode != null &&
                              record.batchCode!.isNotEmpty)
                          ? record.batchCode!
                          : (record.batchId.isNotEmpty ? record.batchId : null);
                      if (code == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(80),
                              width: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco_rounded,
                                size: 11, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(
                              code.length > 14
                                  ? '${code.substring(0, 12)}…'
                                  : code,
                              style: tt.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueStr,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (hasUnit) ...[
                      const SizedBox(width: 4),
                      Text(
                        _unit,
                        style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withAlpha(153),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                if (record.measuredByName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'bởi ${record.measuredByName}',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurface.withAlpha(128)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dateStr,
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(153),
                      fontWeight: FontWeight.w600)),
              Text(timeStr,
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurface.withAlpha(102))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRecordsState extends StatelessWidget {
  const _EmptyRecordsState({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: cs.onSurface.withAlpha(51)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có dữ liệu ghi nhận',
              style: tt.titleMedium?.copyWith(
                  color: cs.onSurface.withAlpha(153)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy hoàn thành các task đo lường\nđể dữ liệu hiển thị tại đây.',
              style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withAlpha(102)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
