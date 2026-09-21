import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_report_model.dart';
import '../../../core/api/services/task_image_api_service.dart';

export '../../../core/api/services/task_image_api_service.dart'
    show UploadTaskImageDto, UploadTaskImageMultipartDto;

final taskImageRepositoryProvider = Provider<TaskImageRepository>((ref) {
  return TaskImageRepository(ref.read(taskImageApiServiceProvider));
});

class TaskImageRepository {
  TaskImageRepository(this._api);
  final TaskImageApiService _api;

  /// Upload file binary (multipart). Dùng cho ảnh mới chụp/chọn.
  /// Truyền [aiProvider] để chỉ định AI provider cho ảnh (vd: 'TomatoLeafDiseaseOnnx').
  Future<TaskImageModel> uploadTaskImage({
    required String experimentId,
    required String batchId,
    required String taskReportId,
    required String taskId,
    required File imageFile,
    String? caption,
    DateTime? capturedAt,
    String? imageUrl,
    String? aiProvider,
  }) {
    final dto = UploadTaskImageMultipartDto(
      file: imageFile,
      experimentId: experimentId,
      batchId: batchId,
      taskReportId: taskReportId,
      taskId: taskId,
      imageUrl: imageUrl,
      caption: caption,
      capturedAt: capturedAt ?? DateTime.now(),
      aiProvider: aiProvider,
    );
    return _api.uploadMultipart(dto);
  }

  /// Lấy danh sách ảnh kèm aiAnalysis (cho modal xem kết quả AI).
  Future<List<TaskImageModel>> getImagesByReportWithAnalysis(String reportId) =>
      _api.getImagesByReportWithAnalysis(reportId);

  /// Retry AI scan cho 1 ảnh (re-enqueue worker).
  Future<TaskImageModel> retryAiScan(String imageId) =>
      _api.retryAiScan(imageId);

  /// Anchor URL đã upload sẵn (Cloudinary) với report (JSON-only).
  Future<TaskImageModel> attachExistingImageUrl({
    required String experimentId,
    required String batchId,
    required String taskReportId,
    required String imageUrl,
    String? caption,
    DateTime? capturedAt,
  }) {
    final dto = UploadTaskImageDto(
      experimentId: experimentId,
      batchId: batchId,
      taskReportId: taskReportId,
      imageUrl: imageUrl,
      caption: caption,
      capturedAt: capturedAt ?? DateTime.now(),
    );
    return _api.uploadJson(dto);
  }

  Future<List<TaskImageModel>> getImagesByReport(String reportId) =>
      _api.getImagesByReport(reportId);

  Future<List<TaskImageModel>> getImagesByBatch(String batchId) =>
      _api.getImagesByBatch(batchId);

  Future<void> deleteImage(String id) => _api.deleteImage(id);
}
