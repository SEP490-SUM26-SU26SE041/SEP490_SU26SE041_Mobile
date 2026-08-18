/// Field type cho measurement definition.
/// Xác định loại input control hiển thị trên form.
enum MeasurementFieldType {
  number,
  text,
  select,
  multiSelect;

  static MeasurementFieldType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'text':
        return MeasurementFieldType.text;
      case 'select':
        return MeasurementFieldType.select;
      case 'multiselect':
      case 'multi_select':
        return MeasurementFieldType.multiSelect;
      case 'number':
      default:
        return MeasurementFieldType.number;
    }
  }
}

/// Một option cho field type select/multiSelect.
class MeasurementOption {
  const MeasurementOption({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final String? color;

  factory MeasurementOption.fromJson(Map<String, dynamic> json) {
    return MeasurementOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? json['value']?.toString() ?? '',
      color: json['color'] as String?,
    );
  }
}

/// Measurement definition chỉ số đo lường của experiment.
/// Hỗ trợ field types động: number, text, select, multiSelect.
class MeasurementDefinitionModel {
  const MeasurementDefinitionModel({
    required this.id,
    required this.metricName,
    this.unit,
    this.targetValue,
    this.description,
    this.groupId,
    this.groupName,
    this.fieldType = MeasurementFieldType.number,
    this.options = const [],
    this.minValue,
    this.maxValue,
  });

  final String id;
  final String metricName;
  final String? unit;
  final double? targetValue;
  final String? description;
  final String? groupId;
  final String? groupName;

  /// Loại field - mặc định là number.
  final MeasurementFieldType fieldType;

  /// Danh sách options cho field type select/multiSelect.
  /// VD: Màu lá → [{value: 'xanh', label: 'Xanh'}, {value: 'vang', label: 'Vàng'}]
  final List<MeasurementOption> options;

  /// Giá trị min/max cho field type number.
  final double? minValue;
  final double? maxValue;

  /// Check xem có phải là field chọn (select/multiSelect) không.
  bool get isChoiceField =>
      fieldType == MeasurementFieldType.select ||
      fieldType == MeasurementFieldType.multiSelect;

  factory MeasurementDefinitionModel.fromJson(Map<String, dynamic> json) {
    // Parse options
    final optionsList = <MeasurementOption>[];
    final rawOptions = json['options'];
    if (rawOptions is List) {
      optionsList.addAll(
        rawOptions.whereType<Map>().map(
              (e) => MeasurementOption.fromJson(Map<String, dynamic>.from(e)),
            ),
      );
    }

    return MeasurementDefinitionModel(
      id: (json['id'] ?? '') as String,
      metricName: (json['metricName'] ?? json['name'] ?? 'Chỉ số') as String,
      unit: json['unit'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      description: json['description'] as String?,
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      fieldType: MeasurementFieldType.fromString(json['fieldType'] as String?),
      options: optionsList,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'metricName': metricName,
        if (unit != null) 'unit': unit,
        if (targetValue != null) 'targetValue': targetValue,
        if (description != null) 'description': description,
        if (groupId != null) 'groupId': groupId,
        if (fieldType != MeasurementFieldType.number) 'fieldType': fieldType.name,
        if (options.isNotEmpty)
          'options': options.map((e) => {'value': e.value, 'label': e.label}).toList(),
        if (minValue != null) 'minValue': minValue,
        if (maxValue != null) 'maxValue': maxValue,
      };
}
