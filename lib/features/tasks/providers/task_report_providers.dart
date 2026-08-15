import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_report_model.dart' as api;
import '../../../core/api/services/task_report_api_service.dart';
import '../../../shared/models/growth_task_model.dart' as internal;
import '../data/task_report_repository.dart';

final taskReportRepositoryProvider = Provider<TaskReportRepository>((ref) {
  return TaskReportRepository(ref.read(taskReportApiServiceProvider));
});

internal.TaskReportModel? _toInternal(api.TaskReportModel? r) {
  if (r == null) return null;
  return internal.TaskReportModel(
    id: r.id,
    taskId: r.taskId,
    title: r.taskTitle ?? r.reportText,
    description: r.reportText,
    submittedAt: r.reportedAt,
    submittedBy: r.reporterName,
    images: const [],
    rawResultData: r.resultData,
  );
}

internal.TaskReportModel _toInternalRequired(api.TaskReportModel r) =>
    _toInternal(r)!;

List<internal.TaskReportModel> _toInternalList(List<api.TaskReportModel> list) =>
    list.map(_toInternalRequired).toList();

// ─── Get reports by batch ───────────────────────────────────────────────

final taskReportsByBatchProvider =
    FutureProvider.autoDispose.family<List<internal.TaskReportModel>, String>(
  (ref, batchId) async {
    final list = await ref.read(taskReportRepositoryProvider).getReportsByBatch(batchId);
    return _toInternalList(list);
  },
);

// ─── Submit report ─────────────────────────────────────────────────────

final submitReportProvider =
    FutureProvider.autoDispose.family<internal.TaskReportModel, api.CreateTaskReportDto>(
  (ref, dto) async {
    final report = await ref.read(taskReportRepositoryProvider).submitReport(dto);
    return _toInternalRequired(report);
  },
);

// ─── Update report ─────────────────────────────────────────────────────

final updateReportProvider =
    FutureProvider.autoDispose.family<internal.TaskReportModel, UpdateReportParam>(
  (ref, param) async {
    final report = await ref.read(taskReportRepositoryProvider).updateReport(
      param.reportId,
      param.dto,
    );
    return _toInternalRequired(report);
  },
);

class UpdateReportParam {
  const UpdateReportParam({required this.reportId, required this.dto});
  final String reportId;
  final api.UpdateTaskReportDto dto;
}
