library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/task_report_model.dart';

final taskImageApiServiceProvider = Provider<TaskImageApiService>((ref) {
  return TaskImageApiService(ref.read(dioProvider));
});

class TaskImageApiService {
  TaskImageApiService(this._dio);
  final Dio _dio;

  /// POST /task-images — upload an image for a task report.
  Future<TaskImageModel> uploadImage(UploadTaskImageDto dto) async {
    final formData = FormData.fromMap({
      'experimentId': dto.experimentId,
      'batchId': dto.batchId,
      'taskReportId': dto.taskReportId,
      'imageUrl': dto.imageUrl,
      if (dto.caption != null) 'caption': dto.caption,
      'capturedAt': dto.capturedAt.toIso8601String(),
    });

    final res = await _dio.post(
      ApiEndpoints.taskImages,
      data: formData,
    );
    return TaskImageModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /task-images/report/{reportId}
  Future<List<TaskImageModel>> getImagesByReport(String reportId) async {
    final res = await _dio.get(ApiEndpoints.taskImageByReport(reportId));
    return _parseList(res);
  }

  /// GET /task-images/batch/{batchId}
  Future<List<TaskImageModel>> getImagesByBatch(String batchId) async {
    final res = await _dio.get(ApiEndpoints.taskImageByBatch(batchId));
    return _parseList(res);
  }

  List<TaskImageModel> _parseList(Response res) {
    final data = res.data;
    // Handle wrapped response {success, message, data}
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        return inner.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }
    if (data is List) {
      return data.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

class UploadTaskImageDto {
  const UploadTaskImageDto({
    required this.experimentId,
    required this.batchId,
    required this.taskReportId,
    required this.imageUrl,
    this.caption,
    required this.capturedAt,
  });

  final String experimentId;
  final String batchId;
  final String taskReportId;
  final String imageUrl;
  final String? caption;
  final DateTime capturedAt;
}
