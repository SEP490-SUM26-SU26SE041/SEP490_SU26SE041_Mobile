library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_report_model.dart';
import '../../../core/api/services/task_report_api_service.dart';

final taskReportRepositoryProvider = Provider<TaskReportRepository>((ref) {
  return TaskReportRepository(ref.read(taskReportApiServiceProvider));
});

class TaskReportRepository {
  TaskReportRepository(this._api);
  final TaskReportApiService _api;

  Future<TaskReportModel> submitReport(CreateTaskReportDto dto) =>
      _api.submitReport(dto);

  Future<TaskReportModel?> getReportByTask(String taskId) =>
      _api.getReportByTask(taskId);

  Future<List<TaskReportModel>> getReportsByBatch(String batchId) =>
      _api.getReportsByBatch(batchId);

  Future<TaskReportModel> updateReport(String reportId, UpdateTaskReportDto dto) =>
      _api.updateReport(reportId, dto);
}
