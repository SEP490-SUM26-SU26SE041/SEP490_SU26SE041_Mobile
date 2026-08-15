library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/api/models/measurement_definition_model.dart';
import '../../../core/api/services/measurement_record_api_service.dart';
import '../../../core/api/services/experiment_api_service.dart';

final measurementRecordRepositoryProvider =
    Provider<MeasurementRecordRepository>((ref) {
  return MeasurementRecordRepository(
    ref.read(measurementRecordApiServiceProvider),
    ref.read(experimentApiServiceProvider),
  );
});

class MeasurementRecordRepository {
  MeasurementRecordRepository(this._measurementApi, this._experimentApi);
  final MeasurementRecordApiService _measurementApi;
  final ExperimentApiService _experimentApi;

  Future<BulkMeasurementResponse> createBulk(BulkMeasurementDto dto) =>
      _measurementApi.createBulk(dto);

  Future<List<MeasurementRecordModel>> getRecordsByBatch(String batchId) =>
      _measurementApi.getRecordsByBatch(batchId);

  Future<MeasurementValidationResult> validateValue(
          String definitionId, double value) =>
      _measurementApi.validateValue(definitionId, value);

  Future<MeasurementStatisticsResponse> getStageStatistics(
    String stageId, {
    DateTime? fromDate,
    DateTime? toDate,
    String? groupId,
  }) =>
      _measurementApi.getStageStatistics(stageId,
          fromDate: fromDate, toDate: toDate, groupId: groupId);

  Future<MeasurementStatisticsResponse> getExperimentStatistics(
    String experimentId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      _measurementApi.getExperimentStatistics(experimentId,
          fromDate: fromDate, toDate: toDate);

  Future<List<MeasurementDefinitionModel>> getDefinitionsByExperiment(
      String experimentId) async {
    final raw = await _experimentApi.getMeasurementDefinitions(experimentId);
    return raw.map((e) => MeasurementDefinitionModel.fromJson(e)).toList();
  }
}
