import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/measurement_definition_model.dart';
import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/api/services/experiment_api_service.dart';
import '../../../core/api/services/measurement_record_api_service.dart';
import '../data/measurement_record_repository.dart';

final measurementRecordRepositoryProvider = Provider<MeasurementRecordRepository>((ref) {
  return MeasurementRecordRepository(ref.read(measurementRecordApiServiceProvider));
});

// ─── Get records by batch ───────────────────────────────────────────────

final measurementRecordsByBatchProvider = FutureProvider.autoDispose.family<
    List<MeasurementRecordModel>, String>(
  (ref, batchId) async {
    return ref.read(measurementRecordRepositoryProvider).getRecordsByBatch(batchId);
  },
);

// ─── Get measurement definitions by experiment ──────────────────────────

final measurementDefinitionsProvider = FutureProvider.autoDispose.family<
    List<MeasurementDefinitionModel>, String>(
  (ref, experimentId) async {
    final api = ref.read(experimentApiServiceProvider);
    final list = await api.getMeasurementDefinitions(experimentId);
    return list.map(MeasurementDefinitionModel.fromJson).toList();
  },
);

// ─── Create measurement record ─────────────────────────────────────────

final createMeasurementRecordProvider = FutureProvider.autoDispose.family<
    MeasurementRecordModel, CreateMeasurementDto>(
  (ref, dto) async {
    return ref.read(measurementRecordRepositoryProvider).createRecord(dto);
  },
);
