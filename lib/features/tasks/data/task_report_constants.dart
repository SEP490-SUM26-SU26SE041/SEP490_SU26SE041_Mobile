library;

import '../../../core/api/models/task_model.dart' as api;

/// Constants & schema cho TaskReport bridge flow.
///
/// Bao gồm:
///   - [MeasurementFieldMapping] bảng mapping flat key → MeasurementName (theo SPEC.md).
///   - [QuickFormFieldSpec] / [QuickFormSchema] form cố định cho 6 task types.
///   - Helper [ResultEntry].

// ─── Result data entry ──────────────────────────────────────────────────────

/// Một cặp key-value trong `resultData` của TaskReport.
/// value luôn là String để tương thích với TextField + BE.
class ResultEntry {
  const ResultEntry({required this.key, required this.value});

  final String key;
  final String value;

  Map<String, dynamic> toJson() => {key: value};

  @override
  String toString() => '$key=$value';
}

// ─── MEASUREMENT_FIELD_MAP ──────────────────────────────────────────────────

/// Mapping từ flat key trong `resultData` → MeasurementRecord field.
///
/// Dùng cho "legacy path": Bridge sẽ tìm các key trong resultData có trong
/// map này và tạo MeasurementRecord tương ứng.
///
/// Lấy từ TASK_REPORT_BRIDGE_FLOW.md mục 4.4 — `MEASUREMENT_FIELD_MAP` (FE JS).
class MeasurementFieldMapping {
  const MeasurementFieldMapping({
    required this.targetName,
    required this.targetUnit,
    required this.description,
  });

  final String targetName;
  final String targetUnit;
  final String description;
}

/// Bảng field-map (phiên bản Flutter, lấy y hệt từ FE JS).
const Map<String, MeasurementFieldMapping> kMeasurementFieldMap = {
  // Plant metrics
  'plantHeight': MeasurementFieldMapping(targetName: 'height', targetUnit: 'cm', description: 'Chiều cao cây'),
  'chieuCaoCm': MeasurementFieldMapping(targetName: 'height', targetUnit: 'cm', description: 'Chiều cao cây'),
  'leafCount': MeasurementFieldMapping(targetName: 'leafCount', targetUnit: 'lá', description: 'Số lá trung bình'),
  'soLaTrungBinh': MeasurementFieldMapping(targetName: 'leafCount', targetUnit: 'lá', description: 'Số lá trung bình'),
  'tocDoSinhTruong': MeasurementFieldMapping(targetName: 'growthRate', targetUnit: 'cm/ngày', description: 'Tốc độ sinh trưởng'),
  'tiLeSong': MeasurementFieldMapping(targetName: 'survivalRate', targetUnit: '%', description: 'Tỷ lệ sống'),
  'tiLeDauQua': MeasurementFieldMapping(targetName: 'fruitingRate', targetUnit: '%', description: 'Tỷ lệ đậu quả'),

  // Watering
  'waterAmount': MeasurementFieldMapping(targetName: 'waterAmount', targetUnit: 'L/m²', description: 'Lượng nước tưới'),
  'luongNuocTong': MeasurementFieldMapping(targetName: 'totalWater', targetUnit: 'lít', description: 'Tổng lượng nước'),
  'soLanTuoi': MeasurementFieldMapping(targetName: 'wateringCount', targetUnit: 'lần', description: 'Số lần tưới'),
  'duration': MeasurementFieldMapping(targetName: 'wateringDuration', targetUnit: 'phút', description: 'Thời gian tưới'),
  'soilMoistureBefore': MeasurementFieldMapping(targetName: 'soilMoistureBefore', targetUnit: '%', description: 'Độ ẩm đất trước tưới'),
  'soilMoistureAfter': MeasurementFieldMapping(targetName: 'soilMoistureAfter', targetUnit: '%', description: 'Độ ẩm đất sau tưới'),

  // Fertilizing
  'fertilizerAmount': MeasurementFieldMapping(targetName: 'fertilizerAmount', targetUnit: 'g/cây', description: 'Liều lượng phân bón'),
  'soLanBonPhan': MeasurementFieldMapping(targetName: 'fertilizingCount', targetUnit: 'lần', description: 'Số lần bón phân'),
  'soLanPhunThuoc': MeasurementFieldMapping(targetName: 'pesticideCount', targetUnit: 'lần', description: 'Số lần phun thuốc BVTV'),

  // Planting
  'plantCount': MeasurementFieldMapping(targetName: 'plantCount', targetUnit: 'cây', description: 'Số cây trồng/thu hoạch'),
  'plantSpacing': MeasurementFieldMapping(targetName: 'plantSpacing', targetUnit: 'cm', description: 'Khoảng cách cây'),
  'soLuong': MeasurementFieldMapping(targetName: 'plantCount', targetUnit: 'cây', description: 'Số lượng'),

  // Inspection
  'affectedPlantCount': MeasurementFieldMapping(targetName: 'affectedPlantCount', targetUnit: 'cây', description: 'Số cây bị ảnh hưởng'),
  'tyLeHaoHut': MeasurementFieldMapping(targetName: 'lossRate', targetUnit: '%', description: 'Tỷ lệ hao hụt'),

  // Harvest
  'harvestWeight': MeasurementFieldMapping(targetName: 'weight', targetUnit: 'kg', description: 'Khối lượng thu hoạch'),
  'sanLuongKg': MeasurementFieldMapping(targetName: 'weight', targetUnit: 'kg', description: 'Sản lượng (kg)'),
  'sanLuongTan': MeasurementFieldMapping(targetName: 'weightTon', targetUnit: 'tấn', description: 'Sản lượng (tấn)'),
  'averagePerPlant': MeasurementFieldMapping(targetName: 'yieldPerPlant', targetUnit: 'kg/cây', description: 'Trung bình/cây'),
  'moistureContent': MeasurementFieldMapping(targetName: 'moistureContent', targetUnit: '%', description: 'Độ ẩm sản phẩm'),

  // PostHarvest
  'khoiLuongBaoQuan': MeasurementFieldMapping(targetName: 'storageWeight', targetUnit: 'kg', description: 'Khối lượng bảo quản'),
  'nhietDoBaoQuan': MeasurementFieldMapping(targetName: 'storageTemp', targetUnit: '°C', description: 'Nhiệt độ bảo quản'),
};

