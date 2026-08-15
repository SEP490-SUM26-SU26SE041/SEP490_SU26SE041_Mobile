library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../../../shared/models/experiment_model.dart';
import '../models/batch_model.dart';

final experimentApiServiceProvider = Provider<ExperimentApiService>((ref) {
  return ExperimentApiService(ref.read(dioProvider));
});

class ExperimentApiService {
  ExperimentApiService(this._dio);
  final Dio _dio;

  // ─── Experiments ──────────────────────────────────────────────────────────────

  /// GET /experiments — fetch all experiments for the researcher.
  Future<List<ExperimentModel>> getExperiments({String? farmId}) async {
    final queryParams = farmId != null ? {'farmId': farmId} : null;
    final res = await _dio.get(ApiEndpoints.experiments, queryParameters: queryParams);
    return _parseExperimentList(res);
  }

  /// GET /experiments/{id}
  Future<ExperimentModel?> getExperiment(String id) async {
    final res = await _dio.get(ApiEndpoints.experimentById(id));
    return _parseExperimentSingle(res);
  }

  /// POST /experiments — create new experiment
  Future<ExperimentModel> createExperiment(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.experiments, data: data);
    return _experimentFromJson(res.data as Map<String, dynamic>);
  }

  /// PUT /experiments/{id} — update experiment
  Future<ExperimentModel> updateExperiment(String id, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiEndpoints.experimentById(id), data: data);
    return _experimentFromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /experiments/{id}/status — update status
  Future<void> updateExperimentStatus(String id, String status) async {
    await _dio.patch(ApiEndpoints.experimentStatus(id), data: {'status': status});
  }

  // ─── Stages ──────────────────────────────────────────────────────────────────

  /// GET /experiments/{id}/stages
  Future<List<ExperimentStage>> getStages(String experimentId) async {
    final res = await _dio.get(ApiEndpoints.experimentStages(experimentId));
    return _parseStageList(res);
  }

  /// GET /experiments/{id}/stages/{stageId}
  Future<ExperimentStage?> getStage(String experimentId, String stageId) async {
    final res = await _dio.get(ApiEndpoints.experimentStage(experimentId, stageId));
    if (res.data == null) return null;
    return _parseStage(res.data as Map<String, dynamic>);
  }

  /// POST /experiments/{id}/stages
  Future<ExperimentStage> createStage(String experimentId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.experimentStages(experimentId), data: data);
    return _parseStage(res.data as Map<String, dynamic>);
  }

  /// PUT /experiments/stages/{stageId}
  Future<ExperimentStage> updateStage(String stageId, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiEndpoints.stageById(stageId), data: data);
    return _parseStage(res.data as Map<String, dynamic>);
  }

  // ─── Groups ─────────────────────────────────────────────────────────────────

  /// GET /experiments/{id}/groups
  Future<List<ExperimentGroup>> getGroups(String experimentId) async {
    final res = await _dio.get(ApiEndpoints.experimentGroups(experimentId));
    return _parseGroupList(res);
  }

  /// POST /experiments/{id}/groups
  Future<ExperimentGroup> createGroup(String experimentId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.experimentGroups(experimentId), data: data);
    return _parseGroup(res.data as Map<String, dynamic>);
  }

  // ─── Batches ────────────────────────────────────────────────────────────────

  /// GET /batches/experiments/{experimentId}
  Future<List<BatchModel>> getBatchesByExperiment(String experimentId) async {
    final res = await _dio.get(ApiEndpoints.batchesByExperiment(experimentId));
    return _parseBatchList(res);
  }

  /// GET /batches/{batchId}
  Future<BatchModel?> getBatch(String batchId) async {
    final res = await _dio.get(ApiEndpoints.batchById(batchId));
    if (res.data == null) return null;
    return BatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /batches — create batch
  Future<BatchModel> createBatch(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.batches, data: data);
    return BatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// PUT /batches/{batchId} — update batch
  Future<BatchModel> updateBatch(String batchId, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiEndpoints.batchById(batchId), data: data);
    return BatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Design ─────────────────────────────────────────────────────────────────

  /// GET /experiments/{id}/design
  Future<ExperimentDesign?> getDesign(String experimentId) async {
    try {
      final res = await _dio.get(ApiEndpoints.experimentDesign(experimentId));
      // Handle wrapped response {success, message, data}
      if (res.data == null) return null;
      Map<String, dynamic>? data;
      if (res.data is Map<String, dynamic>) {
        data = res.data['data'] as Map<String, dynamic>?;
      } else if (res.data is Map<String, dynamic>) {
        data = res.data as Map<String, dynamic>;
      }
      if (data == null) return null;
      return _parseDesign(data);
    } on DioException catch (e) {
      // 404 means design not yet created
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /experiments/{id}/design
  Future<ExperimentDesign> saveDesign(String experimentId, Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.experimentDesign(experimentId), data: data);
    return _parseDesign(res.data as Map<String, dynamic>);
  }

  // ─── Measurement Definitions ────────────────────────────────────────────────

  /// GET /experiments/{id}/measurements
  /// Response có thể là:
  ///   - `[{...}, {...}]` (list trần)
  ///   - `{ "data": [{...}, {...}] }` (wrapped)
  ///   - `{ "items": [{...}, {...}] }` (wrapped, alias)
  ///   - `{ "succeeded": true, "data": [...] }` (envelope)
  Future<List<Map<String, dynamic>>> getMeasurementDefinitions(String experimentId) async {
    final res = await _dio.get(ApiEndpoints.experimentMeasurements(experimentId));
    final data = res.data;
    List<dynamic>? extractList(dynamic v) {
      if (v is List) return v;
      if (v is Map<String, dynamic>) {
        for (final key in const ['data', 'items', 'result', 'records']) {
          final inner = v[key];
          if (inner is List) return inner;
        }
      }
      return null;
    }

    final list = extractList(data);
    if (list == null) return [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// POST /experiments/{id}/measurements
  Future<Map<String, dynamic>> createMeasurementDefinition(
    String experimentId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post(
      ApiEndpoints.experimentMeasurements(experimentId),
      data: data,
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── Care Schedules ─────────────────────────────────────────────────────────

  /// GET /experiments/{id}/schedules
  Future<List<Map<String, dynamic>>> getSchedules(String experimentId) async {
    final res = await _dio.get(ApiEndpoints.experimentSchedules(experimentId));
    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// POST /experiments/{id}/schedules
  Future<Map<String, dynamic>> createSchedule(
    String experimentId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post(
      ApiEndpoints.experimentSchedules(experimentId),
      data: data,
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── Procedure Templates ────────────────────────────────────────────────────

  /// GET /experiments/procedure-templates
  Future<List<Map<String, dynamic>>> getProcedureTemplates({String? cropVarietyId}) async {
    final queryParams = cropVarietyId != null ? {'cropVarietyId': cropVarietyId} : null;
    final res = await _dio.get(
      ApiEndpoints.procedureTemplates,
      queryParameters: queryParams,
    );
    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// GET /experiments/procedure-templates/{id}
  Future<Map<String, dynamic>?> getProcedureTemplate(String id) async {
    final res = await _dio.get(ApiEndpoints.procedureTemplateById(id));
    if (res.data == null) return null;
    return res.data as Map<String, dynamic>;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  List<ExperimentModel> _parseExperimentList(Response res) {
    final data = res.data;
    // Backend có thể trả về { data: [...] } hoặc trực tiếp [...]
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => _experimentFromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => _experimentFromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  ExperimentModel? _parseExperimentSingle(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      // Backend có thể trả về { data: {...} } hoặc trực tiếp {...}
      if (data['data'] is Map<String, dynamic>) {
        return _experimentFromJson(data['data'] as Map<String, dynamic>);
      }
      return _experimentFromJson(data);
    }
    return null;
  }

  List<ExperimentStage> _parseStageList(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => _parseStage(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => _parseStage(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  List<ExperimentGroup> _parseGroupList(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => _parseGroup(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => _parseGroup(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  List<BatchModel> _parseBatchList(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

/// Parse backend experiment JSON → ExperimentModel.
ExperimentModel _experimentFromJson(Map<String, dynamic> json) {
  return ExperimentModel(
    id: json['id'] as String,
    experimentCode: json['experimentCode'] as String? ?? json['code'] as String? ?? '',
    title: json['title'] as String? ?? json['name'] as String? ?? '',
    objective: json['objective'] as String? ?? json['description'] as String? ?? '',
    status: _parseStatus(json['status'] as String? ?? json['experimentStatus'] as String?),
    researcherId: json['researcherId'] as String? ?? json['createdBy'] as String? ?? '',
    startDate: _parseDate(json['startDate'] ?? json['start']),
    endDate: _parseDate(json['endDate'] ?? json['end']),
    cropVariety: json['cropVariety'] as String? ?? json['crop'] as String? ?? json['cropVarietyName'] as String? ?? '',
    design: _parseDesign(json['design'] as Map<String, dynamic>?),
    groups: (json['groups'] as List?)
            ?.map((g) => _parseGroup(g as Map<String, dynamic>))
            .toList() ?? [],
    stages: (json['stages'] as List?)
            ?.map((s) => _parseStage(s as Map<String, dynamic>))
            .toList() ?? [],
    requiredArea: (json['requiredArea'] as num?)?.toDouble(),
    plantQuantity: json['plantQuantity'] as int?,
  );
}

ExperimentStatus _parseStatus(String? s) {
  return switch (s?.toLowerCase()) {
    'active'    => ExperimentStatus.active,
    'draft'     => ExperimentStatus.draft,
    'planning'  => ExperimentStatus.planning,
    'pending'   => ExperimentStatus.pending,
    'pendingapproval' => ExperimentStatus.pending,
    'approved'  => ExperimentStatus.active,
    'inprogress' => ExperimentStatus.active,
    'completed' => ExperimentStatus.completed,
    'cancelled' => ExperimentStatus.completed,
    'paused'    => ExperimentStatus.paused,
    _           => ExperimentStatus.planning,
  };
}

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

ExperimentDesign _parseDesign(Map<String, dynamic>? json) {
  if (json == null) {
    return const ExperimentDesign(
      id: '',
      designType: '',
      replicationCount: 0,
      randomizationMethod: '',
    );
  }
  
  // Parse designParameters if present
  DesignParameters? params;
  final dp = json['designParameters'];
  if (dp != null && dp is String) {
    try {
      final Map<String, dynamic> dpJson = jsonDecode(dp);
      params = DesignParameters(
        notes: dpJson['notes'] as String?,
        layout: dpJson['layout'] as String?,
        spacing: dpJson['spacing'] != null ? PlotSpacing(
          row: dpJson['spacing']['row'] as String?,
          plant: dpJson['spacing']['plant'] as String?,
        ) : null,
        plotArea: dpJson['plotArea'] as int?,
        plotWidth: (dpJson['plotWidth'] as num?)?.toDouble(),
        blockCount: dpJson['blockCount'] as int?,
        bufferZone: dpJson['bufferZone'] as String?,
        plotLength: (dpJson['plotLength'] as num?)?.toDouble(),
        randomSeed: dpJson['randomSeed'] as int?,
        treatments: dpJson['treatments'] as int?,
        plantsPerPlot: dpJson['plantsPerPlot'] as int?,
      );
    } catch (_) {}
  }
  
  return ExperimentDesign(
    id: json['id'] as String? ?? '',
    designType: json['designType'] as String? ?? '',
    replicationCount: json['replicationCount'] as int? ?? 0,
    randomizationMethod: json['randomizationMethod'] as String? ?? '',
    designParameters: params,
  );
}

DesignType _parseDesignType(String? s) {
  return switch (s?.toLowerCase()) {
    'crd' || 'completelyrandomized' => DesignType.completelyRandomized,
    'rcbd' || 'randomizedblock' => DesignType.randomizedBlock,
    'factorial' => DesignType.factorial,
    _ => DesignType.randomizedBlock,
  };
}

ExperimentGroup _parseGroup(Map<String, dynamic> json) {
  return ExperimentGroup(
    id: json['id'] as String,
    groupName: json['groupName'] as String? ?? json['name'] as String? ?? '',
    groupType: _parseGroupType(json['groupType'] as String?),
    description: json['description'] as String? ?? json['treatmentDescription'] as String?,
    cultivationMethod: _parseCultivationMethod(
        json['cultivationMethod'] as Map<String, dynamic>?),
    sampleSize: json['sampleSize'] as int? ?? 30,
  );
}

GroupType _parseGroupType(String? s) {
  return switch (s?.toLowerCase()) {
    'control'  => GroupType.control,
    'treatment' => GroupType.treatment,
    _           => GroupType.treatment,
  };
}

CultivationMethod _parseCultivationMethod(Map<String, dynamic>? json) {
  return CultivationMethod(
    methodName: json?['methodName'] as String? ?? '',
    wateringRule: _parseWatering(json?['wateringRule'] as Map<String, dynamic>?),
    fertilizingRule:
        _parseFertilizing(json?['fertilizingRule'] as Map<String, dynamic>?),
  );
}

WateringRule _parseWatering(Map<String, dynamic>? json) {
  return WateringRule(
    amount: json?['amount'] as int? ?? 0,
    frequencyDays: json?['frequencyDays'] as int? ?? 7,
  );
}

FertilizingRule _parseFertilizing(Map<String, dynamic>? json) {
  return FertilizingRule(
    fertilizerName: json?['fertilizerName'] as String? ?? '',
    amount: (json?['amount'] as num?)?.toDouble() ?? 0,
    frequencyDays: json?['frequencyDays'] as int? ?? 14,
  );
}

ExperimentStage _parseStage(Map<String, dynamic> json) {
  return ExperimentStage(
    id: json['id'] as String,
    stageOrder: json['stageOrder'] as int? ?? 0,
    stageName: json['stageName'] as String? ?? json['name'] as String? ?? '',
    stageType: _parseStageType(json['stageType'] as String?),
    startDate: _parseDate(json['startDate']),
    endDate: _parseDate(json['endDate']),
    status: _parseStageStatus(json['status'] as String?),
    result: json['result'] != null
        ? StageResult(
            summary: json['result']['summary'] as String? ?? json['resultSummary'] as String? ?? '',
            metrics: (json['result']['metrics'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ),
          )
        : null,
  );
}

ExperimentStageType _parseStageType(String? s) {
  return switch (s?.toLowerCase()) {
    'nursery'       => ExperimentStageType.nursery,
    'preparation'   => ExperimentStageType.nursery,
    'planting'      => ExperimentStageType.care,
    'care'          => ExperimentStageType.care,
    'growing'       => ExperimentStageType.growth,
    'growth'        => ExperimentStageType.growth,
    'harvest'       => ExperimentStageType.harvest,
    'harvesting'    => ExperimentStageType.harvest,
    'postharvest'   => ExperimentStageType.evaluation,
    'evaluation'    => ExperimentStageType.evaluation,
    _               => ExperimentStageType.care,
  };
}

StageStatus _parseStageStatus(String? s) {
  return switch (s?.toLowerCase()) {
    'active'    => StageStatus.active,
    'completed' => StageStatus.completed,
    _           => StageStatus.upcoming,
  };
}
