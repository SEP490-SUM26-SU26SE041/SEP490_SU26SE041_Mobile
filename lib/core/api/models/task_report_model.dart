import '../../utils/date_utils.dart';

/// TaskReport model matching SmartFarm backend API response.
///
/// Maps to: POST/GET /task-reports.
///
/// `resultData` là JSON dynamic dạng `{"key": value}` (string/number/bool…).
/// Luôn lưu dạng `String → String` cho an toàn vì FE Mobile đang hỗ trợ
/// `def_<uuid>` keys (Measurement) + flat keys (legacy field map) +
/// `custom_N` keys (user-defined). BE nhận JSON bất kỳ.
class TaskReportModel {
  const TaskReportModel({
    required this.id,
    required this.taskId,
    this.taskTitle,
    required this.reporterId,
    this.reporterName,
    required this.reportText,
    required this.reportedAt,
    this.resultData,
    this.images,
  });

  final String id;
  final String taskId;
  final String? taskTitle;
  final String reporterId;
  final String? reporterName;
  final String reportText;

  /// JSON object dạng `{ key: value }`. value có thể là String, num, bool…
  /// Luôn parsed non-null (mặc định rỗng).
  final Map<String, dynamic>? resultData;
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
      resultData: _parseResultData(json['resultData']),
      reportedAt: parseApiDateTimeOrNow(json['reportedAt']?.toString()),
      images: (json['images'] as List?)
          ?.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'reportText': reportText,
        if (resultData != null && resultData!.isNotEmpty)
          'resultData': resultData,
      };

  static Map<String, dynamic>? _parseResultData(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}

/// DTO tạo TaskReport. `resultData` là map các cặp key-value tự do.
class CreateTaskReportDto {
  const CreateTaskReportDto({
    required this.taskId,
    required this.reportText,
    this.resultData,
  });

  final String taskId;
  final String reportText;

  /// Mỗi value phải là string tương thích với FE service:
  ///   - number fields → dạng "18.5"
  ///   - select fields → dạng "Tốt"
  ///   - free text fields → string tự do
  final Map<String, String>? resultData;

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'reportText': reportText,
        if (resultData != null && resultData!.isNotEmpty)
          'resultData': resultData,
      };
}

/// DTO cập nhật report.
class UpdateTaskReportDto {
  const UpdateTaskReportDto({
    required this.reportText,
    this.resultData,
  });

  final String reportText;
  final Map<String, String>? resultData;

  Map<String, dynamic> toJson() => {
        'reportText': reportText,
        if (resultData != null && resultData!.isNotEmpty)
          'resultData': resultData,
      };
}

/// Model ảnh minh chứng cho task report.
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
