import 'package:flutter/material.dart';

/// Mức độ nghiêm trọng của bệnh cây — mapped từ API response.
enum Severity { mild, moderate, severe, critical }

extension SeverityX on Severity {
  String get viLabel => switch (this) {
        Severity.mild => 'Nhẹ',
        Severity.moderate => 'Trung bình',
        Severity.severe => 'Nghiêm trọng',
        Severity.critical => 'Rất nghiêm trọng',
      };

  Color get color => switch (this) {
        Severity.mild => const Color(0xFF66BB6A),
        Severity.moderate => const Color(0xFFFFA726),
        Severity.severe => const Color(0xFFEF5350),
        Severity.critical => const Color(0xFFBA1A1A),
      };

  /// Map từ confidence (0.0-1.0) của API thành Severity enum.
  static Severity fromConfidence(double confidence) {
    if (confidence >= 0.85) return Severity.severe;
    if (confidence >= 0.65) return Severity.moderate;
    if (confidence >= 0.40) return Severity.mild;
    return Severity.mild;
  }
}

/// Một mục đề xuất xử lý (treatment).
class TreatmentItem {
  const TreatmentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.hasChevron = false,
  });

  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool hasChevron;
}

/// Bounding box từ AI detection — vẽ rectangle lên ảnh gốc.
///
/// Hai dạng API backend trả về:
///   - Tomato: `[x1, y1, x2, y2]` dạng `List<double>`
///   - Pest: `{"x1": 104, "y1": 5, "x2": 233, "y2": 199}` dạng `Map`
///
/// `originalWidth`/`originalHeight` là kích thước ảnh GỐC (pixel thật).
/// CustomPainter dùng 2 field này để scale bbox về đúng vị trí trên widget
/// hiển thị — đặc biệt quan trọng khi ảnh gốc không vuông (vd: ảnh chụp
/// 3024x4032 hiển thị widget 360x360).
class BoundingBox {
  const BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.originalWidth,
    required this.originalHeight,
  });

  factory BoundingBox.fromList(
    List<dynamic> list, {
    required int originalWidth,
    required int originalHeight,
  }) {
    return BoundingBox(
      x1: (list[0] as num).toDouble(),
      y1: (list[1] as num).toDouble(),
      x2: (list[2] as num).toDouble(),
      y2: (list[3] as num).toDouble(),
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );
  }

  factory BoundingBox.fromMap(
    Map<String, dynamic> map, {
    required int originalWidth,
    required int originalHeight,
  }) {
    return BoundingBox(
      x1: (map['x1'] as num).toDouble(),
      y1: (map['y1'] as num).toDouble(),
      x2: (map['x2'] as num).toDouble(),
      y2: (map['y2'] as num).toDouble(),
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );
  }

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final int originalWidth;
  final int originalHeight;

  double get width => x2 - x1;
  double get height => y2 - y1;

  /// Tính rect đã scale theo kích thước widget hiển thị, dùng cùng `BoxFit`
  /// mà widget hiển thị ảnh đang dùng (mặc định `BoxFit.cover`).
  ///
  /// Logic scale:
  ///   - BoxFit.cover: scale để phủ kín widget, giữ tỉ lệ ảnh → crop phần thừa.
  ///     + scale = max(widgetW / imgW, widgetH / imgH)
  ///     + bbox cũng scale theo; offset = ((widgetW - imgW*scale)/2, ...)
  Rect toRectInWidget({required Size widgetSize, BoxFit fit = BoxFit.cover}) {
    final imgW = originalWidth.toDouble();
    final imgH = originalHeight.toDouble();
    if (imgW <= 0 || imgH <= 0) {
      return Rect.zero;
    }
    final widgetW = widgetSize.width;
    final widgetH = widgetSize.height;

    double scale;
    double dx = 0;
    double dy = 0;
    switch (fit) {
      case BoxFit.cover:
        scale = widgetW / imgW > widgetH / imgH
            ? widgetW / imgW
            : widgetH / imgH;
        dx = (widgetW - imgW * scale) / 2;
        dy = (widgetH - imgH * scale) / 2;
        break;
      case BoxFit.contain:
        scale = widgetW / imgW < widgetH / imgH
            ? widgetW / imgW
            : widgetH / imgH;
        dx = (widgetW - imgW * scale) / 2;
        dy = (widgetH - imgH * scale) / 2;
        break;
      default:
        scale = widgetW / imgW;
        dx = 0;
        dy = (widgetH - imgH * scale) / 2;
    }

    return Rect.fromLTRB(
      dx + x1 * scale,
      dy + y1 * scale,
      dx + x2 * scale,
      dy + y2 * scale,
    );
  }
}

/// Phân loại detection: gate (tiền xử lý) vs disease (kết quả bệnh thật).
enum DetectionCategory {
  /// Detection từ gate model (kiểm tra ảnh có phải lá cà chua, có phải sâu bệnh).
  /// Thường có label như "tomato_leaf", "pest", "non_pest".
  gate,

  /// Detection thật của bệnh/sâu bệnh — kết quả cuối cùng của AI.
  disease,
}

