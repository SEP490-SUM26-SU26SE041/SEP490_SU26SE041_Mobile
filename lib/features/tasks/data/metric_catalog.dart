/// Catalog mapping `metricName` (EN, chuẩn BE) → label tiếng Việt + unit.
///
/// BE lưu `metricName` theo chuẩn EN (vd: `height`, `leafCount`, `growthRate`),
/// nhưng UI mobile cần hiển thị tiếng Việt cho user nông dân / sinh viên VN.
///
/// Nguồn: xem `MOBILE_FLOW_SUMMARY.md` §4.3 `MEASUREMENT_FIELD_MAP`.
class MetricCatalog {
  static const Map<String, MetricDisplay> byName = {
    'height': MetricDisplay(label: 'Chiều cao cây', unit: 'cm', icon: 'height'),
    'plantHeight': MetricDisplay(label: 'Chiều cao cây', unit: 'cm', icon: 'height'),
    'leafCount': MetricDisplay(label: 'Số lá trung bình', unit: 'lá', icon: 'leaf'),
    'soLaTrungBinh': MetricDisplay(label: 'Số lá trung bình', unit: 'lá', icon: 'leaf'),
    'growthRate': MetricDisplay(label: 'Tốc độ sinh trưởng', unit: 'cm/ngày', icon: 'trending'),
    'tocDoSinhTruong': MetricDisplay(label: 'Tốc độ sinh trưởng', unit: 'cm/ngày', icon: 'trending'),
    'survivalRate': MetricDisplay(label: 'Tỷ lệ sống', unit: '%', icon: 'percent'),
    'tiLeSong': MetricDisplay(label: 'Tỷ lệ sống', unit: '%', icon: 'percent'),
    'fruitingRate': MetricDisplay(label: 'Tỷ lệ đậu quả', unit: '%', icon: 'percent'),
    'tiLeDauQua': MetricDisplay(label: 'Tỷ lệ đậu quả', unit: '%', icon: 'percent'),
    'waterAmount': MetricDisplay(label: 'Lượng nư�c tưới', unit: 'L/m²', icon: 'water'),
    'totalWater': MetricDisplay(label: 'Tổng lượng nước', unit: 'lít', icon: 'water'),
    'luongNuocTong': MetricDisplay(label: 'Tổng lượng nước', unit: 'lít', icon: 'water'),
    'wateringDuration': MetricDisplay(label: 'Thời gian tưới', unit: 'phút', icon: 'timer'),
    'soilMoistureBefore': MetricDisplay(label: 'Độ ẩm đất trước', unit: '%', icon: 'soil'),
    'soilMoistureAfter': MetricDisplay(label: 'Độ ẩm đất sau', unit: '%', icon: 'soil'),
    'fertilizerAmount': MetricDisplay(label: 'Liều lượng phân bón', unit: 'g/cây', icon: 'fertilizer'),
    'plantCount': MetricDisplay(label: 'Số cây', unit: 'cây', icon: 'count'),
    'weight': MetricDisplay(label: 'Sản lượng', unit: 'kg', icon: 'weight'),
    'harvestWeight': MetricDisplay(label: 'Khối lượng thu hoạch', unit: 'kg', icon: 'weight'),
    'sanLuongKg': MetricDisplay(label: 'Sản lượng', unit: 'kg', icon: 'weight'),
    'sanLuongTon': MetricDisplay(label: 'Sản lượng', unit: 'tấn', icon: 'weight'),
    'moistureContent': MetricDisplay(label: 'Độ ẩm sản phẩm', unit: '%', icon: 'percent'),
  };

  /// Tra cứu theo `metricName` (chính là key trong resultData hoặc MeasurementDefinition.metricName).
  static MetricDisplay? lookup(String? metricName) {
    if (metricName == null || metricName.isEmpty) return null;
    return byName[metricName];
  }

  /// Fallback hiển thị khi không tìm thấy trong catalog.
  static MetricDisplay fallback(String? rawKey) {
    if (rawKey == null || rawKey.isEmpty) {
      return const MetricDisplay(label: 'Chỉ số', unit: null, icon: 'ruler');
    }
    return MetricDisplay(
      label: _beautify(rawKey),
      unit: null,
      icon: 'ruler',
    );
  }

  static String _beautify(String key) {
    // 'plantHeight' → 'Plant Height'
    final s = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return s[0].toUpperCase() + s.substring(1);
  }
}

class MetricDisplay {
  const MetricDisplay({
    required this.label,
    required this.unit,
    required this.icon,
  });
  final String label;
  final String? unit;
  final String icon; // 'height' | 'leaf' | 'trending' | 'percent' | 'water' | 'timer' | 'soil' | 'fertilizer' | 'count' | 'weight' | 'ruler'
}
