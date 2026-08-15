import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../tasks/providers/measurement_record_providers.dart';

/// Growth Chart Screen — xem chỉ số tăng trưởng theo batch.
///
/// Truyền vào `batchId`, screen sẽ:
///   1. Fetch measurement records theo batch (sắp xếp theo thời gian).
///   2. Nhóm theo metric (definitionId) → mỗi metric 1 line chart.
///   3. Hiển thị summary: latest value, target, delta so với record trước.
///
/// Phù hợp với Student/Technician muốn xem quá trình phát triển cây trồng
/// trong cùng 1 batch qua nhiều lần đo.
class GrowthChartScreen extends ConsumerStatefulWidget {
  const GrowthChartScreen({
    super.key,
    required this.batchId,
    this.batchCode,
    this.experimentId,
  });

  final String batchId;
  final String? batchCode;
  final String? experimentId;

  @override
  ConsumerState<GrowthChartScreen> createState() => _GrowthChartScreenState();
}

class _GrowthChartScreenState extends ConsumerState<GrowthChartScreen> {
  String? _selectedMetricId;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final recordsAsync = ref.watch(
      measurementRecordsByBatchProvider(widget.batchId),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          widget.batchCode != null && widget.batchCode!.isNotEmpty
              ? 'Tăng trưởng - ${widget.batchCode}'
              : 'Tăng trưởng',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(e.toString(), tt, cs),
        data: (records) {
          if (records.isEmpty) {
            return _buildEmpty(tt, cs);
          }

          // Group by definitionId
          final byMetric = <String, List<MeasurementRecordModel>>{};
          for (final r in records) {
            byMetric.putIfAbsent(r.measurementDefinitionId, () => []).add(r);
          }
          // Sort each metric's records by measuredAt ascending
          byMetric.forEach((_, list) {
            list.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
          });

          // Default select first metric
          _selectedMetricId ??= byMetric.keys.first;

          final selected = byMetric[_selectedMetricId!] ?? [];
          final metricName = selected.isNotEmpty
              ? (selected.first.measurementDefinitionName ??
                  'Chỉ số ${_selectedMetricId!.substring(0, 8)}')
              : '';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _SummaryCard(
                records: records,
                tt: tt,
                cs: cs,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chỉ số đo lường (${byMetric.length})',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Pills chọn metric
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: byMetric.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final id = byMetric.keys.elementAt(i);
                    final list = byMetric[id]!;
                    final name = list.first.measurementDefinitionName ??
                        'Chỉ số ${id.substring(0, 8)}';
                    final isSel = id == _selectedMetricId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMetricId = id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.success.withAlpha(25)
                              : cs.surfaceContainerHighest.withAlpha(77),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? AppColors.success
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: tt.labelMedium?.copyWith(
                              color: isSel
                                  ? AppColors.success
                                  : cs.onSurface.withAlpha(179),
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (selected.isNotEmpty)
                _ChartCard(
                  metricName: metricName,
                  records: selected,
                  tt: tt,
                  cs: cs,
                ),
              const SizedBox(height: AppSpacing.lg),
              if (selected.isNotEmpty)
                _TableCard(
                  metricName: metricName,
                  records: selected,
                  tt: tt,
                  cs: cs,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(TextTheme tt, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 72,
              color: cs.onSurface.withAlpha(77),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Chưa có dữ liệu đo lường',
                style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Batch này chưa có bản ghi đo. Hãy thực hiện task đo lường để tạo dữ liệu.',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String err, TextTheme tt, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Không tải được dữ liệu', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(err, style: tt.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.records,
    required this.tt,
    required this.cs,
  });

  final List<MeasurementRecordModel> records;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final latestPerMetric = <String, MeasurementRecordModel>{};
    for (final r in records) {
      final existing = latestPerMetric[r.measurementDefinitionId];
      if (existing == null || r.measuredAt.isAfter(existing.measuredAt)) {
        latestPerMetric[r.measurementDefinitionId] = r;
      }
    }

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Tổng quan',
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${records.length} bản ghi',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  icon: Icons.list_alt_rounded,
                  label: 'Số chỉ số',
                  value: '${latestPerMetric.length}',
                  tt: tt,
                  cs: cs,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryStat(
                  icon: Icons.event_rounded,
                  label: 'Cập nhật cuối',
                  value: formatDateShort(
                    _latestDate(latestPerMetric.values),
                  ),
                  tt: tt,
                  cs: cs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _latestDate(Iterable<MeasurementRecordModel> rs) {
    DateTime? latest;
    for (final r in rs) {
      if (latest == null || r.measuredAt.isAfter(latest)) {
        latest = r.measuredAt;
      }
    }
    return latest;
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.tt,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withAlpha(128)),
          const SizedBox(height: AppSpacing.xs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withAlpha(153),
              )),
          const SizedBox(height: 2),
          Text(value,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.metricName,
    required this.records,
    required this.tt,
    required this.cs,
  });

  final String metricName;
  final List<MeasurementRecordModel> records;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      spots.add(FlSpot(i.toDouble(), r.value));
      if (r.value < minY) minY = r.value;
      if (r.value > maxY) maxY = r.value;
    }

    if (minY.isInfinite) minY = 0;
    if (maxY < 0) maxY = 0;

    final padding = (maxY - minY).abs() * 0.15;
    if (padding == 0) {
      minY = minY - 1;
      maxY = maxY + 1;
    } else {
      minY -= padding;
      maxY += padding;
    }

    // latest value vs earliest
    final latest = records.last.value;
    final earliest = records.first.value;
    final delta = latest - earliest;
    final deltaPercent = earliest == 0 ? 0 : (delta / earliest * 100);
    final deltaColor = delta >= 0 ? AppColors.success : AppColors.error;

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metricName,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${records.length} lần đo',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(latest.toStringAsFixed(2),
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      )),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: deltaColor,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${delta >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(1)}%',
                        style: tt.labelSmall?.copyWith(
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 4).clamp(0.1, double.infinity),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outline.withAlpha(40),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withAlpha(128),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval:
                          (records.length / 4).clamp(1, double.infinity).toDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= records.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatDateShort(records[i].measuredAt),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurface.withAlpha(128),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.success,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.success,
                        strokeWidth: 2,
                        strokeColor: cs.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.success.withAlpha(60),
                          AppColors.success.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => cs.onSurface,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${records[s.x.toInt()].value.toStringAsFixed(2)}\n${formatDateShort(records[s.x.toInt()].measuredAt)}',
                              tt.labelSmall?.copyWith(color: cs.surface) ??
                                  const TextStyle(),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.metricName,
    required this.records,
    required this.tt,
    required this.cs,
  });

  final String metricName;
  final List<MeasurementRecordModel> records;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    // Show newest first
    final sorted = [...records].reversed.toList();
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_rows_rounded,
                  color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('Lịch sử đo',
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...sorted.map((r) => _HistoryRow(
                record: r,
                isLatest: sorted.first.id == r.id,
                tt: tt,
                cs: cs,
              )),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.record,
    required this.isLatest,
    required this.tt,
    required this.cs,
  });

  final MeasurementRecordModel record;
  final bool isLatest;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          if (isLatest)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'MỚI',
                style: tt.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDateTime(record.measuredAt),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(179),
                    )),
                if (record.measuredByName != null)
                  Text(
                    'Bởi ${record.measuredByName}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(128),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            record.value.toStringAsFixed(2),
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isLatest ? AppColors.success : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}