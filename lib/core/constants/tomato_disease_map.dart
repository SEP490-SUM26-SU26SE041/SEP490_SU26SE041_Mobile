/// Mapping key bệnh (TomatoLeafDiseaseOnnx) → tên tiếng Việt + severity.
///
/// Dựa trên output thực tế từ model ONNX. Severity dùng để phân cấp badge.
class TomatoDiseaseMap {
  TomatoDiseaseMap._();

  /// Map key → metadata (Tiếng Việt, severity).
  static const Map<String, TomatoDiseaseMeta> _map = {
    'Tomato_Early_blight': TomatoDiseaseMeta(
      vietnamese: 'Bệnh đốm sớm',
      severity: DiseaseSeverity.high,
    ),
    'Tomato_Late_blight': TomatoDiseaseMeta(
      vietnamese: 'Bệnh đốm nâu',
      severity: DiseaseSeverity.critical,
    ),
    'Tomato_Leaf_Mold': TomatoDiseaseMeta(
      vietnamese: 'Bệnh mốc sương lá',
      severity: DiseaseSeverity.medium,
    ),
    'Tomato_Septoria_leaf_spot': TomatoDiseaseMeta(
      vietnamese: 'Bệnh đốm Septoria',
      severity: DiseaseSeverity.high,
    ),
    'Tomato_Spider_mites_Tetranychus': TomatoDiseaseMeta(
      vietnamese: 'Nhện đỏ',
      severity: DiseaseSeverity.medium,
    ),
    'Tomato__yellow_leaf_curl_virus': TomatoDiseaseMeta(
      vietnamese: 'Bệnh xoắn lá virus',
      severity: DiseaseSeverity.critical,
    ),
    'Tomato_mosaic_virus': TomatoDiseaseMeta(
      vietnamese: 'Bệnh khảm virus',
      severity: DiseaseSeverity.critical,
    ),
    'Bacterial_spot': TomatoDiseaseMeta(
      vietnamese: 'Bệnh đốm vi khuẩn',
      severity: DiseaseSeverity.high,
    ),
    'Target_Spot': TomatoDiseaseMeta(
      vietnamese: 'Bệnh đốm đích',
      severity: DiseaseSeverity.medium,
    ),
    'Healthy': TomatoDiseaseMeta(
      vietnamese: 'Khỏe mạnh',
      severity: DiseaseSeverity.none,
    ),
    'NotTomatoLeaf': TomatoDiseaseMeta(
      vietnamese: 'Không phải lá cà chua',
      severity: DiseaseSeverity.none,
    ),
  };

  /// Lấy meta theo key (case-insensitive). Trả null nếu không tìm thấy.
  static TomatoDiseaseMeta? lookup(String? key) {
    if (key == null || key.isEmpty) return null;
    return _map[key] ?? _map[key.toLowerCase()] ?? _map[key.toUpperCase()];
  }

  /// Lấy tên tiếng Việt (fallback: chính key).
  static String vietnamese(String? key) {
    return lookup(key)?.vietnamese ?? (key ?? 'Không xác định');
  }

  /// Lấy severity (fallback: none).
  static DiseaseSeverity severity(String? key) {
    return lookup(key)?.severity ?? DiseaseSeverity.none;
  }
}

enum DiseaseSeverity { none, medium, high, critical }

extension DiseaseSeverityX on DiseaseSeverity {
  String get label {
    switch (this) {
      case DiseaseSeverity.none:
        return 'Bình thường';
      case DiseaseSeverity.medium:
        return 'Trung bình';
      case DiseaseSeverity.high:
        return 'Cao';
      case DiseaseSeverity.critical:
        return 'Nghiêm trọng';
    }
  }
}

class TomatoDiseaseMeta {
  const TomatoDiseaseMeta({
    required this.vietnamese,
    required this.severity,
  });
  final String vietnamese;
  final DiseaseSeverity severity;
}
