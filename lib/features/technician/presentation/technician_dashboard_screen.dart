import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/models/dashboard_model.dart';
import '../../../core/api/models/task_model.dart' as taskApi;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/utils/time_greeting.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/plant_photo_gallery.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../dashboard/providers/role_dashboard_providers.dart';
import '../../notifications/providers/notification_providers.dart';
import '../providers/technician_my_tasks_provider.dart';
import '../providers/technician_task_providers.dart';

class TechnicianDashboardScreen extends ConsumerWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final overview = ref.watch(dashboardOverviewProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    // Lấy counts trực tiếp từ 4 endpoint API → đồng bộ với TaskHub.
    final myTasksAsync = ref.watch(technicianMyTasksProvider);
    int bucketCount(TechnicianTaskBucket bucket) {
      final set = myTasksAsync.maybeWhen(
          data: (s) => s, orElse: () => TechnicianTaskBucketSet.empty);
      switch (bucket) {
        case TechnicianTaskBucket.today:
          return set.today.length;
        case TechnicianTaskBucket.upcoming:
          return set.upcoming.length;
        case TechnicianTaskBucket.overdue:
          return set.overdue.length;
        case TechnicianTaskBucket.completed:
          return set.completed.length;
        case TechnicianTaskBucket.all:
          return set.today.length +
              set.upcoming.length +
              set.overdue.length +
              set.completed.length;
      }
    }
    final todayCount = bucketCount(TechnicianTaskBucket.today);
    final upcomingCount = bucketCount(TechnicianTaskBucket.upcoming);
    final overdueCount = bucketCount(TechnicianTaskBucket.overdue);

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.dashboard,
        accentColor: AppColors.info,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(technicianDashboardStatsProvider);
              ref.invalidate(dashboardOverviewProvider);
              ref.invalidate(dashboardAlertsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              ref.invalidate(technicianMyTasksProvider);
              ref.invalidate(technicianMyTasksFlatProvider);
              ref.invalidate(technicianTodayTasksApiProvider);
              ref.invalidate(technicianUpcomingTasksApiProvider);
              ref.invalidate(technicianOverdueTasksApiProvider);
              ref.invalidate(technicianCompletedTasksApiProvider);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(tt, unread),
                        const SizedBox(height: AppSpacing.xl),
                        _buildKPIRow(
                          todayCount: todayCount,
                          upcomingCount: upcomingCount,
                          overdueCount: overdueCount,
                          overview: overview,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildQuickActions(context),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAlerts(context, alertsAsync, unread),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionHeader('Hình ảnh cây gần đây',
                            Icons.eco_rounded, AppColors.success),
                        const SizedBox(height: AppSpacing.md),
                        const PlantPhotoGallery(maxPhotos: 5),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionHeader('Công việc hôm nay',
                            Icons.assignment_rounded, AppColors.primary),
                        const SizedBox(height: AppSpacing.md),
                        _buildTodayTaskList(ref, tt, cs),
                        const SizedBox(height: AppSpacing.huge),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme tt, int unread) {
    final greeting = TimeGreeting.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: greeting.tone.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: greeting.tone.withAlpha(60), width: 1),
                    ),
                    child: Icon(greeting.icon,
                        color: greeting.tone, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(greeting.text,
                        style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.engineering_rounded,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('Kỹ thuật viên',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const NotificationBell(),
        const SizedBox(width: AppSpacing.sm),
        const ProfileButton(),
      ],
    );
  }

  Widget _buildKPIRow({
    required int todayCount,
    required int upcomingCount,
    required int overdueCount,
    required AsyncValue<DashboardOverviewModel> overview,
  }) {
    final measurementCount = overview.maybeWhen(
        data: (o) => o.totalMeasurementRecords,
        orElse: () => 0);

    return Row(
      children: [
        Expanded(
            child: _KPICard(
                value: '$todayCount',
                label: 'Hôm nay',
                color: AppColors.info,
                icon: Icons.task_alt_rounded)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: _KPICard(
                value: '$upcomingCount',
                label: 'Sắp tới',
                color: AppColors.warning,
                icon: Icons.upcoming_rounded)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: _KPICard(
                value: '$overdueCount',
                label: 'Quá hạn',
                color: AppColors.error,
                icon: Icons.warning_amber_rounded)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: _KPICard(
                value: '$measurementCount',
                label: 'Số liệu đo',
                color: AppColors.success,
                icon: Icons.straighten_rounded)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    Widget action({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        action(
            icon: Icons.assignment_rounded,
            label: 'Task',
            color: AppColors.primary,
            onTap: () => context.go('/tech/tasks')),
        const SizedBox(width: AppSpacing.sm),
        action(
            icon: Icons.sensors_rounded,
            label: 'IoT',
            color: AppColors.info,
            onTap: () => context.push('/tech/iot')),
        const SizedBox(width: AppSpacing.sm),
        action(
            icon: Icons.straighten_rounded,
            label: 'Đo lường',
            color: AppColors.success,
            onTap: () => context.go('/tech/growth')),
        const SizedBox(width: AppSpacing.sm),
        action(
            icon: Icons.scanner_rounded,
            label: 'AI Scan',
            color: AppColors.warning,
            onTap: () => context.go('/tech/ai-scan')),
      ],
    );
  }

  Widget _buildAlerts(
    BuildContext context,
    AsyncValue<List<DashboardAlertModel>> alertsAsync,
    int unread,
  ) {
    final hasAlerts = alertsAsync.maybeWhen(
      data: (l) => l.isNotEmpty,
      orElse: () => false,
    );
    if (!hasAlerts && unread == 0) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('Cảnh báo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/notifications'),
              child: Text('Xem tất cả',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        alertsAsync.maybeWhen(
          data: (list) => Column(
            children: list
                .take(3)
                .map((a) => _AlertRow(alert: a, cs: cs))
                .toList(),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: 12,
              onTap: () => context.push('/notifications'),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Bạn có $unread thông báo chưa đọc',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: cs.onSurface.withAlpha(128)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTodayTaskList(
    WidgetRef ref,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final todayAsync = ref.watch(technicianTodayTasksApiProvider);
    return todayAsync.when(
      data: (list) {
        final items = list.take(5).toList();
        if (items.isEmpty) {
          return SNMSCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Không có công việc hôm nay. Nghỉ ngơi thôi!',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurface.withAlpha(153)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: items
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TaskRow(task: t, tt: tt, cs: cs),
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SNMSCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Lỗi tải công việc',
              style: tt.bodyMedium?.copyWith(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                .withAlpha(80)),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(30)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.tt, required this.cs});
  final taskApi.TaskModel task;
  final TextTheme tt;
  final ColorScheme cs;

  Color get _statusColor => switch (task.status) {
        taskApi.TaskStatus.pending => AppColors.warning,
        taskApi.TaskStatus.inProgress => AppColors.primary,
        taskApi.TaskStatus.completed => AppColors.success,
        _ => AppColors.error,
      };

  IconData get _icon => switch (task.taskType) {
        taskApi.TaskType.planting => Icons.eco_rounded,
        taskApi.TaskType.watering => Icons.water_drop_rounded,
        taskApi.TaskType.fertilizing => Icons.science_rounded,
        taskApi.TaskType.observation => Icons.visibility_rounded,
        taskApi.TaskType.inspection => Icons.search_rounded,
        taskApi.TaskType.measurement => Icons.straighten_rounded,
        taskApi.TaskType.harvest => Icons.agriculture_rounded,
        taskApi.TaskType.other => Icons.more_horiz_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/tech/tasks/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _statusColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      '${task.experimentCode ?? ''} · ${task.batchCode ?? ''}',
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withAlpha(128), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: _statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(formatTime(task.dueDate),
                      style: tt.labelSmall?.copyWith(
                          color: _statusColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.cs});
  final DashboardAlertModel alert;
  final ColorScheme cs;

  Color get _color {
    final sev = alert.severity.toLowerCase();
    return switch (sev) {
      'critical' => AppColors.error,
      'high' => AppColors.warning,
      'medium' => AppColors.info,
      _ => cs.onSurface.withAlpha(128),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: 12,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(alert.message,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withAlpha(153)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(formatTime(alert.createdAt),
                style: TextStyle(
                    fontSize: 10, color: cs.onSurface.withAlpha(102))),
          ],
        ),
      ),
    );
  }
}
