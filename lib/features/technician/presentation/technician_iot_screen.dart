import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/farm_model.dart';
import '../../../shared/widgets/snms_card.dart';

final selectedZoneFilterProvider = StateProvider<String?>((ref) => null);

class TechnicianIoTScreen extends ConsumerWidget {
  const TechnicianIoTScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final selectedZone = ref.watch(selectedZoneFilterProvider);
    final allSensors = _getAllSensors();
    final filtered = selectedZone == null
        ? allSensors
        : allSensors.where((s) => s.sensorCode.contains(selectedZone)).toList();

    final online = filtered.where((s) => s.status == SensorStatusType.online).length;
    final offline = filtered.where((s) => s.status == SensorStatusType.offline).length;
    final warning = filtered.where((s) => s.status == SensorStatusType.warning).length;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('IoT - Theo dõi cảm biến', style: tt.titleLarge),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(tt, cs, online, offline, warning),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSensorFilter(tt, cs, ref, selectedZone),
                  const SizedBox(height: AppSpacing.lg),
                  _buildEnvironmentChart(tt, cs),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Icon(Icons.sensors_rounded, size: 18, color: cs.onSurface.withAlpha(153)),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Danh sách cảm biến', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${filtered.length}', style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final sensor = filtered[index];
                return _SensorCard(sensor: sensor, tt: tt, cs: cs);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
        ],
      ),
    );
  }

  Widget _buildStatusOverview(TextTheme tt, ColorScheme cs, int online, int offline, int warning) {
    return Row(
      children: [
        Expanded(child: _StatusTile(label: 'Online', count: online, color: AppColors.sensorOnline, icon: Icons.check_circle_rounded)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatusTile(label: 'Offline', count: offline, color: AppColors.sensorOffline, icon: Icons.cloud_off_rounded)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatusTile(label: 'Warning', count: warning, color: AppColors.sensorWarning, icon: Icons.warning_rounded)),
      ],
    );
  }

  Widget _buildSensorFilter(TextTheme tt, ColorScheme cs, WidgetRef ref, String? selectedZone) {
    final zones = ['Tất cả', 'Z01', 'Z02'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: zones.map((zone) {
          final isSelected = (zone == 'Tất cả' && selectedZone == null) || zone == selectedZone;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(zone),
              selected: isSelected,
              onSelected: (_) {
                ref.read(selectedZoneFilterProvider.notifier).state = zone == 'Tất cả' ? null : zone;
              },
              selectedColor: AppColors.primary.withAlpha(38),
              backgroundColor: cs.surface,
              side: BorderSide(color: isSelected ? AppColors.primary : cs.outline.withAlpha(77)),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnvironmentChart(TextTheme tt, ColorScheme cs) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Chỉ số môi trường', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.outline.withAlpha(51),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}°',
                        style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(102)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Text(
                        'D${value.toInt()}',
                        style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(102)),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 26), FlSpot(2, 28), FlSpot(4, 27),
                      FlSpot(6, 29), FlSpot(8, 28.5), FlSpot(10, 30),
                      FlSpot(12, 29), FlSpot(14, 28),
                    ],
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.warning.withAlpha(20),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 68), FlSpot(2, 70), FlSpot(4, 72),
                      FlSpot(6, 71), FlSpot(8, 73), FlSpot(10, 72),
                      FlSpot(12, 74), FlSpot(14, 72),
                    ],
                    isCurved: true,
                    color: AppColors.info,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.info.withAlpha(20),
                    ),
                  ),
                ],
                minY: 20,
                maxY: 85,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(label: 'Nhiệt độ', color: AppColors.warning),
              const SizedBox(width: AppSpacing.lg),
              _ChartLegend(label: 'Độ ẩm', color: AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  List<SensorModel> _getAllSensors() {
    return [];
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.count, required this.color, required this.icon});
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(153))),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.sensor, required this.tt, required this.cs});
  final SensorModel sensor;
  final TextTheme tt;
  final ColorScheme cs;

  Color get _statusColor => switch (sensor.status) {
    SensorStatusType.online  => AppColors.sensorOnline,
    SensorStatusType.offline => AppColors.sensorOffline,
    SensorStatusType.warning  => AppColors.sensorWarning,
    SensorStatusType.idle    => AppColors.sensorIdle,
  };

  String get _statusLabel => switch (sensor.status) {
    SensorStatusType.online  => 'Online',
    SensorStatusType.offline => 'Offline',
    SensorStatusType.warning  => 'Warning',
    SensorStatusType.idle    => 'Idle',
  };

  IconData get _sensorIcon => switch (sensor.sensorType) {
    SensorType.temperature  => Icons.thermostat_rounded,
    SensorType.humidity     => Icons.water_drop_outlined,
    SensorType.soilMoisture => Icons.water_rounded,
    SensorType.light        => Icons.light_mode_rounded,
    SensorType.co2         => Icons.cloud_outlined,
  };

  String get _sensorTypeLabel => switch (sensor.sensorType) {
    SensorType.temperature  => 'Nhiệt độ',
    SensorType.humidity     => 'Độ ẩm',
    SensorType.soilMoisture => 'Độ ẩm đất',
    SensorType.light        => 'Ánh sáng',
    SensorType.co2         => 'CO2',
  };

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_sensorIcon, color: _statusColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sensor.sensorCode, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_sensorTypeLabel, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (sensor.latestValue != null)
                Text(
                  '${sensor.latestValue}${sensor.unit ?? ''}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _statusColor),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
