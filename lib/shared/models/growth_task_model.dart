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

enum TaskType { planting, watering, fertilizing, observation, inspection }

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

  String get taskTypeLabel => switch (taskType) {
    TaskType.planting    => 'Planting',
    TaskType.watering   => 'Watering',
    TaskType.fertilizing => 'Fertilizing',
    TaskType.observation => 'Observation',
    TaskType.inspection  => 'Inspection',
  };

  String get statusLabel => switch (status) {
    TaskStatus.pending    => 'Pending',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.completed  => 'Completed',
    TaskStatus.overdue    => 'Overdue',
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
