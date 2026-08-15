library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/measurement_record_model.dart';

final measurementRecordApiServiceProvider =
    Provider<MeasurementRecordApiService>((ref) {
  return MeasurementRecordApiService(ref.read(dioProvider));
});

class MeasurementRecordApiService {
  MeasurementRecordApiService(this._dio);
  final Dio _dio;

  // ─── Bulk Create ─────────────────────────────────────────────────────────────

  /// POST /measurement-records/bulk
  /// Tạo N records trong 1 request (1 record/metric).
  Future<BulkMeasurementResponse> createBulk(BulkMeasurementDto dto) async {
    final res = await _dio.post(
      ApiEndpoints.measurementRecordsBulk,
      data: dto.toJson(),
    );
    if (res.data is Map<String, dynamic>) {
      return BulkMeasurementResponse.fromJson(res.data);
    }
    throw Exception('Unexpected response format');
  }

  // ─── Single Create (legacy) ──────────────────────────────────────────────

  /// POST /measurement-records
  Future<MeasurementRecordModel> createRecord({
    required String experimentId,
    required String experimentStageId,
    required String batchId,
    required String measurementDefinitionId,
    required double value,
    String? textValue,
    required DateTime measuredAt,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.measurementRecords,
      data: {
        'experimentId': experimentId,
        'experimentStageId': experimentStageId,
        'batchId': batchId,
        'measurementDefinitionId': measurementDefinitionId,
        'value': value,
        if (textValue != null) 'textValue': textValue,
        'measuredAt': measuredAt.toIso8601String(),
      },
    );
    return MeasurementRecordModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Get by batch ─────────────────────────────────────────────────────────

  /// GET /measurement-records/batch/{batchId}
  Future<List<MeasurementRecordModel>> getRecordsByBatch(String batchId) async {
    final res = await _dio.get(ApiEndpoints.measurementByBatch(batchId));
    return _parseList(res);
  }

  // ─── Validate ─────────────────────────────────────────────────────────────

  /// GET /measurement-definitions/{id}/validate?value=X
  Future<MeasurementValidationResult> validateValue(
    String definitionId,
    double value,
  ) async {
    final res = await _dio.get(
      ApiEndpoints.measurementDefinitionValidate(definitionId),
      queryParameters: {'value': value},
    );
    return MeasurementValidationResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  /// GET /experiments/stages/{stageId}/statistics
  Future<MeasurementStatisticsResponse> getStageStatistics(
    String stageId, {
    DateTime? fromDate,
    DateTime? toDate,
    String? groupId,
  }) async {
    final query = <String, dynamic>{};
    if (fromDate != null) {
      query['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      query['toDate'] = toDate.toIso8601String();
    }
    if (groupId != null) query['groupId'] = groupId;

    final res = await _dio.get(
      ApiEndpoints.stageStatistics(stageId),
      queryParameters: query.isEmpty ? null : query,
    );
    return MeasurementStatisticsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /experiments/{experimentId}/statistics
  Future<MeasurementStatisticsResponse> getExperimentStatistics(
    String experimentId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, dynamic>{};
    if (fromDate != null) {
      query['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      query['toDate'] = toDate.toIso8601String();
    }

    final res = await _dio.get(
      ApiEndpoints.experimentStatistics(experimentId),
      queryParameters: query.isEmpty ? null : query,
    );
    return MeasurementStatisticsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  List<MeasurementRecordModel> _parseList(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        return inner
            .map((e) => MeasurementRecordModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    if (data is List) {
      return data
          .map((e) => MeasurementRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
