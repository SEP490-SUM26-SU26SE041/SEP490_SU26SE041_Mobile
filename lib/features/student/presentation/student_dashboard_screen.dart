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
import '../../tasks/presentation/widgets/task_visual.dart';
import '../../tasks/providers/my_tasks_provider.dart';
import 'growth_log_screen.dart' show growthRecordsProvider;

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final overview = ref.watch(dashboardOverviewProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    // Đếm measurement records từ cache (fallback khi dashboard trả 0).
    final growthRecordsAsync = ref.watch(growthRecordsProvider);
    // Dùng chung nguồn với TaskHub để counts KPI đồng bộ với tab Công việc.
    // Lấy counts trực tiếp từ 4 endpoint API → đồng bộ với TaskHub.
    final myTasksAsync = ref.watch(myTasksProvider);
    int bucketCount(TaskFilterBucket bucket) {
      final set = myTasksAsync.maybeWhen(
          data: (s) => s, orElse: () => TaskBucketSet.empty);
      switch (bucket) {
        case TaskFilterBucket.today:
          return set.today.length;
        case TaskFilterBucket.upcoming:
          return set.upcoming.length;
        case TaskFilterBucket.overdue:
          return set.overdue.length;
        case TaskFilterBucket.completed:
          return set.completed.length;
        case TaskFilterBucket.all:
          return set.today.length +
              set.upcoming.length +
              set.overdue.length +
              set.completed.length;
      }
    }
    final todayCount = bucketCount(TaskFilterBucket.today);
    final upcomingCount = bucketCount(TaskFilterBucket.upcoming);
    final overdueCount = bucketCount(TaskFilterBucket.overdue);

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.dashboard,
        accentColor: AppColors.accent,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardOverviewProvider);
              ref.invalidate(dashboardAlertsProvider);
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              ref.invalidate(myTasksProvider);
              ref.invalidate(myTasksFlatProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSection(tt: tt, cs: cs),
                  const SizedBox(height: AppSpacing.xl),
                  _KPIRow(
                    todayCount: todayCount,
                    upcomingCount: upcomingCount,
                    overdueCount: overdueCount,
                    overview: overview,
                    measurementFallback:
                        growthRecordsAsync.maybeWhen(
                      data: (l) => l.length,
                      orElse: () => 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _QuickActions(context: context),
                  const SizedBox(height: AppSpacing.xl),
                  _AlertsSection(
                      context: context,
                      alertsAsync: alertsAsync,
                      unreadAsync: unreadAsync),
                  const SizedBox(height: AppSpacing.xl),
                  GradientHeader(
                    title: 'Hình ảnh cây gần đây',
                    subtitle: 'Cập nhật từ Student & Technician',
                    leading: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PlantPhotoGallery(
                    images: overview.maybeWhen(
                      data: (o) => o.recentImages,
                      orElse: () => const [],
                    ),
                    maxPhotos: 5,
                    onImageTap: (image) => _onImageTap(context, image),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _TodayTasksSection(context: context, today: myTasksAsync.maybeWhen(
                    data: (s) => s.today, orElse: () => const [])),
                  const SizedBox(height: AppSpacing.lg),
                  _UpcomingTasksSection(
                      context: context,
                      upcoming: myTasksAsync.maybeWhen(
                          data: (s) => s.upcoming,
                          orElse: () => const [])),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onImageTap(BuildContext context, TaskImageItem image) {
    if (image.taskId != null && image.taskId!.isNotEmpty) {
      context.push('/tasks/${image.taskId}');
    }
  }
}

class _KPIRow extends StatelessWidget {
  const _KPIRow({
    required this.todayCount,
    required this.upcomingCount,
    required this.overdueCount,
    required this.overview,
    required this.measurementFallback,
  });

  final int todayCount;
  final int upcomingCount;
  final int overdueCount;
  final AsyncValue<DashboardOverviewModel> overview;
  final int measurementFallback;

  @override
  Widget build(BuildContext context) {
    final measurementCount = overview.maybeWhen(
        data: (o) {
          final fromApi = o.totalMeasurementRecords;
          // Backend đôi khi trả 0 cho student → fallback về cache.
          return fromApi > 0 ? fromApi : measurementFallback;
        },
        orElse: () => measurementFallback);

    Widget kpi({
      required Color color,
      required IconData icon,
      required int value,
      required String label,
    }) {
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
            Text('$value',
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
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
            child: kpi(
                color: AppColors.info,
                icon: Icons.task_alt_rounded,
                value: todayCount,
                label: 'Hôm nay')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: kpi(
                color: AppColors.warning,
                icon: Icons.upcoming_rounded,
                value: upcomingCount,
                label: 'Sắp tới')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: kpi(
                color: AppColors.error,
                icon: Icons.warning_amber_rounded,
                value: overdueCount,
                label: 'Quá hạn')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: kpi(
                color: AppColors.success,
                icon: Icons.straighten_rounded,
                value: measurementCount,
                label: 'Đo lường')),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
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
            onTap: () => context.go('/student/tasks')),
        const SizedBox(width: AppSpacing.sm),
        action(
            icon: Icons.straighten_rounded,
            label: 'Số liệu',
            color: AppColors.success,
            onTap: () => context.go('/student/growth')),
        const SizedBox(width: AppSpacing.sm),
        action(
            icon: Icons.notifications_rounded,
            label: 'Thông báo',
            color: AppColors.warning,
            onTap: () => context.push('/notifications')),
        const SizedBox(width: AppSpacing.sm),
        action(
            icon: Icons.scanner_rounded,
            label: 'AI Scan',
            color: AppColors.info,
            onTap: () => context.go('/student/ai-scan')),
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({
    required this.context,
    required this.alertsAsync,
    required this.unreadAsync,
  });
  final BuildContext context;
  final AsyncValue<List<DashboardAlertModel>> alertsAsync;
  final AsyncValue<int> unreadAsync;

  @override
  Widget build(BuildContext _) {
    final cs = Theme.of(context).colorScheme;
    final hasAlerts =
        alertsAsync.maybeWhen(data: (l) => l.isNotEmpty, orElse: () => false);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    if (!hasAlerts && unread == 0) return const SizedBox.shrink();

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
            children: list.take(3).map((a) => _AlertCard(alert: a, cs: cs)).toList(),
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
                    child: Text('Bạn có $unread thông báo chưa đọc',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
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
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.cs});
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

class _TodayTasksSection extends StatelessWidget {
  const _TodayTasksSection({required this.context, required this.today});
  final BuildContext context;
  final List<taskApi.TaskModel> today;

  @override
  Widget build(BuildContext _) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final list = today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.today_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('Công việc hôm nay',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (list.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${list.length}',
                    style: tt.labelSmall?.copyWith(
                        color: AppColors.warning, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (list.isEmpty)
          _EmptyState(message: 'Không có công việc hôm nay')
        else
          Column(
              children: list
                  .take(5)
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TaskRow(task: t, tt: tt, cs: cs),
                      ))
                  .toList()),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/student/tasks'),
            child: Text('Xem tất cả',
                style: tt.labelMedium?.copyWith(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}

class _UpcomingTasksSection extends StatelessWidget {
  const _UpcomingTasksSection({required this.context, required this.upcoming});
  final BuildContext context;
  final List<taskApi.TaskModel> upcoming;

  @override
  Widget build(BuildContext _) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final list = upcoming;
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.upcoming_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('Sắp tới (7 ngày)',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${list.length}',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.info, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
            children: list
                .take(3)
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TaskRow(task: t, tt: tt, cs: cs),
                    ))
                .toList()),
      ],
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
        taskApi.TaskType.harvest => Icons.agriculture_rounded,
        taskApi.TaskType.measurement => Icons.straighten_rounded,
        taskApi.TaskType.other => Icons.more_horiz_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/student/tasks/${task.id}'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SNMSCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(message,
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurface.withAlpha(153))),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final greeting = TimeGreeting.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon mặt trời / mặt trăng theo giờ — tone màu động.
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1F4D3D), Color(0xFF3D7A5D)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Sinh viên nghiên cứu',
                        style: TextStyle(
                            color: Colors.white,
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
}
