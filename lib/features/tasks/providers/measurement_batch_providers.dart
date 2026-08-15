import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/measurement_definition_model.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../../core/api/services/experiment_api_service.dart';
import '../data/measurement_bridge.dart';
import '../data/task_report_constants.dart';

/// Hook: Fetch batch (groupId) từ batchId, dùng để filter measurement
/// definitions theo nhóm (xem [filterDefinitionsByTaskGroup]).
final batchInfoProvider = FutureProvider.autoDispose.family<
    BatchGroupInfoWithCode?, String>((ref, batchId) async {
  if (batchId.isEmpty) return null;
  final res = await ref.read(experimentApiServiceProvider).getBatch(batchId);
  if (res == null) return null;
  return BatchGroupInfoWithCode(
    batchId: res.id,
    groupId: res.experimentGroupId.isNotEmpty ? res.experimentGroupId : null,
    groupName: res.experimentGroupName,
    batchCode: res.batchCode,
  );
});

/// Trả về các definitions đã được filter theo groupId của task.
///
/// Ưu tiên:
///   1. Fetch `experimentGroupId` qua `GET /batches/{batchId}`.
///   2. Fallback: dedupe theo `metricName`.
final effectiveMeasurementDefinitionsProvider =
    FutureProvider.autoDispose.family<List<MeasurementDefinitionModel>,
        EffectiveDefinitionsParam>((ref, params) async {
  final defs = params.definitions;
  if (defs.isEmpty) return const [];

  // Try fetching batch to get definitive groupId.
  String? groupId = params.taskBatchGroupId;
  if (groupId == null && params.batchId != null && params.batchId!.isNotEmpty) {
    final batch = await ref.read(batchInfoProvider(params.batchId!).future);
    if (batch != null) groupId = batch.groupId;
  }

  final ctx = TaskGroupContext(
    experimentId: params.experimentId,
    experimentStageId: null,
    batchId: params.batchId,
    batchGroupId: groupId,
  );
  return filterDefinitionsByTaskGroup(
    defs,
    ctx,
    explicitGroupId: ctx.batchGroupId,
  );
});

class EffectiveDefinitionsParam {
  const EffectiveDefinitionsParam({
    required this.definitions,
    this.experimentId,
    this.taskId,
    this.batchId,
    this.taskBatchGroupId,
  });
  final List<MeasurementDefinitionModel> definitions;
  final String? experimentId;
  final String? taskId;
  final String? batchId;
  final String? taskBatchGroupId;
}

/// Subclass có batchCode để hiển thị.
class BatchGroupInfoWithCode extends BatchGroupInfo {
  const BatchGroupInfoWithCode({
    required super.batchId,
    required super.groupId,
    required super.groupName,
    required this.batchCode,
  });

  final String? batchCode;
}

/// Whether [taskType] requires dynamic measurement form.
bool isDynamicFormTaskType(api.TaskType t) =>
    kDynamicMeasurementTaskTypes.contains(t);
