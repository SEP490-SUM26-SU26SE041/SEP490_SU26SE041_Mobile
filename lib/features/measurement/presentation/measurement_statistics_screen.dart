library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../tasks/providers/measurement_record_providers.dart';

class MeasurementStatisticsScreen extends ConsumerStatefulWidget {
  const MeasurementStatisticsScreen({
    super.key,
    required this.stageId,
    required this.stageName,
    this.experimentId,
    this.fromDate,
    this.toDate,
    this.groupId,
  });

  final String stageId;
  final String stageName;
  final String? experimentId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? groupId;

  @override
  ConsumerState<MeasurementStatisticsScreen> createState() =>
      _MeasurementStatisticsScreenState();
}

class _MeasurementStatisticsScreenState
    extends ConsumerState<MeasurementStatisticsScreen> {
  String? _selectedGroupId;
  int _selectedMetricIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final params = (
      stageId: widget.stageId,
      fromDate: widget.fromDate,
      toDate: widget.toDate,
      groupId: _selectedGroupId,
    );

    final statsAsync = ref.watch(stageStatisticsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thống kê đo lường', style: tt.titleMedium),
            Text(widget.stageName,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Xuất báo cáo',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: AppSpacing.md),
              Text('Lỗi tải thống kê: $e', textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.invalidate(stageStatisticsProvider(params)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (stats) {
          if (stats.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 64, color: cs.onSurface.withAlpha(77)),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Chưa có dữ liệu đo lường', style: tt.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Dữ liệu sẽ hiển thị sau khi Technician ghi nhận chỉ số',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groups = stats.groups;
          final allMetrics = groups.isNotEmpty ? groups.first.metrics : <MetricStatistics>[];
          final selectedMetric = allMetrics.isNotEmpty &&
                  _selectedMetricIndex < allMetrics.length
              ? allMetrics[_selectedMetricIndex]
              : null;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(stageStatisticsProvider(params));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Overview cards ──────────────────────────────────────────────
                  _buildOverviewCards(stats, tt, cs),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Group filter ──────────────────────────────────────────────
                  if (groups.length > 1) ...[
                    Text('Nhóm', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildGroupFilter(groups, tt, cs),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Metric selector ────────────────────────────────────────────
                  if (allMetrics.isNotEmpty) ...[
                    Text('Chỉ số',
                        style:
                            tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildMetricSelector(allMetrics, tt, cs),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Metric Statistics Table ────────────────────────────────────
                  if (selectedMetric != null) ...[
                    Text('Thống kê chi tiết',
                        style:
                            tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.md),
                    _buildStatisticsTable(groups, selectedMetric, tt, cs),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Growth Chart ──────────────────────────────────────────────
                  if (selectedMetric != null) ...[
                    Text('Tăng trưởng theo thời gian',
                        style:
                            tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.md),
                    _buildGrowthChart(groups, selectedMetric, tt, cs),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Cross-group Comparison ────────────────────────────────────
                  if (stats.crossGroupComparison != null) ...[
                    Text('So sánh giữa các nhóm',
                        style:
                            tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.md),
                    _buildComparisonSection(stats, tt, cs),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(MeasurementStatisticsResponse stats, TextTheme tt, ColorScheme cs) {
    final totalSamples = stats.groups.fold<int>(
      0,
      (sum, g) => sum + g.totalSamples,
    );
    final totalBatches = stats.groups.fold<int>(
      0,
      (sum, g) => sum + g.batchCount,
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.analytics_rounded,
            iconColor: AppColors.primary,
            label: 'Nhóm',
            value: '${stats.groups.length}',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.grid_view_rounded,
            iconColor: AppColors.info,
            label: 'Batch',
            value: '$totalBatches',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.numbers_rounded,
            iconColor: AppColors.success,
            label: 'Mẫu đo',
            value: '$totalSamples',
          ),
        ),
      ],
    );
  }

  Widget _buildGroupFilter(
    List<GroupStatistics> groups,
    TextTheme tt,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            selected: _selectedGroupId == null,
            onTap: () => setState(() => _selectedGroupId = null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...groups.map((g) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _FilterChip(
                  label: g.groupName,
                  selected: _selectedGroupId == g.groupId,
                  onTap: () => setState(() => _selectedGroupId = g.groupId),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(
    List<MetricStatistics> metrics,
    TextTheme tt,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(metrics.length, (i) {
          final m = metrics[i];
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _FilterChip(
              label: '${m.metricName} (${m.unit ?? '-'})',
              selected: _selectedMetricIndex == i,
              onTap: () => setState(() => _selectedMetricIndex = i),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatisticsTable(
    List<GroupStatistics> groups,
    MetricStatistics selectedMetric,
    TextTheme tt,
    ColorScheme cs,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Nhóm', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('TB', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Min', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Max', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Đạt', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          // Rows
          ...groups.map((g) {
            final metric = g.metrics.firstWhere(
              (m) => m.definitionId == selectedMetric.definitionId,
              orElse: () => selectedMetric.copyWith(
                average: 0,
                min: 0,
                max: 0,
                sampleCount: 0,
              ),
            );
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: cs.outlineVariant.withAlpha(77)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.groupName,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('n=${metric.sampleCount}',
                            style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withAlpha(128))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      metric.average.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      metric.min.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      metric.max.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      metric.reachesTarget
                          ? Icons.check_circle_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: metric.reachesTarget
                          ? AppColors.success
                          : cs.onSurface.withAlpha(102),
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(
    List<GroupStatistics> groups,
    MetricStatistics selectedMetric,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
      AppColors.success,
    ];

    return Container(
      height: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Column(
        children: [
          // Legend
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 4,
            children: groups.asMap().entries.map((e) {
              final i = e.key;
              final g = e.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(g.groupName, style: tt.labelSmall),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.outlineVariant.withAlpha(77),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withAlpha(128)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (groups.isEmpty) return const SizedBox.shrink();
                        final dates = groups.first.growthOverTime;
                        if (idx >= dates.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${dates[idx].measuredAt.day}/${dates[idx].measuredAt.month}',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurface.withAlpha(128)),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: groups.asMap().entries.map((e) {
                  final i = e.key;
                  final g = e.value;
                  final growth = g.growthOverTime;
                  if (growth.isEmpty) return LineChartBarData(spots: []);
                  return LineChartBarData(
                    spots: growth.asMap().entries.map((e2) {
                      return FlSpot(e2.key.toDouble(), e2.value.average);
                    }).toList(),
                    isCurved: true,
                    color: colors[i % colors.length],
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: colors[i % colors.length],
                        strokeWidth: 2,
                        strokeColor: cs.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors[i % colors.length].withAlpha(26),
                    ),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final group = groups[s.barIndex];
                        return LineTooltipItem(
                          '${group.groupName}: ${s.y.toStringAsFixed(1)}',
                          TextStyle(
                            color: colors[s.barIndex % colors.length],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(
    MeasurementStatisticsResponse stats,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final comp = stats.crossGroupComparison!;
    final bestColor = AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bestColor.withAlpha(15),
            bestColor.withAlpha(5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: bestColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: bestColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhóm dẫn đầu: ${comp.bestGroupName}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: bestColor,
                      ),
                    ),
                    if (comp.summary != null)
                      Text(comp.summary!, style: tt.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: comp.metrics.any((m) => m.significantDifference)
                      ? AppColors.success.withAlpha(25)
                      : AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comp.metrics.any((m) => m.significantDifference)
                      ? 'Khác biệt có ý nghĩa'
                      : 'Chưa có ý nghĩa',
                  style: tt.labelSmall?.copyWith(
                    color: comp.metrics.any((m) => m.significantDifference)
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...comp.metrics.map((m) => _buildMetricComparisonRow(m, tt, cs)),
        ],
      ),
    );
  }

  Widget _buildMetricComparisonRow(
    MetricComparison m,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final isSignificant = m.significantDifference;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${m.metricName} (${m.unit ?? '-'})',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: m.groupValues.map((gv) {
                final isBest = gv.groupId == m.bestGroupId;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isBest
                          ? AppColors.success.withAlpha(25)
                          : cs.surfaceContainerHighest.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: isBest
                          ? Border.all(color: AppColors.success.withAlpha(77))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          gv.groupName,
                          style: tt.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          gv.average.toStringAsFixed(1),
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isBest ? AppColors.success : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSignificant
                  ? AppColors.success.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSignificant ? Icons.check : Icons.remove,
                  size: 14,
                  color: isSignificant
                      ? AppColors.success
                      : cs.onSurface.withAlpha(102),
                ),
                const SizedBox(width: 2),
                Text(
                  '+${m.maxDifference.toStringAsFixed(1)}',
                  style: tt.labelSmall?.copyWith(
                    color: isSignificant
                        ? AppColors.success
                        : cs.onSurface.withAlpha(153),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Xuất CSV'),
              subtitle: const Text('Phù hợp cho Excel, Google Sheets'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang xuất CSV...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_rounded),
              title: const Text('Xuất Excel (XLSX)'),
              subtitle: const Text('Bảng tính với nhiều sheet'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang xuất XLSX...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: iconColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

extension on MetricStatistics {
  MetricStatistics copyWith({
    double? average,
    double? min,
    double? max,
    int? sampleCount,
  }) {
    return MetricStatistics(
      definitionId: definitionId,
      metricName: metricName,
      unit: unit,
      targetValue: targetValue,
      sampleCount: sampleCount ?? this.sampleCount,
      average: average ?? this.average,
      min: min ?? this.min,
      max: max ?? this.max,
      stdDev: stdDev,
      median: median,
      q1: q1,
      q3: q3,
      reachesTarget: reachesTarget,
      targetAchievementRatio: targetAchievementRatio,
    );
  }
}
