import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart';
import '../../../core/api/services/task_api_service.dart';
import '../../../core/api/services/task_report_api_service.dart';
import '../../../core/api/services/task_image_api_service.dart';
import '../../../shared/models/growth_task_model.dart' as internal;

// ─── Repository ────────────────────────────────────────────────────────

final taskRepoProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.read(taskApiServiceProvider),
    ref.read(taskReportApiServiceProvider),
    ref.read(taskImageApiServiceProvider),
  );
});

class TaskRepository {
  TaskRepository(this._api, this._apiTaskReport, this._apiTaskImage);
  final TaskApiService _api;
  final TaskReportApiService _apiTaskReport;
  final TaskImageApiService _apiTaskImage;

  // ─── Mobile: Technician / Student ─────────────────────────────────

  Future<List<TaskModel>> getMyTasks({
    List<String>? status,
    String? batchId,
    String? experimentId,
  }) =>
      _api.getMyTasks(
        status: status,
        batchId: batchId,
        experimentId: experimentId,
      );

  Future<List<TaskModel>> getTodayTasks() => _api.getTodayTasks();

  Future<List<TaskModel>> getUpcomingTasks({int days = 7}) =>
      _api.getUpcomingTasks(days: days);

  Future<List<TaskModel>> getOverdueTasks() => _api.getOverdueTasks();

  Future<TaskModel> getTaskById(String taskId) => _api.getTaskById(taskId);

  Future<void> startTask(String taskId) => _api.startTask(taskId);

  Future<void> completeTask(String taskId) => _api.completeTask(taskId);

  Future<List<TaskAssignment>> getMyAssignments() => _api.getMyAssignments();

  // ─── Researcher ───────────────────────────────────────────────────

  Future<List<TaskModel>> getResearcherCreatedTasks({
    String? scope,
    String? experimentId,
    int? upcomingDays,
  }) =>
      _api.getResearcherCreatedTasks(
        scope: scope,
        experimentId: experimentId,
        upcomingDays: upcomingDays,
      );

  Future<List<TaskModel>> getTasksByExperiment(String experimentId) =>
      _api.getTasksByExperiment(experimentId);

  Future<List<SkillMatch>> getSkillMatches(String taskId) =>
      _api.getSkillMatches(taskId);

  Future<void> assignTask({
    required String taskId,
    required String assigneeId,
    String? reason,
  }) =>
      _api.assignTask(taskId: taskId, assigneeId: assigneeId, reason: reason);

  Future<void> reassignTask({
    required String taskId,
    required String newAssigneeId,
    String? reason,
  }) =>
      _api.reassignTask(
        taskId: taskId,
        newAssigneeId: newAssigneeId,
        reason: reason,
      );

  Future<void> cancelTask(String taskId) => _api.cancelTask(taskId);

  Future<TaskModel> createTask(CreateTaskDto dto) => _api.createTask(dto);

  Future<List<TaskModel>> generateByStage(String stageId) =>
      _api.generateByStage(stageId);

  Future<List<TaskModel>> generateByExperiment(String experimentId) =>
      _api.generateByExperiment(experimentId);

  // ─── Task Report by Task ID ──────────────────────────────────────────

  Future<internal.TaskReportModel?> getTaskReportByTaskId(String taskId) async {
    final report = await _apiTaskReport.getReportByTask(taskId);
    if (report == null) return null;
    return internal.TaskReportModel(
      id: report.id,
      taskId: report.taskId,
      title: report.reportText,
      description: report.resultData?.additionalNotes ?? report.reportText,
      submittedAt: report.reportedAt,
      submittedBy: report.reporterName,
      images: [],
    );
  }

  Future<List<internal.TaskImageModel>> getTaskImagesByTaskId(String taskId) async {
    // Lấy report trước để có reportId
    final report = await _apiTaskReport.getReportByTask(taskId);
    if (report == null) return [];
    final images = await _apiTaskImage.getImagesByReport(report.id);
    return images.map((img) => internal.TaskImageModel(
      id: img.id,
      taskId: taskId,
      reportId: img.taskReportId,
      imageUrl: img.imageUrl,
      uploadedAt: img.createdAt,
      description: img.caption,
    )).toList();
  }
}

// ─── All Tasks (Researcher: created tasks, Technician/Student: assigned tasks) ──

