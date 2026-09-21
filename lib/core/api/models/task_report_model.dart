import 'dart:convert';

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
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      taskTitle: json['taskTitle'] as String?,
      reporterId: json['reporterId']?.toString() ?? '',
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
    this.imageUrl = '',
    this.caption,
    this.uploadedBy,
    this.uploadedByName,
    required this.capturedAt,
    required this.createdAt,
    // AI Scan fields
    this.aiStatus,
    this.aiProvider,
    this.aiPredictedLabel,
    this.aiConfidence,
    this.aiAnnotatedImageUrl,
    this.aiAnalysis,
  });

  final String id;
  final String experimentId;
  final String batchId;
  final String? batchCode;
  final String taskReportId;
  final String imageUrl;
  final String? caption;
  final String? uploadedBy;
  final String? uploadedByName;
  final DateTime capturedAt;
  final DateTime createdAt;

  // ─── AI Scan fields (optional) ───────────────────────────────────────────
  /// Trạng thái AI: 'Idle' | 'Pending' | 'Completed' | 'Failed'.
  final String? aiStatus;
  /// AI provider đã dùng (vd: 'TomatoLeafDiseaseOnnx').
  final String? aiProvider;
  /// Label dự đoán (top-level). Thường null — đọc từ [aiAnalysis].
  final String? aiPredictedLabel;
  /// Confidence (top-level). Thường null — đọc từ [aiAnalysis].
  final double? aiConfidence;
  /// URL ảnh đã annotate (bounding boxes).
  final String? aiAnnotatedImageUrl;
  /// Kết quả scan chi tiết từ BE worker.
  final AiAnalysisModel? aiAnalysis;

  /// Trạng thái AI đã hoàn thành (success hoặc failed).
  bool get isAiDone {
    final s = (aiStatus ?? aiAnalysis?.finalStatus ?? '').toLowerCase();
    return s == 'completed' || s == 'success' ||
        s == 'failed' || s == 'error';
  }

  /// Trạng thái AI đang chạy (pending).
  bool get isAiPending {
    final s = (aiStatus ?? '').toLowerCase();
    if (s == 'pending' || s == 'processing') return true;
    final fs = (aiAnalysis?.finalStatus ?? '').toLowerCase();
    return fs == 'pending' || fs.isEmpty && s.isNotEmpty;
  }

  /// Trạng thái AI thất bại.
  bool get isAiFailed {
    final s = (aiStatus ?? '').toLowerCase();
    return s == 'failed' || s == 'error';
  }

  /// Trạng thái AI thành công.
  bool get isAiCompleted {
    final s = (aiStatus ?? '').toLowerCase();
    return s == 'completed' || s == 'success';
  }

  factory TaskImageModel.fromJson(Map<String, dynamic> json) {
    return TaskImageModel(
      id: json['id']?.toString() ?? '',
      experimentId: json['experimentId']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? '',
      batchCode: json['batchCode'] as String?,
      taskReportId: json['taskReportId']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      caption: json['caption'] as String?,
      uploadedBy: json['uploadedBy'] as String?,
      uploadedByName: json['uploadedByName'] as String?,
      capturedAt: parseApiDateTimeOrNow(json['capturedAt']?.toString()),
      createdAt: parseApiDateTimeOrNow(json['createdAt']?.toString()),
      aiStatus: json['aiStatus'] as String?,
      aiProvider: json['aiProvider'] as String?,
      aiPredictedLabel: json['aiPredictedLabel'] as String?,
      aiConfidence: _parseDouble(json['aiConfidence']),
      aiAnnotatedImageUrl: json['aiAnnotatedImageUrl'] as String?,
      aiAnalysis: json['aiAnalysis'] is Map<String, dynamic>
          ? AiAnalysisModel.fromJson(json['aiAnalysis'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Helper parse double an toàn (API có thể trả num, String, null).
  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

/// Model kết quả scan AI chi tiết (BE trả về nested trong TaskImage).
class AiAnalysisModel {
  const AiAnalysisModel({
    this.id,
    this.plantImageId,
    this.aiProvider,
    this.apiVersion,
    this.finalStatus,
    this.isHealthy,
    this.label,
    this.confidence,
    this.gateLabel,
    this.gateConfidence,
    this.detectionCount,
    this.bestBox,
    this.annotatedImageUrl,
    this.rawResultJson,
    this.errorMessage,
  });

  final String? id;
  final String? plantImageId;
  final String? aiProvider;
  final String? apiVersion;
  final String? finalStatus;
  /// True nếu cây khỏe mạnh (healthy).
  final bool? isHealthy;
  final String? label;
  final double? confidence;
  final String? gateLabel;
  final double? gateConfidence;
  final int? detectionCount;
  final Map<String, dynamic>? bestBox;
  final String? annotatedImageUrl;
  final String? rawResultJson;
  final String? errorMessage;

  /// True nếu đây là gate rejection (vd: NotTomatoLeaf).
  bool get isGateRejection {
    final s = (finalStatus ?? '').toLowerCase();
    return s.contains('nottomato') ||
        s.contains('nottomatoLeaf'.toLowerCase()) ||
        s.contains('not_tomato') ||
        s == 'rejected';
  }

  /// True nếu scan thất bại (errorMessage có hoặc finalStatus = error).
  bool get hasError =>
      errorMessage != null ||
      (finalStatus ?? '').toLowerCase() == 'error' ||
      (finalStatus ?? '').toLowerCase() == 'failed';

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AiAnalysisModel(
      id: json['id']?.toString(),
      plantImageId: json['plantImageId']?.toString(),
      aiProvider: json['aiProvider'] as String?,
      apiVersion: json['apiVersion'] as String?,
      finalStatus: json['finalStatus'] as String?,
      isHealthy: json['isHealthy'] is bool
          ? json['isHealthy'] as bool
          : (json['isHealthy']?.toString().toLowerCase() == 'true'),
      label: json['label'] as String?,
      confidence: _parseDouble(json['confidence']),
      gateLabel: json['gateLabel'] as String?,
      gateConfidence: _parseDouble(json['gateConfidence']),
      detectionCount: json['detectionCount'] is int
          ? json['detectionCount'] as int
          : int.tryParse(json['detectionCount']?.toString() ?? ''),
      bestBox: json['bestBox'] is Map<String, dynamic>
          ? json['bestBox'] as Map<String, dynamic>
          : null,
      annotatedImageUrl: json['annotatedImageUrl'] as String?,
      rawResultJson: json['rawResultJson'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Parse rawResultJson thành Map.
  Map<String, dynamic>? get rawMap {
    if (rawResultJson == null || rawResultJson!.isEmpty) return null;
    try {
      final decoded = jsonDecode(rawResultJson!);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
