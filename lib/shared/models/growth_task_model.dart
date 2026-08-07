import '../../core/utils/date_utils.dart';
import 'experiment_model.dart';

class TaskSkillRequirement {
  const TaskSkillRequirement({
    required this.skillName,
    required this.requiredLevel,
    required this.isMandatory,
  });
  final String skillName;
  final int requiredLevel;
  final bool isMandatory;
}

enum TaskType { planting, watering, fertilizing, observation, inspection, other }

enum TaskStatus { pending, inProgress, completed, overdue }

class AITaskSuggestion {
  const AITaskSuggestion({
    required this.suggestedAssigneeId,
    required this.matchScore,
    required this.reason,
    this.reviewStatus,
    this.alternativeCandidates,
  });
  final String suggestedAssigneeId;
  final double matchScore;
  final String reason;
  final String? reviewStatus;
  final List<AICandidateSuggestion>? alternativeCandidates;
}

class AICandidateSuggestion {
  const AICandidateSuggestion({
    required this.userId,
    required this.fullName,
    required this.matchScore,
    required this.currentTaskCount,
    required this.reason,
  });
  final String userId;
  final String fullName;
  final double matchScore;
  final int currentTaskCount;
  final String reason;
}

// TaskReport Model
class TaskReportModel {
  const TaskReportModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.description,
    required this.submittedAt,
    this.submittedBy,
    this.images = const [],
  });
  final String id;
  final String taskId;
  final String title;
  final String description;
  final DateTime submittedAt;
  final String? submittedBy;
  final List<TaskImageModel> images;

  factory TaskReportModel.fromJson(Map<String, dynamic> json) {
    return TaskReportModel(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? json['taskId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      submittedAt: parseApiDateTimeOrNow(json['submittedAt'] ?? json['createdAt']?.toString()),
      submittedBy: json['submittedBy'] ?? json['submittedByName'],
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => TaskImageModel.fromJson(e))
          .toList() ?? [],
    );
  }
}

// TaskImage Model
class TaskImageModel {
  const TaskImageModel({
    required this.id,
    required this.taskId,
    required this.reportId,
    required this.imageUrl,
    required this.uploadedAt,
    this.description,
  });
  final String id;
  final String taskId;
  final String reportId;
  final String imageUrl;
  final DateTime uploadedAt;
  final String? description;

  factory TaskImageModel.fromJson(Map<String, dynamic> json) {
    return TaskImageModel(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      reportId: json['reportId'] ?? '',
      imageUrl: json['imageUrl'] ?? json['url'] ?? '',
      uploadedAt: parseApiDateTimeOrNow(json['uploadedAt'] ?? json['createdAt']?.toString()),
      description: json['description'],
    );
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.taskName,
    required this.taskType,
    required this.experimentId,
    this.stageId,
    this.batchId,
    required this.status,
    this.assignedTo,
    required this.dueDate,
    this.description,
    this.requiredSkills,
    this.aiSuggestion,
    this.createdAt,
    // API-sourced fields
    this.experimentTitle,
    this.experimentCode,
    this.experimentStageName,
    this.batchCode,
    this.careScheduleId,
    this.careScheduleTitle,
    this.createdByName,
    this.skillRequirements,
  });
  final String id;
  final String taskName;
  final TaskType taskType;
  final String experimentId;
  final String? stageId;
  final String? batchId;
  final TaskStatus status;
  final String? assignedTo;
  final DateTime dueDate;
  final String? description;
  final List<TaskSkillRequirement>? requiredSkills;
  final AITaskSuggestion? aiSuggestion;
  final DateTime? createdAt;
  // API-sourced fields
  final String? experimentTitle;
  final String? experimentCode;
  final String? experimentStageName;
  final String? batchCode;
  final String? careScheduleId;
  final String? careScheduleTitle;
  final String? createdByName;
  final List<TaskSkillRequirement>? skillRequirements;

  // Factory parse từ API response
  factory TaskModel.fromApiJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      taskName: json['title'] ?? '',
      taskType: _parseTaskType(json['taskType']),
      experimentId: json['experimentId'] ?? '',
      stageId: json['experimentStageId'],
      batchId: json['batchId'],
      status: _parseTaskStatus(json['status']),
      assignedTo: json['assignedToName'] ?? json['assignedTo'],
      dueDate: parseApiDateTimeOrNow(json['dueDate']?.toString()),
      description: json['description'],
      createdAt: parseApiDateTime(json['createdAt']?.toString()),
      experimentTitle: json['experimentTitle'],
      experimentCode: json['experimentCode'],
      experimentStageName: json['experimentStageName'],
      batchCode: json['batchCode'],
      careScheduleId: json['careScheduleId'],
      careScheduleTitle: json['careScheduleTitle'],
      createdByName: json['createdByName'],
    );
  }

  static TaskType _parseTaskType(String? type) {
    return switch (type?.toLowerCase()) {
      'planting' => TaskType.planting,
      'watering' => TaskType.watering,
      'fertilizing' => TaskType.fertilizing,
      'observation' => TaskType.observation,
      'inspection' => TaskType.inspection,
      _ => TaskType.other,
    };
  }

  static TaskStatus _parseTaskStatus(String? status) {
    return switch (status?.toLowerCase()) {
      'pending' => TaskStatus.pending,
      'inprogress' || 'in_progress' => TaskStatus.inProgress,
      'completed' => TaskStatus.completed,
      'overdue' => TaskStatus.overdue,
      _ => TaskStatus.pending,
    };
  }

  // Tính số ngày quá hạn
  int get overdueDays {
    if (status != TaskStatus.overdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  String get taskTypeLabel => switch (taskType) {
    TaskType.planting    => 'Trồng cây',
    TaskType.watering   => 'Tưới nước',
    TaskType.fertilizing => 'Bón phân',
    TaskType.observation => 'Quan sát',
    TaskType.inspection  => 'Kiểm tra',
    TaskType.other       => 'Khác',
  };

  String get statusLabel => switch (status) {
    TaskStatus.pending    => 'Chờ',
    TaskStatus.inProgress => 'Đang làm',
    TaskStatus.completed  => 'Hoàn thành',
    TaskStatus.overdue    => 'Quá hạn',
  };
}

class ExperimentRequestModel {
  const ExperimentRequestModel({
    required this.id,
    required this.title,
    required this.objective,
    required this.cropVariety,
    required this.expectedStartDate,
    required this.expectedEndDate,
    this.plantQuantity,
    this.groupCount,
    this.requiredArea,
    this.requiredZoneCount,
    this.requiredBedCount,
    this.plantSpacing,
    this.requiredSoilType,
    this.monitoringRequirements,
    required this.status,
    required this.researcherId,
    required this.researcherName,
    this.createdAt,
  });
  final String id;
  final String title;
  final String objective;
  final String cropVariety;
  final DateTime expectedStartDate;
  final DateTime expectedEndDate;
  final int? plantQuantity;
  final int? groupCount;
  final double? requiredArea;
  final int? requiredZoneCount;
  final int? requiredBedCount;
  final int? plantSpacing;
  final String? requiredSoilType;
  final List<String>? monitoringRequirements;
  final ExperimentStatus status;
  final String researcherId;
  final String researcherName;
  final DateTime? createdAt;
}