/// Tasks provider - for Researcher uses researcher/created, for others uses /my
final tasksProvider = FutureProvider.autoDispose<List<internal.TaskModel>>((ref) async {
  final apiTasks = await ref.read(taskRepoProvider).getResearcherCreatedTasks(scope: null);
  return apiTasks.map(_toInternalTask).toList();
});

internal.TaskModel _toInternalTask(TaskModel api) {
  return internal.TaskModel(
    id: api.id,
    taskName: api.title ?? 'Công việc',
    taskType: _toInternalTaskType(api.taskType),
    experimentId: api.experimentId,
    stageId: api.experimentStageId,
    batchId: api.batchId,
    status: _toInternalTaskStatus(api.status),
    assignedTo: api.assignedToName ?? api.assignedTo,
    dueDate: api.dueDate,
    description: api.description,
    // Map API-sourced fields for UI display
    experimentTitle: api.experimentTitle,
    experimentCode: api.experimentCode,
    experimentStageName: api.experimentStageName,
    batchCode: api.batchCode,
  );
}

internal.TaskType _toInternalTaskType(TaskType t) {
  return switch (t) {
    TaskType.planting    => internal.TaskType.planting,
    TaskType.watering   => internal.TaskType.watering,
    TaskType.fertilizing => internal.TaskType.fertilizing,
    TaskType.observation => internal.TaskType.observation,
    TaskType.inspection  => internal.TaskType.inspection,
    TaskType.harvest     => internal.TaskType.inspection,
    TaskType.other       => internal.TaskType.inspection,
  };
}

internal.TaskStatus _toInternalTaskStatus(TaskStatus s) {
  return switch (s) {
    TaskStatus.pending    => internal.TaskStatus.pending,
    TaskStatus.inProgress => internal.TaskStatus.inProgress,
    TaskStatus.completed => internal.TaskStatus.completed,
    TaskStatus.approved  => internal.TaskStatus.completed,
    TaskStatus.submitted => internal.TaskStatus.completed,
    _                    => internal.TaskStatus.overdue,
  };
}

// ─── My Tasks (Technician / Student) ──────────────────────────────────

final myTasksFilterProvider = StateProvider<MyTasksFilter>((ref) => const MyTasksFilter());

final filteredMyTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final filter = ref.watch(myTasksFilterProvider);
  final repo = ref.read(taskRepoProvider);
  return repo.getMyTasks(
    status: filter.statuses,
    batchId: filter.batchId,
    experimentId: filter.experimentId,
  );
});

class MyTasksFilter {
  const MyTasksFilter({this.statuses, this.batchId, this.experimentId});
  final List<String>? statuses;
  final String? batchId;
  final String? experimentId;
}

// ─── Today / Upcoming / Overdue ────────────────────────────────────────

final todayTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getTodayTasks();
});

/// "Công việc hôm nay" theo **múi giờ VN (UTC+7)**, lọc client-side.
///
/// Backend `/tasks/today` filter theo timezone của server → có thể lệch ngày
/// khi client ở UTC+7 ngoài giờ làm việc. Provider này lấy tất cả task được
/// assign cho user rồi lọc theo deadline (so với ngày hiện tại tại VN) để
/// không phụ thuộc TZ của server.
final todayTasksLocalProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final all = await ref.read(taskRepoProvider).getMyTasks();
  final nowLocal = DateTime.now();
  final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final tomorrowLocal = todayLocal.add(const Duration(days: 1));

  return all.where((t) {
    if (t.status == TaskStatus.completed) return false;
    final due = t.dueDate;
    if (due.isBefore(todayLocal)) return false;
    if (!due.isBefore(tomorrowLocal)) return false;
    return true;
  }).toList();
});

/// "Công việc quá hạn" theo **múi giờ VN (UTC+7)**, lọc client-side.
final overdueTasksLocalProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final all = await ref.read(taskRepoProvider).getMyTasks();
  final nowLocal = DateTime.now();
  final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

  return all.where((t) {
    if (t.status == TaskStatus.completed) return false;
    return t.dueDate.isBefore(todayLocal);
  }).toList();
});

final upcomingTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getUpcomingTasks();
});

final overdueTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getOverdueTasks();
});

// ─── Task Detail ───────────────────────────────────────────────────────

