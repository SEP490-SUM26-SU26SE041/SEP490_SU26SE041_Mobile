import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../tasks/data/metric_catalog.dart';
import '../../tasks/providers/measurement_definition_provider.dart';

/// Shared UI cho màn hình "Nhật ký tăng trưởng" — dùng cho cả Student và
/// Technician. Screen chỉ watch providers riêng của role → truyền data vào
/// widget này, không chứa business logic.
///
/// Props:
/// - [records]: list records đã filter theo batch (sẵn sàng render)
/// - [heightSpots] / [leafCountSpots]: chart data
/// - [batchCodes]: list batch codes để hiển thị chip + popup
/// - [selectedBatch]: code đang chọn ('' = tất cả)
/// - [defMap]: map definitionId → MeasurementDefinitionInfo
/// - [batchMap]: map batchId → batchCode (từ provider resolve batchCode)
/// - [isBatchMapLoading]: c� hiển thị loading badge trên record card
/// - [onBatchChanged]: callback khi user chọn batch
/// - [onRefresh]: callback khi nhấn "Thử lại"
/// - [title]: AppBar title (mặc định "Nhật ký tăng trưởng")
/// - [emptyHint]: hint ở empty state (mặc định "Hãy hoàn thành các task đo lường...")
class GrowthLogView extends StatelessWidget {
  const GrowthLogView({
    super.key,
    required this.records,
    required this.heightSpots,
    required this.leafCountSpots,
    required this.batchCodes,
    required this.selectedBatch,
    required this.batchMap,
    required this.defMap,
    required this.isBatchMapLoading,
    required this.onBatchChanged,
    required this.onRefresh,
    this.title = 'Nhật ký tăng trưởng',
    this.emptyHint = 'Hãy hoàn thành các task đo lường\nđể dữ liệu hiển thị tại đây.',
  });

  final List<MeasurementRecordModel> records;
  final List<FlSpot> heightSpots;
  final List<FlSpot> leafCountSpots;
  final List<String> batchCodes;
  final String selectedBatch;
  final Map<String, String> batchMap;
  final bool isBatchMapLoading;
  final Map<String, MeasurementDefinitionInfo>? defMap;
  final ValueChanged<String> onBatchChanged;
  final VoidCallback onRefresh;
  final String title;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(title),
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
              onSelected: (code) => onBatchChanged(
                code == selectedBatch ? '' : code,
              ),
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 80,
                        ),
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
                            Expanded(
                              child: Text(
                                code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (records.isNotEmpty)
            _BatchSelectorStrip(
              batchCodes: batchCodes,
              selectedBatch: selectedBatch,
              onChanged: onBatchChanged,
            ),
          Expanded(
            child: records.isEmpty
                ? _EmptyRecordsState(tt: tt, cs: cs, hint: emptyHint)
                : _GrowthLogContent(
                    records: records,
                    heightSpots: heightSpots,
                    leafCountSpots: leafCountSpots,
                    defMap: defMap,
                    batchMap: batchMap,
                    isBatchMapLoading: isBatchMapLoading,
                    tt: tt,
                    cs: cs,
                    onRefresh: onRefresh,
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
                  style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
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
          constraints: const BoxConstraints(maxWidth: 180),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    required this.leafCountSpots,
    required this.defMap,
    required this.batchMap,
    required this.isBatchMapLoading,
    required this.tt,
    required this.cs,
    required this.onRefresh,
  });

  final List<MeasurementRecordModel> records;
  final List<FlSpot> heightSpots;
  final List<FlSpot> leafCountSpots;
  final Map<String, MeasurementDefinitionInfo>? defMap;
  final Map<String, String> batchMap;
  final bool isBatchMapLoading;
  final TextTheme tt;
  final ColorScheme cs;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heightSpots.isNotEmpty || leafCountSpots.isNotEmpty) ...[
              Text('Biểu đồ tăng trưởng',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              _GrowthChart(
                heightSpots: heightSpots,
                leafCountSpots: leafCountSpots,
                tt: tt,
                cs: cs,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Row(
              children: [
                Text('Lịch sử ghi nhận',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '${records.length} bản ghi',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurface.withAlpha(128)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...records.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _GrowthRecordCard(
                    record: r,
                    defMap: defMap,
                    batchMap: batchMap,
                    isBatchMapLoading: isBatchMapLoading,
                    tt: tt,
                    cs: cs,
                  ),
                )),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
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
                        style: widget.tt.bodyMedium?.copyWith(
                            color: widget.cs.onSurface.withAlpha(128))))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _showLeafCount ? 2 : 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                            color: widget.cs.outline.withAlpha(51),
                            strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: _showLeafCount ? 2 : 5,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: widget.tt.labelSmall?.copyWith(
                                  color:
                                      widget.cs.onSurface.withAlpha(102)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval:
                                (spots.length / 5).ceilToDouble().clamp(1, 10),
                            getTitlesWidget: (value, meta) => Text(
                              'D${value.toInt()}',
                              style: widget.tt.labelSmall?.copyWith(
                                  color:
                                      widget.cs.onSurface.withAlpha(102)),
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
                          belowBarData: BarAreaData(
                              show: true, color: color.withAlpha(25)),
                        ),
                      ],
                      minY:
                          (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) -
                                      2)
                                  .clamp(0, double.infinity),
                      maxY: spots
                              .map((s) => s.y)
                              .reduce((a, b) => a > b ? a : b) +
                          2,
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
    required this.batchMap,
    required this.isBatchMapLoading,
    required this.tt,
    required this.cs,
  });

  final MeasurementRecordModel record;
  final Map<String, MeasurementDefinitionInfo>? defMap;
  final Map<String, String> batchMap;
  final bool isBatchMapLoading;
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
    final def = defMap?[record.measurementDefinitionId];
    if (def?.unit != null && def!.unit!.isNotEmpty) return def.unit!;
    final name = _resolveMetricName();
    final catalogUnit = MetricCatalog.lookup(name)?.unit;
    if (catalogUnit != null && catalogUnit.isNotEmpty) return catalogUnit;
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

    final code = (record.batchCode != null && record.batchCode!.isNotEmpty)
        ? record.batchCode!
        : (batchMap[record.batchId] ??
            (record.batchId.isNotEmpty ? record.batchId : null));
    final isLoadingName = code == record.batchId && isBatchMapLoading;

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
                    if (code != null)
                      Container(
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
                            Flexible(
                              child: Text(
                                isLoadingName
                                    ? '…'
                                    : (code.length > 18
                                        ? '${code.substring(0, 16)}…'
                                        : code),
                                style: tt.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
  const _EmptyRecordsState(
      {required this.tt, required this.cs, required this.hint});
  final TextTheme tt;
  final ColorScheme cs;
  final String hint;

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
              style: tt.titleMedium
                  ?.copyWith(color: cs.onSurface.withAlpha(153)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint,
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withAlpha(102)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