// ─── QUICK_FORM_SCHEMA ──────────────────────────────────────────────────────

/// Kiểu field trong quick form.
enum QuickFieldType { number, select, text }

/// Spec của 1 field trong quick form.
class QuickFormFieldSpec {
  const QuickFormFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    this.options,
    this.allowDecimal = false,
    this.required = false,
    this.group,
    this.description,
    this.placeholder,
  });

  /// Key trong `resultData` của TaskReport.
  final String key;

  /// Label hiển thị cho user.
  final String label;

  final QuickFieldType type;
  final String? unit;
  final List<String>? options;
  final bool allowDecimal;
  final bool required;

  /// Optional — nhóm các field để render có heading trong form.
  final String? group;

  /// Optional — dòng mô tả dưới label.
  final String? description;

  /// Optional — placeholder cho input.
  final String? placeholder;
}

/// Spec của form cho 1 task type.
class QuickFormSchema {
  const QuickFormSchema({required this.iconName, required this.fields, this.isDynamic = false});

  /// Tên Material icon (tránh import icon trong lib/util).
  final String iconName;

  /// Danh sách fields (không dùng khi `isDynamic == true`).
  final List<QuickFormFieldSpec> fields;

  /// Nếu true: form động dựa trên MeasurementDefinitions (không hardcoded fields).
  /// Áp dụng cho `Measurement` và `Observation`.
  final bool isDynamic;
}

