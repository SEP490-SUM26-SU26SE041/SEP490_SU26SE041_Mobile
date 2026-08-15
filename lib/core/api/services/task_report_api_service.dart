library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/task_report_model.dart';

final taskReportApiServiceProvider = Provider<TaskReportApiService>((ref) {
  return TaskReportApiService(ref.read(dioProvider));
});

class TaskReportApiService {
  TaskReportApiService(this._dio);
  final Dio _dio;

  /// POST /task-reports — submit a task report.
  Future<TaskReportModel> submitReport(CreateTaskReportDto dto) async {
    final res = await _dio.post(
      ApiEndpoints.taskReports,
      data: dto.toJson(),
    );
    return TaskReportModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /task-reports/task/{taskId}
  /// Trả về ARRAY các báo cáo (một task có thể có nhiều reports theo thời gian).
  Future<List<TaskReportModel>> getReportsByTask(String taskId) async {
    final res = await _dio.get(ApiEndpoints.taskReportByTask(taskId));
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => TaskReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /task-reports/batch/{batchId}
  Future<List<TaskReportModel>> getReportsByBatch(String batchId) async {
    final res = await _dio.get(ApiEndpoints.taskReportByBatch(batchId));
    return _parseList(res);
  }

  /// PUT /task-reports/{reportId} — update a report.
  Future<TaskReportModel> updateReport(
    String reportId,
    UpdateTaskReportDto dto,
  ) async {
    final res = await _dio.put(
      ApiEndpoints.taskReportById(reportId),
      data: dto.toJson(),
    );
    return TaskReportModel.fromJson(res.data as Map<String, dynamic>);
  }

  List<TaskReportModel> _parseList(Response res) {
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => TaskReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
