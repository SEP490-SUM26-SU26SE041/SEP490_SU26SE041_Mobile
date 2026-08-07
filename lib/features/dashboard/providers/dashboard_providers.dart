library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart';
import '../../tasks/providers/task_providers.dart';
import '../../../shared/widgets/notification_card.dart';

// ─── Researcher Dashboard Providers ──────────────────────────────────────────

/// KPI: Tasks the researcher has created (all scopes)
final researcherDashboardTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final scope = ref.watch(_researcherTaskScopeProvider);
  return ref.read(taskRepoProvider).getResearcherCreatedTasks(scope: scope);
});

final _researcherTaskScopeProvider = StateProvider<String?>((ref) => 'all');

// ─── Dashboard KPI Stats ───────────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.read(taskRepoProvider);

  final allTasks = await repo.getResearcherCreatedTasks(scope: null);
  // Tính "hôm nay" / "quá hạn" theo giờ VN (UTC+7) để không phụ thuộc TZ server.
  final todayTasks = await ref.read(todayTasksLocalProvider.future);
  final overdueTasks = await ref.read(overdueTasksLocalProvider.future);

  final pending = allTasks.where((t) => t.status == TaskStatus.pending).length;
  final inProgress = allTasks.where((t) => t.status == TaskStatus.inProgress).length;
  final completed = allTasks.where((t) => t.status == TaskStatus.completed).length;

  return DashboardStats(
    totalTasks: allTasks.length,
    pendingTasks: pending,
    inProgressTasks: inProgress,
    completedTasks: completed,
    overdueTasks: overdueTasks.length,
    todayTasks: todayTasks.length,
  );
});

class DashboardStats {
  const DashboardStats({
    required this.totalTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.todayTasks,
  });
  final int totalTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int overdueTasks;
  final int todayTasks;
}

// ─── Researcher Pending Tasks (from API) ───────────────────────────────────

final researcherPendingTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getResearcherCreatedTasks(scope: 'upcoming');
});

// ─── Critical Alerts (from overdue tasks) ──────────────────────────────────

final criticalAlertsProvider = FutureProvider.autoDispose<List<AlertFromTask>>((ref) async {
  final overdue = await ref.read(overdueTasksLocalProvider.future);
  return overdue
      .map((t) => AlertFromTask(
            taskId: t.id,
            title: t.title,
            subtitle: _formatDueDate(t.dueDate),
            severity: AlertSeverity.high,
            experimentId: t.experimentId,
          ))
      .toList();
});

String _formatDueDate(DateTime? dt) {
  if (dt == null) return 'No deadline';
  // So sánh theo local VN (UTC+7) thay vì UTC.
  final nowLocal = DateTime.now();
  final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final dtLocal = DateTime(dt.year, dt.month, dt.day);
  final diff = dtLocal.difference(todayLocal);
  if (diff.isNegative) {
    final days = diff.inDays.abs();
    if (days == 0) return 'Due today (overdue)';
    return 'Overdue ${days}d';
  }
  return 'Due ${dt.day}/${dt.month}';
}

class AlertFromTask {
  const AlertFromTask({
    required this.taskId,
    required this.title,
    required this.subtitle,
    required this.severity,
    this.experimentId,
  });
  final String taskId;
  final String title;
  final String subtitle;
  final AlertSeverity severity;
  final String? experimentId;
}
