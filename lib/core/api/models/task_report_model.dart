import '../../utils/date_utils.dart';

/// TaskReport model matching SmartFarm backend API response.
///
/// Maps to: POST/GET /task-reports
class TaskReportModel {
  const TaskReportModel({
    required this.id,
    required this.taskId,
    this.taskTitle,
    required this.reporterId,
    this.reporterName,
    required this.reportText,
    this.resultData,
    required this.reportedAt,
    this.images,
  });

  final String id;
  final String taskId;
  final String? taskTitle;
  final String reporterId;
  final String? reporterName;
  final String reportText;
  final ReportResultData? resultData;
  final DateTime reportedAt;
  final List<TaskImageModel>? images;

  factory TaskReportModel.fromJson(Map<String, dynamic> json) {
    return TaskReportModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String?,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String?,
      reportText: json['reportText'] as String? ?? '',
      resultData: json['resultData'] != null
          ? ReportResultData.fromJson(json['resultData'] as Map<String, dynamic>)
          : null,
      reportedAt: parseApiDateTimeOrNow(json['reportedAt']?.toString()),
      images: (json['images'] as List?)
          ?.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'reportText': reportText,
    if (resultData != null) 'resultData': resultData!.toJson(),
  };
}

class ReportResultData {
  const ReportResultData({this.plantsWatered, this.waterAmount,
    this.condition, this.plantsWilting, this.action, this.plantsHarvested,
    this.harvestWeight, this.additionalNotes});

  final int? plantsWatered;
  final String? waterAmount;
  final String? condition;
  final int? plantsWilting;
  final String? action;
  final int? plantsHarvested;
  final String? harvestWeight;
  final String? additionalNotes;

  factory ReportResultData.fromJson(Map<String, dynamic> json) {
    return ReportResultData(
      plantsWatered: json['plantsWatered'] as int?,
      waterAmount: json['waterAmount'] as String?,
      condition: json['condition'] as String?,
      plantsWilting: json['plantsWilting'] as int?,
      action: json['action'] as String?,
      plantsHarvested: json['plantsHarvested'] as int?,
      harvestWeight: json['harvestWeight'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (plantsWatered != null) 'plantsWatered': plantsWatered,
    if (waterAmount != null) 'waterAmount': waterAmount,
    if (condition != null) 'condition': condition,
    if (plantsWilting != null) 'plantsWilting': plantsWilting,
    if (action != null) 'action': action,
    if (plantsHarvested != null) 'plantsHarvested': plantsHarvested,
    if (harvestWeight != null) 'harvestWeight': harvestWeight,
    if (additionalNotes != null) 'additionalNotes': additionalNotes,
  };
}

class TaskImageModel {
  const TaskImageModel({
    required this.id,
    required this.experimentId,
    required this.batchId,
    this.batchCode,
    required this.taskReportId,
    required this.imageUrl,
    this.caption,
    required this.uploadedBy,
    this.uploadedByName,
    required this.capturedAt,
    required this.createdAt,
  });

  final String id;
  final String experimentId;
  final String batchId;
  final String? batchCode;
  final String taskReportId;
  final String imageUrl;
  final String? caption;
  final String uploadedBy;
  final String? uploadedByName;
  final DateTime capturedAt;
  final DateTime createdAt;

  factory TaskImageModel.fromJson(Map<String, dynamic> json) {
    return TaskImageModel(
      id: json['id'] as String,
      experimentId: json['experimentId'] as String,
      batchId: json['batchId'] as String,
      batchCode: json['batchCode'] as String?,
      taskReportId: json['taskReportId'] as String,
      imageUrl: json['imageUrl'] as String,
      caption: json['caption'] as String?,
      uploadedBy: json['uploadedBy'] as String,
      uploadedByName: json['uploadedByName'] as String?,
      capturedAt: parseApiDateTimeOrNow(json['capturedAt']?.toString()),
      createdAt: parseApiDateTimeOrNow(json['createdAt']?.toString()),
    );
  }
}