/// Một detection đơn lẻ từ API — dùng cho cả Tomato và Pest.
///
/// Schema Tomato:
///   `{class_name, confidence, bbox: [x1,y1,x2,y2]}`
/// Schema Pest (mới):
///   `{class_name, classification_confidence, detection_confidence, box: {x1,y1,x2,y2}}`
class DetectionItem {
  const DetectionItem({
    required this.label,
    required this.confidence,
    this.box,
    this.classId,
    this.detectorClassId,
    this.category = DetectionCategory.disease,
  });

  /// Tên class — Tomto/Pest API có thể trả `class_name` hoặc `class`.
  final String label;

  /// Confidence (0.0 → 1.0). Pest API có 2 loại, ưu tiên `classification_confidence`.
  final double confidence;

  /// Bounding box (nếu có).
  final BoundingBox? box;

  /// `class_id` (Pest API mới).
  final int? classId;

  /// `detector_class_id` (Pest API mới).
  final int? detectorClassId;

  /// Gate hay disease. UI sẽ hiển thị gate với style nhạt hơn.
  final DetectionCategory category;

  int get confidencePercent => (confidence * 100).round();
}

/// Kết quả chẩn đoán từ AI — thống nhất từ 2 API.
class DiseaseResult {
  const DiseaseResult({
    required this.diseaseName,
    required this.diseaseSubtitle,
    required this.severity,
    required this.confidencePercent,
    required this.detectedAt,
    required this.scanImageUrl,
    required this.treatments,
    required this.plantType,
    this.description = '',
    this.detections = const <DetectionItem>[],
    this.probabilities = const <String, double>{},
    this.annotatedImageBytes,
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  /// Tên bệnh (từ class_name / class của API).
  final String diseaseName;

  /// Subtitle — phụ đề, ví dụ: "Cercospora" hoặc "Aphid".
  final String diseaseSubtitle;

  final Severity severity;

  /// Độ tin cậy 0-100 (đã nhân 100 từ API 0.0-1.0).
  final int confidencePercent;

  /// Thời gian phát hiện (relative string, e.g. "2 giờ trước").
  final String detectedAt;

  /// URL ảnh đã scan.
  final String scanImageUrl;

  final List<TreatmentItem> treatments;

  /// Mô tả bệnh — từ disease_info.description của Tomato API.
  final String description;

  /// Loại cây/loại chẩn đoán: 'tomato' hoặc 'pest'.
  final String plantType;

  /// Tất cả detections API trả về (không chỉ first) — dùng để vẽ bbox overlay.
  final List<DetectionItem> detections;

  /// Probabilities cho mọi classes (Tomato API — nếu backend trả về).
  /// Key: tên class (snake_case). Value: probability (0.0 → 1.0).
  final Map<String, double> probabilities;

  /// Annotated image (Pest API trả về base64) — ảnh đã vẽ bbox sẵn.
  /// Mobile dùng cái này nếu có để khỏi tự paint overlay.
  final List<int>? annotatedImageBytes;

  /// Kích thước ảnh GỐC (pixel thật) — cần cho BoundingBox.toRectInWidget
  /// để scale bbox về đúng vị trí trên widget hiển thị.
  final int imageWidth;
  final int imageHeight;

  bool get hasAnnotatedImage =>
      annotatedImageBytes != null && annotatedImageBytes!.isNotEmpty;

  bool get hasBboxOverlay => detections.any((d) => d.box != null);

  /// Chỉ lấy detection loại disease (bệnh thật) — bỏ gate detection.
  List<DetectionItem> get diseaseDetections => detections
      .where((d) => d.category == DetectionCategory.disease)
      .toList(growable: false);

  /// Chỉ lấy detection loại gate (tiền xử lý).
  List<DetectionItem> get gateDetections => detections
      .where((d) => d.category == DetectionCategory.gate)
      .toList(growable: false);
}

/// Mock data cho preview / initial state.
class MockAiScan {
  static const String heroImage =
      'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80';

  static const DiseaseResult currentResult = DiseaseResult(
    diseaseName: 'Đốm lá (Leaf Spot)',
    diseaseSubtitle: 'Cercospora',
    severity: Severity.severe,
    confidencePercent: 98,
    detectedAt: '2 giờ trước',
    scanImageUrl: heroImage,
    plantType: 'tomato',
    treatments: [
      TreatmentItem(
        id: 't1',
        title: 'Loại bỏ lá bệnh',
        description: 'Cắt bỏ các lá bị đốm và tiêu hủy xa khu vực canh tác.',
        iconName: 'content_cut',
      ),
      TreatmentItem(
        id: 't2',
        title: 'Phun thuốc gốc đồng',
        description: 'Sử dụng Fungicide phù hợp để ngăn chặn nấm lan rộng.',
        iconName: 'opacity',
        hasChevron: true,
      ),
      TreatmentItem(
        id: 't3',
        title: 'Cải thiện thông gió',
        description: 'Giãn cách các chậu cây để giảm độ ẩm bề mặt lá.',
        iconName: 'air',
      ),
    ],
  );

  static const List<String> recentScanImages = [
    'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&q=60',
    'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400&q=60',
    'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?w=400&q=60',
  ];
}