final taskDetailProvider = FutureProvider.autoDispose.family<TaskModel, String>(
  (ref, taskId) async {
    return ref.read(taskRepoProvider).getTaskById(taskId);
  },
);

// ─── Task Actions ──────────────────────────────────────────────────────

/// Start task: Pending → InProgress
final startTaskProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, taskId) async {
    await ref.read(taskRepoProvider).startTask(taskId);
  },
);

/// Complete task: InProgress → Completed
final completeTaskProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, taskId) async {
    await ref.read(taskRepoProvider).completeTask(taskId);
  },
);

// ─── My Assignments ────────────────────────────────────────────────────

final myAssignmentsProvider = FutureProvider.autoDispose<List<TaskAssignment>>((ref) async {
  return ref.read(taskRepoProvider).getMyAssignments();
});

// ─── Researcher: Tasks by Experiment ───────────────────────────────────

final researcherTasksScopeProvider = StateProvider<String?>((ref) => null);

final researcherCreatedTasksProvider = FutureProvider.autoDispose<List<internal.TaskModel>>((ref) async {
  final scope = ref.watch(researcherTasksScopeProvider);
  final apiTasks = await ref.read(taskRepoProvider).getResearcherCreatedTasks(scope: scope);
  return apiTasks.map(_toInternalTask).toList();
});

// Tasks by experiment - for experiment detail screen
final experimentTasksProvider = FutureProvider.autoDispose.family<List<internal.TaskModel>, String>(
  (ref, experimentId) async {
    final apiTasks = await ref.read(taskRepoProvider).getTasksByExperiment(experimentId);
    return apiTasks.map(_toInternalTask).toList();
  },
);

// ─── Skill Matches (Researcher) ───────────────────────────────────────

final skillMatchesProvider = FutureProvider.autoDispose.family<List<SkillMatch>, String>(
  (ref, taskId) async {
    return ref.read(taskRepoProvider).getSkillMatches(taskId);
  },
);

// ─── Assign Task (Researcher) ─────────────────────────────────────────

final assignTaskProvider = FutureProvider.autoDispose.family<void, AssignTaskParam>(
  (ref, param) async {
    await ref.read(taskRepoProvider).assignTask(
      taskId: param.taskId,
      assigneeId: param.assigneeId,
      reason: param.reason,
    );
  },
);

// ─── Reassign Task (Researcher) ───────────────────────────────────────

final reassignTaskProvider = FutureProvider.autoDispose.family<void, AssignTaskParam>(
  (ref, param) async {
    await ref.read(taskRepoProvider).reassignTask(
      taskId: param.taskId,
      newAssigneeId: param.assigneeId,
      reason: param.reason,
    );
  },
);

// ─── Cancel Task (Researcher) ──────────────────────────────────────────

final cancelTaskProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, taskId) async {
    await ref.read(taskRepoProvider).cancelTask(taskId);
  },
);

// ─── Create Task (Researcher) ──────────────────────────────────────────

final createTaskProvider = FutureProvider.autoDispose.family<TaskModel, CreateTaskDto>(
  (ref, dto) async {
    return ref.read(taskRepoProvider).createTask(dto);
  },
);

// ─── Generate Tasks ─────────────────────────────────────────────────────

final generateByStageProvider = FutureProvider.family<List<TaskModel>, String>(
  (ref, stageId) async {
    return ref.read(taskRepoProvider).generateByStage(stageId);
  },
);

final generateByExperimentProvider = FutureProvider.family<List<TaskModel>, String>(
  (ref, experimentId) async {
    return ref.read(taskRepoProvider).generateByExperiment(experimentId);
  },
);

// ─── Shared param ──────────────────────────────────────────────────────

class AssignTaskParam {
  const AssignTaskParam({required this.taskId, required this.assigneeId, this.reason});
  final String taskId;
  final String assigneeId;
  final String? reason;
}

// ─── Task Report & Images (by Task ID) ─────────────────────────────────

final taskReportByTaskProvider = FutureProvider.autoDispose.family<internal.TaskReportModel?, String>(
  (ref, taskId) async {
    return ref.read(taskRepoProvider).getTaskReportByTaskId(taskId);
  },
);

final taskImagesByTaskProvider = FutureProvider.autoDispose.family<List<internal.TaskImageModel>, String>(
  (ref, taskId) async {
    return ref.read(taskRepoProvider).getTaskImagesByTaskId(taskId);
  },
);
