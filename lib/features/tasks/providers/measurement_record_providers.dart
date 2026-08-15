library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/api/models/measurement_definition_model.dart';
import '../../../core/api/services/measurement_record_api_service.dart';
import '../../../core/api/services/experiment_api_service.dart';
import '../data/measurement_record_repository.dart';

export '../../../core/api/models/measurement_record_model.dart';

final measurementRecordRepositoryProvider =
    Provider<MeasurementRecordRepository>((ref) {
  return MeasurementRecordRepository(
    ref.read(measurementRecordApiServiceProvider),
    ref.read(experimentApiServiceProvider),
  );
});

final measurementRecordsByBatchProvider =
    FutureProvider.autoDispose.family<List<MeasurementRecordModel>, String>(
  (ref, batchId) async {
    return ref
        .read(measurementRecordRepositoryProvider)
        .getRecordsByBatch(batchId);
  },
);

final measurementDefinitionsProvider =
    FutureProvider.autoDispose.family<List<MeasurementDefinitionModel>, String>(
  (ref, experimentId) async {
    return ref
        .read(measurementRecordRepositoryProvider)
        .getDefinitionsByExperiment(experimentId);
  },
);

final bulkMeasurementProvider =
    FutureProvider.autoDispose.family<BulkMeasurementResponse, BulkMeasurementDto>(
  (ref, dto) async {
    return ref.read(measurementRecordRepositoryProvider).createBulk(dto);
  },
);

final validateMeasurementProvider = FutureProvider.autoDispose.family<
    MeasurementValidationResult, ({String definitionId, double value})>(
  (ref, params) async {
    return ref
        .read(measurementRecordRepositoryProvider)
        .validateValue(params.definitionId, params.value);
  },
);

final stageStatisticsProvider = FutureProvider.autoDispose.family<
    MeasurementStatisticsResponse,
    ({String stageId, DateTime? fromDate, DateTime? toDate, String? groupId})>(
  (ref, params) async {
    return ref.read(measurementRecordRepositoryProvider).getStageStatistics(
          params.stageId,
          fromDate: params.fromDate,
          toDate: params.toDate,
          groupId: params.groupId,
        );
  },
);

final experimentStatisticsProvider = FutureProvider.autoDispose.family<
    MeasurementStatisticsResponse,
    ({String experimentId, DateTime? fromDate, DateTime? toDate})>(
  (ref, params) async {
    return ref.read(measurementRecordRepositoryProvider).getExperimentStatistics(
          params.experimentId,
          fromDate: params.fromDate,
          toDate: params.toDate,
        );
  },
);
