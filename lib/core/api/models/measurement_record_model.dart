import '../../utils/date_utils.dart';

/// ─── MeasurementRecord ─────────────────────────────────────────────────────────

/// Bản ghi đo lường đơn lẻ.
class MeasurementRecordModel {
  const MeasurementRecordModel({
    required this.id,
    required this.experimentId,
    this.experimentTitle,
    required this.experimentStageId,
    this.experimentStageName,
    required this.batchId,
    this.batchCode,
    required this.measurementDefinitionId,
    this.measurementDefinitionName,
    required this.value,
    this.textValue,
    required this.measuredAt,
    this.measuredBy,
    this.measuredByName,
    this.extraData,
    required this.createdAt,
  });

  final String id;
  final String experimentId;
  final String? experimentTitle;
  final String experimentStageId;
  final String? experimentStageName;
  final String batchId;
  final String? batchCode;
  final String measurementDefinitionId;
  final String? measurementDefinitionName;
  final double value;
  final String? textValue;
  final DateTime measuredAt;
  final String? measuredBy;
  final String? measuredByName;
  final Map<String, dynamic>? extraData;
  final DateTime createdAt;

  factory MeasurementRecordModel.fromJson(Map<String, dynamic> json) {
    return MeasurementRecordModel(
      id: json['id'] as String,
      experimentId: json['experimentId'] as String,
      experimentTitle: json['experimentTitle'] as String?,
      experimentStageId: json['experimentStageId'] as String,
      experimentStageName: json['experimentStageName'] as String?,
      batchId: json['batchId'] as String,
      batchCode: json['batchCode'] as String?,
      measurementDefinitionId: json['measurementDefinitionId'] as String,
      measurementDefinitionName: json['measurementDefinitionName'] as String?,
      value: (json['value'] as num).toDouble(),
      textValue: json['textValue'] as String?,
      measuredAt: parseApiDateTimeOrNow(json['measuredAt']?.toString()),
      measuredBy: json['measuredBy'] as String?,
      measuredByName: json['measuredByName'] as String?,
      extraData: json['extraData'] as Map<String, dynamic>?,
      createdAt: parseApiDateTimeOrNow(json['createdAt']?.toString()),
    );
  }

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

// ─── MeasurementDefinition ────────────────────────────────────────────────────

// ─── Bulk Create ────────────────────────────────────────────────────────────

class BulkMeasurementItem {
  const BulkMeasurementItem({
    required this.measurementDefinitionId,
    required this.value,
  });

  final String measurementDefinitionId;
  final double value;

  Map<String, dynamic> toJson() => {
        'measurementDefinitionId': measurementDefinitionId,
        'value': value,
      };
}

class BulkMeasurementDto {
  const BulkMeasurementDto({
    required this.experimentId,
    required this.experimentStageId,
    required this.batchId,
    required this.measuredAt,
    this.extraData,
    required this.items,
  });

  final String experimentId;
  final String experimentStageId;
  final String batchId;
  final DateTime measuredAt;
  final Map<String, dynamic>? extraData;
  final List<BulkMeasurementItem> items;

