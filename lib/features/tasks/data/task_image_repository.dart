library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_report_model.dart';
import '../../../core/api/services/task_image_api_service.dart';

final taskImageRepositoryProvider = Provider<TaskImageRepository>((ref) {
  return TaskImageRepository(ref.read(taskImageApiServiceProvider));
});

class TaskImageRepository {
  TaskImageRepository(this._api);
  final TaskImageApiService _api;

  Future<TaskImageModel> uploadImage(UploadTaskImageDto dto) =>
      _api.uploadImage(dto);

  Future<List<TaskImageModel>> getImagesByReport(String reportId) =>
      _api.getImagesByReport(reportId);

  Future<List<TaskImageModel>> getImagesByBatch(String batchId) =>
      _api.getImagesByBatch(batchId);
}
