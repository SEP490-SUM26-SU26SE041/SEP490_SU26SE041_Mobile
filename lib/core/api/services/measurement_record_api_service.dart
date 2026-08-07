import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/measurement_record_model.dart';

final measurementRecordApiServiceProvider = Provider<MeasurementRecordApiService>((ref) {
  return MeasurementRecordApiService(ref.read(dioProvider));
});

class MeasurementRecordApiService {
  MeasurementRecordApiService(this._dio);
  final Dio _dio;

  /// POST /measurement-records
  Future<MeasurementRecordModel> createRecord(CreateMeasurementDto dto) async {
    final res = await _dio.post(
      ApiEndpoints.measurementRecords,
      data: dto.toJson(),
    );
    return MeasurementRecordModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /measurement-records/batch/{batchId}
  Future<List<MeasurementRecordModel>> getRecordsByBatch(String batchId) async {
    final res = await _dio.get(ApiEndpoints.measurementByBatch(batchId));
    return _parseList(res);
  }

  List<MeasurementRecordModel> _parseList(Response res) {
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => MeasurementRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

class CreateMeasurementDto {
  const CreateMeasurementDto({
    required this.experimentId,
    required this.experimentStageId,
    required this.batchId,
    required this.measurementDefinitionId,
    required this.value,
    this.textValue,
    required this.measuredAt,
  });

  final String experimentId;
  final String experimentStageId;
  final String batchId;
  final String measurementDefinitionId;
  final double value;
  final String? textValue;
  final DateTime measuredAt;

  Map<String, dynamic> toJson() => {
    'experimentId': experimentId,
    'experimentStageId': experimentStageId,
    'batchId': batchId,
    'measurementDefinitionId': measurementDefinitionId,
    'value': value,
    if (textValue != null) 'textValue': textValue,
    'measuredAt': measuredAt.toIso8601String(),
  };
}
