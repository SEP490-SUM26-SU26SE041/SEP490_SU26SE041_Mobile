import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_report_model.dart';
import '../../../core/api/services/task_report_api_service.dart';
import '../data/task_report_repository.dart';

final taskReportRepositoryProvider = Provider<TaskReportRepository>((ref) {
  return TaskReportRepository(ref.read(taskReportApiServiceProvider));
});

// ─── Get report by task ─────────────────────────────────────────────────

final taskReportByTaskProvider = FutureProvider.autoDispose.family<TaskReportModel?, String>(
  (ref, taskId) async {
    return ref.read(taskReportRepositoryProvider).getReportByTask(taskId);
  },
);

// ─── Get reports by batch ───────────────────────────────────────────────

final taskReportsByBatchProvider = FutureProvider.autoDispose.family<List<TaskReportModel>, String>(
  (ref, batchId) async {
    return ref.read(taskReportRepositoryProvider).getReportsByBatch(batchId);
  },
);

// ─── Submit report ─────────────────────────────────────────────────────

final submitReportProvider = FutureProvider.autoDispose.family<TaskReportModel, CreateTaskReportDto>(
  (ref, dto) async {
    return ref.read(taskReportRepositoryProvider).submitReport(dto);
  },
);

// ─── Update report ─────────────────────────────────────────────────────

final updateReportProvider = FutureProvider.autoDispose.family<TaskReportModel, UpdateReportParam>(
  (ref, param) async {
    return ref.read(taskReportRepositoryProvider).updateReport(
      param.reportId,
      param.dto,
    );
  },
);

class UpdateReportParam {
  const UpdateReportParam({required this.reportId, required this.dto});
  final String reportId;
  final UpdateTaskReportDto dto;
}
