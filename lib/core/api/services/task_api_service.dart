library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/task_model.dart';

final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  return TaskApiService(ref.read(dioProvider));
});

class TaskApiService {
  TaskApiService(this._dio);
  final Dio _dio;

  // ─── Mobile (Technician/Student) ────────────────────────────────────

  /// GET /tasks/today — tasks due today for the logged-in user.
  Future<List<TaskModel>> getTodayTasks() async {
    final res = await _dio.get(ApiEndpoints.taskToday);
    return _parseTaskList(res);
  }

  /// GET /tasks/upcoming?days=N — upcoming tasks for the logged-in user.
  Future<List<TaskModel>> getUpcomingTasks({int days = 7}) async {
    final res = await _dio.get(
      ApiEndpoints.taskUpcoming,
      queryParameters: {'days': days},
    );
    return _parseTaskList(res);
  }

  /// GET /tasks/overdue — overdue tasks for the logged-in user.
  Future<List<TaskModel>> getOverdueTasks() async {
    final res = await _dio.get(ApiEndpoints.taskOverdue);
    return _parseTaskList(res);
  }

  /// GET /tasks/my?status=&batchId=&experimentId=
  Future<List<TaskModel>> getMyTasks({
    List<String>? status,
    String? batchId,
    String? experimentId,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (batchId != null) params['batchId'] = batchId;
    if (experimentId != null) params['experimentId'] = experimentId;
    final res = await _dio.get(ApiEndpoints.taskMy, queryParameters: params);
    return _parseTaskList(res);
  }

  /// GET /tasks/{id}
  Future<TaskModel> getTaskById(String taskId) async {
    final res = await _dio.get(ApiEndpoints.taskById(taskId));
    return TaskModel.fromJson(_data(res));
  }

  // ─── Task lifecycle (Mobile) ───────────────────────────────────────

  /// PATCH /tasks/{id}/start — Pending → InProgress
  Future<void> startTask(String taskId) async {
    await _dio.patch(ApiEndpoints.taskStart(taskId));
  }

  /// PATCH /tasks/{id}/complete — InProgress → Completed
  Future<void> completeTask(String taskId) async {
    await _dio.patch(ApiEndpoints.taskComplete(taskId));
  }

  /// GET /tasks/assignments/my — assignments for current user
  Future<List<TaskAssignment>> getMyAssignments() async {
    final res = await _dio.get(ApiEndpoints.myAssignments);
    return (res.data as List)
        .map((e) => TaskAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Researcher ─────────────────────────────────────────────────────

  /// GET /tasks/researcher/created?scope=&experimentId=
  Future<List<TaskModel>> getResearcherCreatedTasks({
    String? scope,
    String? experimentId,
    int? upcomingDays,
  }) async {
    final res = await _dio.get(ApiEndpoints.researcherCreated(
      scope: scope,
      experimentId: experimentId,
      upcomingDays: upcomingDays,
    ));
    return _parseTaskList(res);
  }

  /// GET /tasks/experiment/{experimentId}
  Future<List<TaskModel>> getTasksByExperiment(String experimentId) async {
    final res = await _dio.get(ApiEndpoints.taskExperiment(experimentId));
    return _parseTaskList(res);
  }

  /// GET /tasks/{taskId}/skill-matches
  Future<List<SkillMatch>> getSkillMatches(String taskId) async {
    final res = await _dio.get(ApiEndpoints.taskSkillMatches(taskId));
    return (res.data as List)
        .map((e) => SkillMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Researcher: assign ──────────────────────────────────────────────

  /// POST /tasks/assign
  Future<void> assignTask({
    required String taskId,
    required String assigneeId,
    String? reason,
  }) async {
    await _dio.post(
      ApiEndpoints.taskAssign,
      data: {
        'taskId': taskId,
        'assigneeId': assigneeId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// POST /tasks/reassign
  Future<void> reassignTask({
    required String taskId,
    required String newAssigneeId,
    String? reason,
  }) async {
    await _dio.post(
      ApiEndpoints.taskReassign,
      data: {
        'taskId': taskId,
        'newAssigneeId': newAssigneeId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// PATCH /tasks/{taskId}/cancel
  Future<void> cancelTask(String taskId) async {
    await _dio.patch(ApiEndpoints.taskCancel(taskId));
  }

  // ─── Create ─────────────────────────────────────────────────────────

  /// POST /tasks — create task manually
  Future<TaskModel> createTask(CreateTaskDto dto) async {
    final res = await _dio.post(ApiEndpoints.tasks, data: dto.toJson());
    return TaskModel.fromJson(_data(res));
  }

  /// POST /tasks/generate-by-stage/{stageId}
  Future<List<TaskModel>> generateByStage(String stageId) async {
    final res = await _dio.post(ApiEndpoints.generateByStage(stageId));
    return _parseTaskList(res);
  }

  /// POST /tasks/generate-by-experiment/{experimentId}
  Future<List<TaskModel>> generateByExperiment(String experimentId) async {
    final res = await _dio.post(ApiEndpoints.generateByExperiment(experimentId));
    return _parseTaskList(res);
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  List<TaskModel> _parseTaskList(Response res) {
    final data = res.data;
    // API wraps response in {success, message, data} format OR returns direct array
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        return inner.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } else if (data is List) {
      // Direct array response
      return data.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Map<String, dynamic> _data(Response res) {
    return res.data as Map<String, dynamic>;
  }
}

/// DTO for creating a task.
class CreateTaskDto {
  const CreateTaskDto({
    required this.experimentId,
    required this.title,
    required this.description,
    required this.taskType,
    this.experimentStageId,
    this.batchId,
    this.requiredSkillDescription,
    this.dueDate,
  });

  final String experimentId;
  final String title;
  final String description;
  final String taskType;
  final String? experimentStageId;
  final String? batchId;
  final String? requiredSkillDescription;
  final DateTime? dueDate;

  Map<String, dynamic> toJson() => {
    'experimentId': experimentId,
    'title': title,
    'description': description,
    'taskType': taskType,
    if (experimentStageId != null) 'experimentStageId': experimentStageId,
    if (batchId != null) 'batchId': batchId,
    if (requiredSkillDescription != null)
      'requiredSkillDescription': requiredSkillDescription,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
  };
}

/// Skill match response from /tasks/{taskId}/skill-matches.
class SkillMatch {
  const SkillMatch({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.matchScore,
    required this.currentTaskCount,
    required this.reason,
    this.skills,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final double matchScore;
  final int currentTaskCount;
  final String reason;
  final List<AssigneeSkill>? skills;

  factory SkillMatch.fromJson(Map<String, dynamic> json) {
    return SkillMatch(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      matchScore: (json['matchScore'] as num).toDouble(),
      currentTaskCount: json['currentTaskCount'] as int,
      reason: json['reason'] as String? ?? '',
      skills: (json['skills'] as List?)
          ?.map((e) => AssigneeSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
