library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../models/task_report_model.dart';

final taskImageApiServiceProvider = Provider<TaskImageApiService>((ref) {
  return TaskImageApiService(ref.read(dioProvider));
});

class TaskImageApiService {
  TaskImageApiService(this._dio);
  final Dio _dio;

  /// POST /task-images — gửi bằng JSON (chỉ URL đã upload lên Cloudinary).
  Future<TaskImageModel> uploadJson(UploadTaskImageDto dto) async {
    final formData = FormData.fromMap({
      'experimentId': dto.experimentId,
      'batchId': dto.batchId,
      'taskReportId': dto.taskReportId,
      'imageUrl': dto.imageUrl,
      if (dto.caption != null) 'caption': dto.caption,
      'capturedAt': dto.capturedAt.toIso8601String(),
    });

    final res = await _dio.post('/task-images', data: formData);
    return TaskImageModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /task-images/upload — multipart với binary file.
  ///
  /// Dùng cho file mới chụp/chọn (chưa upload lên Cloudinary).
  /// Truyền [aiProvider] để chỉ định AI provider cho ảnh này (vd: 'TomatoLeafDiseaseOnnx').
  /// Nếu null/empty → BE không enqueue AI scan cho ảnh.
  Future<TaskImageModel> uploadMultipart(UploadTaskImageMultipartDto dto) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        dto.file.path,
        filename: dto.file.path.split(Platform.pathSeparator).last,
      ),
      'experimentId': dto.experimentId,
      'batchId': dto.batchId,
      'taskReportId': dto.taskReportId,
      'taskId': dto.taskId,
      if (dto.imageUrl != null) 'imageUrl': dto.imageUrl,
      if (dto.caption != null) 'caption': dto.caption,
      'capturedAt': dto.capturedAt.toIso8601String(),
      if (dto.aiProvider != null && dto.aiProvider!.isNotEmpty)
        'aiProvider': dto.aiProvider,
      if (dto.tags != null) 'tags': dto.tags,
      if (dto.exif != null) 'exif': dto.exif,
    });

    final res = await _dio.post(
      '/task-images/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return TaskImageModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      return TaskImageModel.fromJson(data);
    }
    throw Exception('Unexpected response: $data');
  }

  Future<List<TaskImageModel>> getImagesByReport(String reportId) async {
    final res = await _dio.get('/task-images/report/$reportId');
    return _parseList(res);
  }

  /// GET /task-images/task/{reportId}/detail?includeAnalysis=true
  ///
  /// Trả về danh sách TaskImage kèm [AiAnalysisModel] đầy đủ.
  Future<List<TaskImageModel>> getImagesByReportWithAnalysis(
    String reportId,
  ) async {
    final res = await _dio.get(
      '/task-images/task/$reportId/detail',
      queryParameters: {'includeAnalysis': true},
    );
    return _parseList(res);
  }

  /// POST /task-images/{id}/retry — re-enqueue AI worker.
  Future<TaskImageModel> retryAiScan(String imageId) async {
    final res = await _dio.post('/task-images/$imageId/retry');
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return TaskImageModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      return TaskImageModel.fromJson(data);
    }
    throw Exception('Unexpected retry response: $data');
  }

  Future<List<TaskImageModel>> getImagesByBatch(String batchId) async {
    final res = await _dio.get('/task-images/batch/$batchId');
    return _parseList(res);
  }

  Future<void> deleteImage(String id) async {
    await _dio.delete('/task-images/$id');
  }

  List<TaskImageModel> _parseList(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        return inner.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return const [];
    }
    if (data is List) {
      return data.map((e) => TaskImageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }
}

/// DTO gửi ảnh chỉ với URL (đã upload Cloudinary trước).
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

/// DTO multipart — có file binary + metadata.
class UploadTaskImageMultipartDto {
  const UploadTaskImageMultipartDto({
    required this.file,
    required this.experimentId,
    required this.batchId,
    required this.taskReportId,
    required this.taskId,
    required this.capturedAt,
    this.imageUrl,
    this.caption,
    this.tags,
    this.exif,
    this.aiProvider,
  });

  final File file;
  final String experimentId;
  final String batchId;
  final String taskReportId;
  final String taskId;
  final DateTime capturedAt;
  final String? imageUrl;
  final String? caption;
  final String? tags;
  final String? exif;

  /// AI provider cho ảnh này. Null/empty → BE không enqueue AI worker.
  final String? aiProvider;
}
