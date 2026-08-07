import '../../utils/date_utils.dart';

/// MeasurementRecord model matching SmartFarm backend API response.
///
/// Maps to: POST/GET /measurement-records
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
    required this.recordedBy,
    this.recordedByName,
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
  final String recordedBy;
  final String? recordedByName;
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
      recordedBy: json['recordedBy'] as String,
      recordedByName: json['recordedByName'] as String?,
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
