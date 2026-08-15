/// Measurement definition chỉ số đo lường của experiment.
class MeasurementDefinitionModel {
  const MeasurementDefinitionModel({
    required this.id,
    required this.metricName,
    this.unit,
    this.targetValue,
    this.description,
    this.groupId,
    this.groupName,
  });

  final String id;
  final String metricName;
  final String? unit;
  final double? targetValue;
  final String? description;
  final String? groupId;
  final String? groupName;

  factory MeasurementDefinitionModel.fromJson(Map<String, dynamic> json) {
    return MeasurementDefinitionModel(
      id: (json['id'] ?? '') as String,
      metricName: (json['metricName'] ?? json['name'] ?? 'Chỉ số') as String,
      unit: json['unit'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      description: json['description'] as String?,
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'metricName': metricName,
        if (unit != null) 'unit': unit,
        if (targetValue != null) 'targetValue': targetValue,
        if (description != null) 'description': description,
        if (groupId != null) 'groupId': groupId,
      };
}
