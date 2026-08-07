library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/api/services/measurement_record_api_service.dart';

final measurementRecordRepositoryProvider = Provider<MeasurementRecordRepository>((ref) {
  return MeasurementRecordRepository(ref.read(measurementRecordApiServiceProvider));
});

class MeasurementRecordRepository {
  MeasurementRecordRepository(this._api);
  final MeasurementRecordApiService _api;

  Future<MeasurementRecordModel> createRecord(CreateMeasurementDto dto) =>
      _api.createRecord(dto);

  Future<List<MeasurementRecordModel>> getRecordsByBatch(String batchId) =>
      _api.getRecordsByBatch(batchId);
}
