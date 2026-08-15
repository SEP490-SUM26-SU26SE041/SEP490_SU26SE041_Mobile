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
}
