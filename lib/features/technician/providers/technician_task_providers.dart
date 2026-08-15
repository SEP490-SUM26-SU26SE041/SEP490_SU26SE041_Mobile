import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../../shared/models/growth_task_model.dart' as internal;
import '../../tasks/providers/task_providers.dart';

/// Technician-specific task provider — maps API TaskModel → internal TaskModel.
/// Uses taskRepoProvider from tasks feature for data fetching.
final technicianTasksProvider = FutureProvider.autoDispose<List<internal.TaskModel>>((ref) async {
  final apiTasks = await ref.read(taskRepoProvider).getMyTasks();
  return apiTasks.map(_toInternal).toList();
});

/// Technician KPI stats from API.
final technicianDashboardStatsProvider = FutureProvider.autoDispose<TechDashboardStats>((ref) async {
  final apiTasks = await ref.read(taskRepoProvider).getMyTasks();
  final todayTasks = await ref.read(taskRepoProvider).getTodayTasks();
  final overdueTasks = await ref.read(taskRepoProvider).getOverdueTasks();

  final pending = apiTasks.where((t) => t.status == api.TaskStatus.pending).length;
  final inProgress = apiTasks.where((t) => t.status == api.TaskStatus.inProgress).length;
  final completed = apiTasks.where((t) => t.status == api.TaskStatus.completed).length;

  return TechDashboardStats(
    todayTasks: todayTasks.length,
    overdueTasks: overdueTasks.length,
    pendingTasks: pending,
    inProgressTasks: inProgress,
    completedTasks: completed,
    totalTasks: apiTasks.length,
  );
});

internal.TaskModel _toInternal(api.TaskModel api) {
  return internal.TaskModel(
    id: api.id,
    taskName: api.title,
    taskType: _taskType(api.taskType),
    experimentId: api.experimentId,
    stageId: api.experimentStageId,
    batchId: api.batchId,
    status: _taskStatus(api.status),
    assignedTo: api.assignedTo,
    dueDate: api.dueDate,
    description: api.description,
    // Map API-sourced fields for UI display
    experimentTitle: api.experimentTitle,
    experimentCode: api.experimentCode,
    experimentStageName: api.experimentStageName,
    batchCode: api.batchCode,
  );
}

internal.TaskType _taskType(api.TaskType t) {
  return switch (t) {
    api.TaskType.planting    => internal.TaskType.planting,
    api.TaskType.watering   => internal.TaskType.watering,
    api.TaskType.fertilizing => internal.TaskType.fertilizing,
    api.TaskType.observation => internal.TaskType.observation,
    api.TaskType.inspection  => internal.TaskType.inspection,
    api.TaskType.measurement => internal.TaskType.observation,
    api.TaskType.harvest     => internal.TaskType.inspection,
    api.TaskType.other       => internal.TaskType.inspection,
  };
}

internal.TaskStatus _taskStatus(api.TaskStatus s) {
  return switch (s) {
    api.TaskStatus.pending    => internal.TaskStatus.pending,
    api.TaskStatus.inProgress => internal.TaskStatus.inProgress,
    api.TaskStatus.completed => internal.TaskStatus.completed,
    api.TaskStatus.approved  => internal.TaskStatus.completed,
    api.TaskStatus.submitted  => internal.TaskStatus.completed,
    _                        => internal.TaskStatus.overdue,
  };
}

class TechDashboardStats {
  const TechDashboardStats({
    required this.todayTasks,
    required this.overdueTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.totalTasks,
  });
  final int todayTasks;
  final int overdueTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int totalTasks;
}
