import '../../utils/date_utils.dart';

/// Task model matching SmartFarm backend API response.
///
/// Maps to: GET /tasks/{id}, GET /tasks/my, GET /tasks/today, etc.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.experimentId,
    this.experimentTitle,
    this.experimentCode,
    this.experimentStageId,
    this.experimentStageName,
    this.batchId,
    this.batchCode,
    this.careScheduleId,
    this.careScheduleTitle,
    this.createdBy,
    this.createdByName,
    this.assignedTo,
    this.assignedToName,
    this.requiredSkillDescription,
    this.skillRequirements,
    this.assignments,
  });

  final String id;
  final String title;
  final String description;
  final TaskType taskType;
  final TaskStatus status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String experimentId;
  final String? experimentTitle;
  final String? experimentCode;
  final String? experimentStageId;
  final String? experimentStageName;
  final String? batchId;
  final String? batchCode;
  final String? careScheduleId;
  final String? careScheduleTitle;
  final String? createdBy;
  final String? createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final String? requiredSkillDescription;
  final List<TaskSkillRequirement>? skillRequirements;
  final List<TaskAssignment>? assignments;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      taskType: TaskType.fromString(json['taskType'] as String? ?? 'Other'),
      status: TaskStatus.fromString(json['status'] as String? ?? 'Pending'),
      dueDate: parseApiDateTimeOrNow(json['dueDate']?.toString()),
      createdAt: parseApiDateTimeOrNow(json['createdAt']?.toString()),
      updatedAt: parseApiDateTimeOrNow(json['updatedAt']?.toString()),
      experimentId: json['experimentId'] as String? ?? '',
      experimentTitle: json['experimentTitle'] as String?,
      experimentCode: json['experimentCode'] as String?,
      experimentStageId: json['experimentStageId'] as String?,
      experimentStageName: json['experimentStageName'] as String?,
      batchId: json['batchId'] as String?,
      batchCode: json['batchCode'] as String?,
      careScheduleId: json['careScheduleId'] as String?,
      careScheduleTitle: json['careScheduleTitle'] as String?,
      createdBy: json['createdBy'] as String?,
      createdByName: json['createdByName'] as String?,
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      requiredSkillDescription: json['requiredSkillDescription'] as String?,
      skillRequirements: (json['skillRequirements'] as List?)
          ?.map((e) => TaskSkillRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List?)
          ?.map((e) => TaskAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'taskType': taskType.value,
    'status': status.value,
    'dueDate': dueDate.toIso8601String(),
    'experimentId': experimentId,
    'experimentStageId': experimentStageId,
    'batchId': batchId,
    'requiredSkillDescription': requiredSkillDescription,
  };

  bool get isOverdue =>
      (status == TaskStatus.pending || status == TaskStatus.overdue) &&
      dueDate.isBefore(DateTime.now());
}

class TaskSkillRequirement {
  const TaskSkillRequirement({
    required this.skillId,
    required this.skillName,
    required this.requiredLevel,
  });

  final String skillId;
  final String skillName;
  final int requiredLevel;

  factory TaskSkillRequirement.fromJson(Map<String, dynamic> json) {
    return TaskSkillRequirement(
      skillId: json['skillId'] as String? ?? '',
      skillName: json['skillName'] as String? ?? '',
      requiredLevel: json['requiredLevel'] as int? ?? 1,
    );
  }
}

class TaskAssignment {
  const TaskAssignment({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeEmail,
    required this.assigneeRole,
    this.assigneeSkills,
    required this.assignedBy,
    required this.assignedByName,
    required this.reason,
    required this.status,
    required this.assignedAt,
    this.endedAt,
  });

  final String id;
  final String taskId;
  final String taskTitle;
  final String assigneeId;
  final String assigneeName;
  final String assigneeEmail;
  final String assigneeRole;
  final List<AssigneeSkill>? assigneeSkills;
  final String assignedBy;
  final String assignedByName;
  final String reason;
  final String status;
  final DateTime assignedAt;
  final DateTime? endedAt;

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      taskTitle: json['taskTitle'] as String? ?? '',
      assigneeId: json['assigneeId'] as String? ?? '',
      assigneeName: json['assigneeName'] as String? ?? '',
      assigneeEmail: json['assigneeEmail'] as String? ?? '',
      assigneeRole: json['assigneeRole'] as String? ?? '',
      assigneeSkills: (json['assigneeSkills'] as List?)
          ?.map((e) => AssigneeSkill.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignedBy: json['assignedBy'] as String? ?? '',
      assignedByName: json['assignedByName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? '',
      assignedAt: parseApiDateTimeOrNow(json['assignedAt']?.toString()),
      endedAt: parseApiDateTime(json['endedAt']?.toString()),
    );
  }
}

class AssigneeSkill {
  const AssigneeSkill({
    required this.skillId,
    required this.skillName,
    required this.proficiencyLevel,
  });

  final String skillId;
  final String skillName;
  final int proficiencyLevel;

  factory AssigneeSkill.fromJson(Map<String, dynamic> json) {
    return AssigneeSkill(
      skillId: json['skillId'] as String? ?? '',
      skillName: json['skillName'] as String? ?? '',
      proficiencyLevel: json['proficiencyLevel'] as int? ?? 1,
    );
  }
}

enum TaskType {
  planting('Planting', 'Trồng cây'),
  watering('Watering', 'Tưới nước'),
  fertilizing('Fertilizing', 'Bón phân'),
  observation('Observation', 'Quan sát'),
  inspection('Inspection', 'Kiểm tra'),
  harvest('Harvest', 'Thu hoạch'),
  measurement('Measurement', 'Đo lường'),
  other('Other', 'Khác');

  const TaskType(this.value, this.labelVi);
  final String value;
  final String labelVi;

  static TaskType fromString(String value) {
    return TaskType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskType.other,
    );
  }
}

enum TaskStatus {
  pending('Pending'),
  inProgress('InProgress'),
  completed('Completed'),
  approved('Approved'),
  submitted('Submitted'),
  rejected('Rejected'),
  resigned('Resigned'),
  reassigned('Reassigned'),
  cancelled('Cancelled'),
  overdue('Overdue');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.pending,
    );
  }
}
