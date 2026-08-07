/// Measurement definition chỉ số đo lường của experiment.
/// Fetch từ GET /experiments/{id}/measurements
class MeasurementDefinitionModel {
  const MeasurementDefinitionModel({
    required this.id,
    required this.metricName,
    this.unit,
    this.targetValue,
    this.description,
  });

  final String id;
  final String metricName;
  final String? unit;
  final double? targetValue;
  final String? description;

  factory MeasurementDefinitionModel.fromJson(Map<String, dynamic> json) {
    return MeasurementDefinitionModel(
      id: (json['id'] ?? '') as String,
      metricName: (json['metricName'] ?? json['name'] ?? 'Chỉ số') as String,
      unit: json['unit'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );
  }
}