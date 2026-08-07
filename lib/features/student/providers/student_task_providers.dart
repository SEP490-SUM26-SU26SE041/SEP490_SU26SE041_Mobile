import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../../shared/models/growth_task_model.dart' as internal;
import '../../tasks/providers/task_providers.dart';

/// Student-specific task provider — maps API TaskModel → internal TaskModel.
final studentTasksProvider = FutureProvider.autoDispose<List<internal.TaskModel>>((ref) async {
  final apiTasks = await ref.read(taskRepoProvider).getMyTasks();
  return apiTasks.map(_toInternal).toList();
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