/// Schema cho 8 task types (phiên bản Flutter, lấy y hệt FE JS).
const Map<api.TaskType, QuickFormSchema> kQuickFormSchema = {
  api.TaskType.planting: QuickFormSchema(
    iconName: 'eco',
    fields: [
      QuickFormFieldSpec(key: 'plantCount', label: 'Số cây đã trồng', type: QuickFieldType.number, unit: 'cây', required: true),
      QuickFormFieldSpec(key: 'plantSpacing', label: 'Khoảng cách cây', type: QuickFieldType.number, unit: 'cm'),
      QuickFormFieldSpec(
        key: 'soilCondition',
        label: 'Tình trạng đất',
        type: QuickFieldType.select,
        options: ['Tốt', 'Trung bình', 'Khô', 'Ẩm ướt'],
      ),
      QuickFormFieldSpec(key: 'seedlingSource', label: 'Nguồn giống', type: QuickFieldType.text),
    ],
  ),
  api.TaskType.watering: QuickFormSchema(
    iconName: 'water_drop',
    fields: [
      QuickFormFieldSpec(key: 'waterAmount', label: 'Lượng nước tưới', type: QuickFieldType.number, unit: 'L/m²', allowDecimal: true, required: true, group: 'Tưới nước'),
      QuickFormFieldSpec(
        key: 'irrigationMethod',
        label: 'Phương pháp tưới',
        type: QuickFieldType.select,
        options: ['Phun mưa', 'Nhỏ giọt', 'Thủ công', 'Ngập'],
        group: 'Tưới nước',
      ),
      QuickFormFieldSpec(key: 'duration', label: 'Thời gian tưới', type: QuickFieldType.number, unit: 'phút', group: 'Tưới nước'),
      QuickFormFieldSpec(key: 'soilMoistureBefore', label: 'Độ ẩm đất trước', type: QuickFieldType.number, unit: '%', group: 'Chất lượng đất'),
      QuickFormFieldSpec(key: 'soilMoistureAfter', label: 'Độ ẩm đất sau', type: QuickFieldType.number, unit: '%', group: 'Chất lượng đất'),
    ],
  ),
  api.TaskType.fertilizing: QuickFormSchema(
    iconName: 'science',
    fields: [
      QuickFormFieldSpec(
        key: 'fertilizerType',
        label: 'Loại phân',
        type: QuickFieldType.select,
        options: ['NPK', 'Hữu cơ', 'Vi sinh', 'Ure', 'Phân chuồng', 'Phân xanh', 'Khác'],
      ),
      QuickFormFieldSpec(key: 'fertilizerAmount', label: 'Liều lượng', type: QuickFieldType.number, unit: 'g/cây', allowDecimal: true),
      QuickFormFieldSpec(key: 'fertilizerBrand', label: 'Thương hiệu', type: QuickFieldType.text),
      QuickFormFieldSpec(
        key: 'applicationMethod',
        label: 'Cách bón',
        type: QuickFieldType.select,
        options: ['Rải gốc', 'Pha nước', 'Bón lá', 'Bón theo hàng'],
      ),
    ],
  ),
  api.TaskType.inspection: QuickFormSchema(
    iconName: 'search',
    fields: [
      QuickFormFieldSpec(
        key: 'overallHealth',
        label: 'Tình trạng tổng thể',
        type: QuickFieldType.select,
        options: ['Tốt', 'Trung bình', 'Yếu', 'Có vấn đề'],
      ),
      QuickFormFieldSpec(
        key: 'pestDiseaseLevel',
        label: 'Mức độ sâu bệnh',
        type: QuickFieldType.select,
        options: ['Không có', 'Nhẹ', 'Trung bình', 'Nặng'],
      ),
      QuickFormFieldSpec(key: 'affectedPlantCount', label: 'Số cây bị ảnh hưởng', type: QuickFieldType.number, unit: 'cây'),
      QuickFormFieldSpec(
        key: 'inspectionChecklist',
        label: 'Checklist tuân thủ',
        type: QuickFieldType.select,
        options: ['Đạt', 'Cần cải thiện', 'Không đạt'],
      ),
    ],
  ),
  api.TaskType.harvest: QuickFormSchema(
    iconName: 'agriculture',
    fields: [
      QuickFormFieldSpec(key: 'harvestWeight', label: 'Khối lượng thu hoạch', type: QuickFieldType.number, unit: 'kg', allowDecimal: true, required: true),
      QuickFormFieldSpec(
        key: 'qualityGrade',
        label: 'Phân loại chất lượng',
        type: QuickFieldType.select,
        options: ['Loại A', 'Loại B', 'Loại C', 'Không phân loại'],
      ),
      QuickFormFieldSpec(key: 'plantCount', label: 'Số cây thu hoạch', type: QuickFieldType.number, unit: 'cây'),
      QuickFormFieldSpec(key: 'averagePerPlant', label: 'Trung bình/cây', type: QuickFieldType.number, unit: 'kg', allowDecimal: true),
      QuickFormFieldSpec(key: 'moistureContent', label: 'Độ ẩm', type: QuickFieldType.number, unit: '%'),
    ],
  ),
  api.TaskType.other: QuickFormSchema(iconName: 'description', fields: []),
  api.TaskType.observation: QuickFormSchema(iconName: 'visibility', fields: [], isDynamic: true),
  api.TaskType.measurement: QuickFormSchema(iconName: 'straighten', fields: [], isDynamic: true),
};

/// Map các task type dùng dynamic measurement form (Measurement/Observation).
const Set<api.TaskType> kDynamicMeasurementTaskTypes = {
  api.TaskType.observation,
  api.TaskType.measurement,
};

/// Cờ: task có dùng bulk path cho measurement records?
bool isMeasurementTask(api.TaskType t) => t == api.TaskType.measurement || kDynamicMeasurementTaskTypes.contains(t);
