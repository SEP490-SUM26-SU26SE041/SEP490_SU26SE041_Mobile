import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/alert_banner.dart';
import '../../../shared/widgets/plant_photo_gallery.dart';
import '../../../shared/widgets/sensor_status_badge.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../mock/mock_farm.dart';
import '../../../mock/mock_growth_data.dart';
import '../../../shared/models/farm_model.dart';

class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sensorAnomalies = _getSensorAnomalies();
    final allSensors = _getAllSensors();
    final online = allSensors.where((s) => s.status == SensorStatusType.online).toList();
    final tempSensor = online.isNotEmpty ? online.first : null;
    final humiditySensors = online.where((s) => s.sensorType == SensorType.humidity).toList();

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.dashboard,
        accentColor: AppColors.info,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(tt),
                      const SizedBox(height: AppSpacing.xl),
                      if (sensorAnomalies.isNotEmpty) ...[
                        AlertBanner(
                          message: '${sensorAnomalies.length} cảm biến cần kiểm tra!',
                          level: AlertLevel.warning,
                          onTap: () => context.push('/tech/iot'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _buildEnvMetrics(tempSensor, humiditySensors, online.length),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('Chỉ số hôm nay', Icons.insights_rounded, AppColors.primary),
                      const SizedBox(height: AppSpacing.md),
                      _buildKPIGrid(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('Thao tác nhanh', Icons.flash_on_rounded, AppColors.warning),
                      const SizedBox(height: AppSpacing.md),
                      _buildQuickActions(context),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('Hình ảnh cây gần đây', Icons.eco_rounded, AppColors.success),
                      const SizedBox(height: AppSpacing.md),
                      const PlantPhotoGallery(maxPhotos: 5),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('Công việc hôm nay', Icons.assignment_rounded, AppColors.primary),
                      const SizedBox(height: AppSpacing.md),
                      _buildPendingTasksList(context),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('Tổng quan cảm biến', Icons.sensors_rounded, AppColors.info),
                      const SizedBox(height: AppSpacing.md),
                      _buildSensorSummary(allSensors),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme tt) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào buổi sáng!', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.engineering_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('Kỹ thuật viên', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const ProfileButton(),
      ],
    );
  }

  Widget _buildEnvMetrics(SensorModel? tempSensor, List<SensorModel> humiditySensors, int onlineCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _EnvMetricChip(
            icon: Icons.thermostat_rounded,
            value: '${tempSensor?.latestValue?.toStringAsFixed(1) ?? '—'}°C',
            label: 'Nhiệt độ',
            color: AppColors.warning,
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          _EnvMetricChip(
            icon: Icons.water_drop_rounded,
            value: '${humiditySensors.isNotEmpty && humiditySensors.first.latestValue != null ? humiditySensors.first.latestValue!.toStringAsFixed(0) : '—'}%',
            label: 'Độ ẩm',
            color: AppColors.info,
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          _EnvMetricChip(
            icon: Icons.sensors_rounded,
            value: '$onlineCount',
            label: 'Online',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildKPIGrid() {
    return Row(
      children: [
        Expanded(child: _KPICard(value: '5', label: 'Hôm nay', color: AppColors.info, icon: Icons.task_alt_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _KPICard(value: '1', label: 'Quá hạn', color: AppColors.error, icon: Icons.warning_amber_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _KPICard(value: '12', label: 'Tuần này', color: AppColors.success, icon: Icons.check_circle_outline_rounded)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickActionCard(icon: Icons.sensors_rounded, label: 'IoT', subLabel: 'Cảm biến', color: AppColors.info, onTap: () => context.push('/tech/iot'))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.description_rounded, label: 'Báo cáo', subLabel: 'Gửi Researcher', color: AppColors.primary, onTap: () => context.push('/tech/report'))),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionCard(icon: Icons.photo_library_rounded, label: 'Ảnh cây', subLabel: 'Thư viện', color: AppColors.success, onTap: () {})),
      ],
    );
  }

  Widget _buildPendingTasksList(BuildContext context) {
    final schedule = _getTodaySchedule();
    final pending = schedule.where((s) => s.status != 'completed').toList();
    if (pending.isEmpty) {
      return _EmptyState(message: 'Không có công việc chờ xử lý', icon: Icons.check_circle_outline_rounded);
    }
    return Column(
      children: pending.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _TechTaskCard(scheduleItem: item, onTap: () => context.go('/tech/tasks')),
      )).toList(),
    );
  }

  Widget _buildSensorSummary(List<SensorModel> sensors) {
    final online = sensors.where((s) => s.status == SensorStatusType.online).length;
    final offline = sensors.where((s) => s.status == SensorStatusType.offline).length;
    final warning = sensors.where((s) => s.status == SensorStatusType.warning).length;
    return Row(
      children: [
        Expanded(child: _SensorStatusCard(label: 'Online', count: online, status: SensorStatus.online)),
        const SizedBox(width: 12),
        Expanded(child: _SensorStatusCard(label: 'Offline', count: offline, status: SensorStatus.offline)),
        const SizedBox(width: 12),
        Expanded(child: _SensorStatusCard(label: 'Warning', count: warning, status: SensorStatus.warning)),
      ],
    );
  }

  List<CareScheduleModel> _getTodaySchedule() => mockCareSchedules;

  List<SensorModel> _getSensorAnomalies() {
    return _getAllSensors().where((s) =>
        s.status == SensorStatusType.offline || s.status == SensorStatusType.warning).toList();
  }

  List<SensorModel> _getAllSensors() {
    final sensors = <SensorModel>[];
    for (final area in mockFarm.areas) {
      for (final zone in area.zones) {
        for (final bed in zone.beds) {
          sensors.addAll(bed.sensors);
        }
      }
    }
    return sensors;
  }
}

class _EnvMetricChip extends StatelessWidget {
  const _EnvMetricChip({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withAlpha(128))),
            ],
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({required this.value, required this.label, required this.color, required this.icon});
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 22 : 10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(30)),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, required this.subLabel, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 22 : 10),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(30)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              Text(subLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechTaskCard extends StatelessWidget {
  const _TechTaskCard({required this.scheduleItem, required this.onTap});
  final CareScheduleModel scheduleItem;
  final VoidCallback onTap;

  Color get _color => switch (scheduleItem.scheduleType.toLowerCase()) {
    'watering' => AppColors.info,
    'fertilizing' => AppColors.primary,
    'inspection' => AppColors.warning,
    _ => AppColors.accent,
  };

  IconData get _icon => switch (scheduleItem.scheduleType.toLowerCase()) {
    'watering' => Icons.water_drop_rounded,
    'fertilizing' => Icons.grass_rounded,
    'inspection' => Icons.search_rounded,
    _ => Icons.agriculture_rounded,
  };

  Color get _statusColor => switch (scheduleItem.status) {
    'completed' => AppColors.success,
    'in_progress' => AppColors.info,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _color.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withAlpha(40)),
                ),
                child: Icon(_icon, size: 22, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scheduleItem.scheduleType, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: cs.onSurface.withAlpha(102)),
                        const SizedBox(width: 4),
                        Text(_formatTime(scheduleItem.scheduledAt), style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Text(scheduleItem.status == 'completed' ? 'Xong' : 'Chờ', style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withAlpha(77)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _SensorStatusCard extends StatelessWidget {
  const _SensorStatusCard({required this.label, required this.count, required this.status});
  final String label;
  final int count;
  final SensorStatus status;

  Color get _color => switch (status) {
    SensorStatus.online => AppColors.success,
    SensorStatus.offline => AppColors.error,
    SensorStatus.warning => AppColors.warning,
    SensorStatus.idle => AppColors.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          SensorStatusBadge(status: status),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _color)),
          Text(label, style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(128))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.success.withAlpha(153)),
          const SizedBox(width: 10),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
