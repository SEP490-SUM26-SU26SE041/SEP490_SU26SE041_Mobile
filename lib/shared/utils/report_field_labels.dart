/// Mapping các key trong `resultData` của TaskReport sang label tiếng Việt
/// để hiển thị trong UI (đặc biệt là "Lịch sử báo cáo").
///
/// Bao gồm:
/// - Tất cả keys trong `kMeasurementFieldMap` (đã có description sẵn).
/// - Tất cả field keys trong `kQuickFormSchema` (mỗi schema spec có `label`).
/// - Một vài key đặc biệt (`condition`, `additionalNotes`).
///
/// Đơn vị (unit) được gộp vào label nếu tồn tại, ví dụ:
///   `plantCount` → "Số cây trồng/thu hoạch (cây)".
library;

import '../../../features/tasks/data/task_report_constants.dart';

/// Lookup table: key → Vietnamese label (kèm unit).
/// Ưu tiên [kMeasurementFieldMap] → fallback [kQuickFormSchema] → fallback custom.
final Map<String, String> kReportFieldLabels = _buildLabelMap();

Map<String, String> _buildLabelMap() {
  final map = <String, String>{};

  // 1. From measurement field map (canonical Vietnamese descriptions).
  kMeasurementFieldMap.forEach((key, m) {
    final unit = m.targetUnit;
    map[key] = unit.isNotEmpty ? '${m.description} ($unit)' : m.description;
  });

  // 2. From quick form schemas (covers select options + custom labels).
  kQuickFormSchema.forEach((type, schema) {
    for (final f in schema.fields) {
      if (f.label.isEmpty) continue;
      // Nếu chưa có hoặc đang là measurement description (ngắn hơn),
      // ưu tiên label từ schema (vì thường đầy đủ ngữ cảnh hơn).
      final existing = map[f.key];
      final label = f.unit != null ? '${f.label} (${f.unit})' : f.label;
      if (existing == null || label.length > existing.length) {
        map[f.key] = label;
      }
    }
  });

  // 3. Custom / cross-cutting keys.
  const customs = <String, String>{
    'condition': 'Tình trạng sức khỏe',
    'additionalNotes': 'Ghi chú thêm',
    'soilCondition': 'Tình trạng đất',
    'seedlingSource': 'Nguồn giống',
    'overallHealth': 'Tình trạng tổng thể',
    'pestDiseaseLevel': 'Mức độ sâu bệnh',
    'inspectionChecklist': 'Checklist tuân thủ',
    'qualityGrade': 'Phân loại chất lượng',
    'leafColor': 'Màu lá',
    'irrigationMethod': 'Phương pháp tưới',
    'duration': 'Thời gian (phút)',
    'waterAmount': 'Lượng nước (L)',
  };
  customs.forEach((k, v) {
    map[k] = v;
  });

  return map;
}

/// Resolve key → Vietnamese label. Fallback: humanized raw key.
String labelForReportKey(String key) {
  final direct = kReportFieldLabels[key];
  if (direct != null) return direct;
  // Humanize camelCase / snake_case → "Có dấu cách".
  return _humanize(key);
}

String _humanize(String s) {
  if (s.isEmpty) return s;
  // Insert space before uppercase letters, capitalize first letter.
  final spaced = s
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}