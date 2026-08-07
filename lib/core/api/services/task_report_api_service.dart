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
  Future<TaskReportModel?> getReportByTask(String taskId) async {
    final res = await _dio.get(ApiEndpoints.taskReportByTask(taskId));
    final data = res.data;
    
    // Handle null or empty response
    if (data == null) return null;
    
    // Handle direct array response (empty or with items) - line 112 shows "[]"
    if (data is List) {
      if ((data as List).isEmpty) return null;
      // If array has items, return first one
      final first = (data as List).first;
      if (first is Map<String, dynamic>) {
        return TaskReportModel.fromJson(first);
      }
      return null;
    }
    
    // Handle wrapped response {success, message, data}
    if (data is Map<String, dynamic>) {
      // If data field is empty array or null
      if (data['data'] == null) return null;
      final inner = data['data'];
      if (inner is List) {
        if ((inner as List).isEmpty) return null;
        final first = inner.first;
        if (first is Map<String, dynamic>) {
          return TaskReportModel.fromJson(first);
        }
      }
      if (inner is Map<String, dynamic>) {
        return TaskReportModel.fromJson(inner);
      }
      return null;
    }
    
    return null;
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

class CreateTaskReportDto {
  const CreateTaskReportDto({
    required this.taskId,
    required this.reportText,
    this.resultData,
  });

  final String taskId;
  final String reportText;
  final ReportResultData? resultData;

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'reportText': reportText,
    if (resultData != null) 'resultData': resultData!.toJson(),
  };
}

class UpdateTaskReportDto {
  const UpdateTaskReportDto({
    required this.reportText,
    this.resultData,
  });

  final String reportText;
  final ReportResultData? resultData;

  Map<String, dynamic> toJson() => {
    'reportText': reportText,
    if (resultData != null) 'resultData': resultData!.toJson(),
  };
}