  Map<String, dynamic> toJson() => {
        'experimentId': experimentId,
        'experimentStageId': experimentStageId,
        'batchId': batchId,
        'measuredAt': measuredAt.toIso8601String(),
        if (extraData != null) 'extraData': extraData,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class BulkMeasurementResponse {
  const BulkMeasurementResponse({
    required this.batchId,
    required this.experimentStageId,
    required this.measuredAt,
    required this.created,
    required this.skipped,
    required this.warnings,
    required this.records,
  });

  final String batchId;
  final String experimentStageId;
  final DateTime measuredAt;
  final int created;
  final int skipped;
  final List<String> warnings;
  final List<MeasurementRecordModel> records;

  factory BulkMeasurementResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return BulkMeasurementResponse(
      batchId: data['batchId'] as String,
      experimentStageId: data['experimentStageId'] as String,
      measuredAt: parseApiDateTimeOrNow((data['measuredAt'] ?? '').toString()),
      created: data['created'] as int? ?? 0,
      skipped: data['skipped'] as int? ?? 0,
      warnings: (data['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      records: (data['records'] as List?)
              ?.map((e) => MeasurementRecordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ─── Statistics ──────────────────────────────────────────────────────────────

class MetricStatistics {
  const MetricStatistics({
    required this.definitionId,
    required this.metricName,
    this.unit,
    this.targetValue,
    required this.sampleCount,
    required this.average,
    required this.min,
    required this.max,
    required this.stdDev,
    required this.median,
    required this.q1,
    required this.q3,
    required this.reachesTarget,
    required this.targetAchievementRatio,
  });

  final String definitionId;
  final String metricName;
  final String? unit;
  final double? targetValue;
  final int sampleCount;
  final double average;
  final double min;
  final double max;
  final double stdDev;
  final double median;
  final double q1;
  final double q3;
  final bool reachesTarget;
  final double targetAchievementRatio;

  factory MetricStatistics.fromJson(Map<String, dynamic> json) {
    return MetricStatistics(
      definitionId: json['definitionId'] as String,
      metricName: json['metricName'] as String,
      unit: json['unit'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      sampleCount: json['sampleCount'] as int? ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0,
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 0,
      stdDev: (json['stdDev'] as num?)?.toDouble() ?? 0,
      median: (json['median'] as num?)?.toDouble() ?? 0,
      q1: (json['q1'] as num?)?.toDouble() ?? 0,
      q3: (json['q3'] as num?)?.toDouble() ?? 0,
      reachesTarget: json['reachesTarget'] as bool? ?? false,
      targetAchievementRatio:
          (json['targetAchievementRatio'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GrowthDataPoint {
  const GrowthDataPoint({
    required this.measuredAt,
    required this.average,
    required this.sampleCount,
    required this.growthRatePercent,
  });

  final DateTime measuredAt;
  final double average;
  final int sampleCount;
  final double growthRatePercent;

  factory GrowthDataPoint.fromJson(Map<String, dynamic> json) {
    return GrowthDataPoint(
      measuredAt: parseApiDateTimeOrNow((json['measuredAt'] ?? '').toString()),
      average: (json['average'] as num?)?.toDouble() ?? 0,
      sampleCount: json['sampleCount'] as int? ?? 0,
      growthRatePercent: (json['growthRatePercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GroupStatistics {
  const GroupStatistics({
    required this.groupId,
    required this.groupName,
    required this.groupType,
    required this.batchCount,
    required this.totalSamples,
    required this.metrics,
    required this.growthOverTime,
  });

  final String groupId;
  final String groupName;
  final String groupType;
  final int batchCount;
  final int totalSamples;
  final List<MetricStatistics> metrics;
  final List<GrowthDataPoint> growthOverTime;

  factory GroupStatistics.fromJson(Map<String, dynamic> json) {
    return GroupStatistics(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      groupType: json['groupType'] as String? ?? 'Treatment',
      batchCount: json['batchCount'] as int? ?? 0,
      totalSamples: json['totalSamples'] as int? ?? 0,
      metrics: (json['metrics'] as List?)
              ?.map((e) => MetricStatistics.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      growthOverTime: (json['growthOverTime'] as List?)
              ?.map((e) => GrowthDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GroupComparisonValue {
  const GroupComparisonValue({
    required this.groupId,
    required this.groupName,
    required this.average,
    required this.sampleCount,
    required this.stdDev,
  });

  final String groupId;
  final String groupName;
  final double average;
  final int sampleCount;
  final double stdDev;

  factory GroupComparisonValue.fromJson(Map<String, dynamic> json) {
    return GroupComparisonValue(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      average: (json['average'] as num?)?.toDouble() ?? 0,
      sampleCount: json['sampleCount'] as int? ?? 0,
      stdDev: (json['stdDev'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MetricComparison {
  const MetricComparison({
    required this.definitionId,
    required this.metricName,
    this.unit,
    required this.groupValues,
    required this.maxDifference,
    required this.bestGroupId,
    required this.bestGroupName,
    required this.significantDifference,
  });

  final String definitionId;
  final String metricName;
  final String? unit;
  final List<GroupComparisonValue> groupValues;
  final double maxDifference;
  final String bestGroupId;
  final String bestGroupName;
  final bool significantDifference;

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    return MetricComparison(
      definitionId: json['definitionId'] as String,
      metricName: json['metricName'] as String,
      unit: json['unit'] as String?,
      groupValues: (json['groupValues'] as List?)
              ?.map((e) => GroupComparisonValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      maxDifference: (json['maxDifference'] as num?)?.toDouble() ?? 0,
      bestGroupId: json['bestGroupId'] as String,
      bestGroupName: json['bestGroupName'] as String,
      significantDifference: json['significantDifference'] as bool? ?? false,
    );
  }
}

class CrossGroupComparison {
  const CrossGroupComparison({
    required this.metrics,
    required this.bestGroupId,
    required this.bestGroupName,
    this.summary,
  });

  final List<MetricComparison> metrics;
  final String bestGroupId;
  final String bestGroupName;
  final String? summary;

  factory CrossGroupComparison.fromJson(Map<String, dynamic> json) {
    return CrossGroupComparison(
      metrics: (json['metrics'] as List?)
              ?.map((e) => MetricComparison.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bestGroupId: json['bestGroupId'] as String,
      bestGroupName: json['bestGroupName'] as String,
      summary: json['summary'] as String?,
    );
  }
}

class MeasurementStatisticsResponse {
  const MeasurementStatisticsResponse({
    required this.stageId,
    required this.stageName,
    required this.experimentId,
    required this.statisticsType,
    required this.definitionCount,
    required this.generatedAt,
    required this.groups,
    this.crossGroupComparison,
  });

  final String stageId;
  final String stageName;
  final String experimentId;
  final String statisticsType;
  final int definitionCount;
  final DateTime generatedAt;
  final List<GroupStatistics> groups;
  final CrossGroupComparison? crossGroupComparison;

  factory MeasurementStatisticsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MeasurementStatisticsResponse(
      stageId: data['stageId'] as String,
      stageName: data['stageName'] as String,
      experimentId: data['experimentId'] as String,
      statisticsType: data['statisticsType'] as String? ?? 'MeasurementStats',
      definitionCount: data['definitionCount'] as int? ?? 0,
      generatedAt:
          parseApiDateTimeOrNow((data['generatedAt'] ?? '').toString()),
      groups: (data['groups'] as List?)
              ?.map((e) => GroupStatistics.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      crossGroupComparison: data['crossGroupComparison'] != null
          ? CrossGroupComparison.fromJson(
              data['crossGroupComparison'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── Validation ──────────────────────────────────────────────────────────────

class MeasurementValidationResult {
  const MeasurementValidationResult({
    required this.success,
    required this.errors,
  });

  final bool success;
  final List<String> errors;

  factory MeasurementValidationResult.fromJson(Map<String, dynamic> json) {
    return MeasurementValidationResult(
      success: json['success'] as bool? ?? true,
      errors: (json['errors'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
