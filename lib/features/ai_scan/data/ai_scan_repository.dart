import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../data/ai_scan_service.dart';
import '../data/mock_ai_scan.dart';

/// Repository bridge giữa API và UI.
/// Chịu trách nhiệm:
///   1. Gọi đúng API theo ngữ cảnh (tomato vs pest)
///   2. Map response → DiseaseResult (unified model)
///   3. Decode ảnh gốc để biết size thật → build BoundingBox chính xác
///      (ảnh gốc thường không vuông, bbox từ API tính theo pixel gốc)
class AiScanRepository {
  AiScanRepository({AiScanService? service})
      : _service = service ?? aiScanService;

  final AiScanService _service;

  /// ─── Thực hiện scan trên ảnh [imageFile].
  ///
  /// [plantType] — loại chẩn đoán:
  ///   - 'tomato' → NhanDangBenhLaCaChua (lá cà chua)
  ///   - 'pest'   → Argo_Pest (sâu bệnh cây trồng)
  ///
  /// Trả về ([DiseaseResult]? result, [String]? errorMessage):
  ///   - result != null → thành công
  ///   - errorMessage != null → thất bại (UI hiển thị message này)
  Future<({DiseaseResult? result, String? errorMessage})> scanImage(
    File imageFile, {
    required String plantType,
  }) async {
    debugPrint('[AiScanRepository] Scanning image for plantType: $plantType');

    // Decode ảnh 1 lần để lấy size thật — dùng cho BoundingBox scaling.
    final imageSize = await _decodeImageSize(imageFile);

    if (plantType == 'pest') {
      final aiRes = await _service.detectPest(imageFile);
      if (aiRes.isFailure) {
        return (result: null, errorMessage: aiRes.errorMessage);
      }
      if (aiRes.isSuccess) {
        return (
          result: _pestToResult(
            aiRes.value,
            imagePath: imageFile.path,
            imageWidth: imageSize.width,
            imageHeight: imageSize.height,
          ),
          errorMessage: null,
        );
      }
      return (result: null, errorMessage: 'Không thể phân tích ảnh.');
    }

    // default: tomato
    final aiRes = await _service.detectTomatoDisease(imageFile);
    if (aiRes.isFailure) {
      return (result: null, errorMessage: aiRes.errorMessage);
    }
    if (aiRes.isSuccess) {
      return (
        result: _tomatoToResult(
          aiRes.value,
          imagePath: imageFile.path,
          imageWidth: imageSize.width,
          imageHeight: imageSize.height,
        ),
        errorMessage: null,
      );
    }
    return (result: null, errorMessage: 'Không thể phân tích ảnh.');
  }

  /// Decode ảnh để lấy kích thước pixel thật. Trả (0, 0) nếu fail.
  Future<({int width, int height})> _decodeImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final w = img.width;
      final h = img.height;
      img.dispose();
      return (width: w, height: h);
    } catch (e) {
      debugPrint('[AiScanRepository] Decode image size failed: $e');
      // Fallback theo setting image_picker (maxWidth=1024, maxHeight=1024).
      return (width: 1024, height: 1024);
    }
  }

  /// Helper build `DetectionItem` từ `RawDetectionItem` + size ảnh gốc.
  DetectionItem _toDetectionItem(
    RawDetectionItem raw, {
    required int imageWidth,
    required int imageHeight,
  }) {
    BoundingBox? box;
    final rawBox = raw.rawBox;
    if (rawBox != null) {
      if (rawBox.list != null && rawBox.list!.length == 4) {
        box = BoundingBox.fromList(
          rawBox.list!,
          originalWidth: imageWidth,
          originalHeight: imageHeight,
        );
      } else if (rawBox.map != null) {
        box = BoundingBox.fromMap(
          rawBox.map!,
          originalWidth: imageWidth,
          originalHeight: imageHeight,
        );
      }
    }
    return DetectionItem(
      label: raw.label,
      confidence: raw.confidence,
      box: box,
      classId: raw.classId,
      detectorClassId: raw.detectorClassId,
      category: raw.category,
    );
  }

  // ─── Map Tomato response → DiseaseResult ───────────────────────────────────

  DiseaseResult _tomatoToResult(
    TomatoApiResponse r, {
    required String imagePath,
    required int imageWidth,
    required int imageHeight,
  }) {
    final confidence = (r.confidence * 100).round();

    // Treatments chỉ từ disease_info API trả về.
    // Không thêm fallback hardcoded — UI chỉ hiển thị đúng những gì API cung cấp.
    final treatments = <TreatmentItem>[];
    final info = r.diseaseInfo;
    if (info != null) {
      if (info.treatment.isNotEmpty) {
        treatments.add(TreatmentItem(
          id: 'api-treatment',
          title: 'Hướng xử lý',
          description: info.treatment,
          iconName: 'medication',
          hasChevron: true,
        ));
      }
      if (info.description.isNotEmpty) {
        treatments.add(TreatmentItem(
          id: 'api-description',
          title: 'Mô tả bệnh',
          description: info.description,
          iconName: 'info',
        ));
      }
    }

    // Tên hiển thị: ưu tiên label, fallback className; nếu rỗng → message server.
    final rawName = r.label.isNotEmpty
        ? r.label
        : (r.className.isNotEmpty ? r.className : '');
    final displayName = rawName.isNotEmpty
        ? _formatDiseaseName(rawName)
        : (r.message.isNotEmpty ? r.message : 'Không phát hiện bệnh');

    return DiseaseResult(
      diseaseName: displayName,
      diseaseSubtitle: rawName,
      severity: SeverityX.fromConfidence(r.confidence),
      confidencePercent: confidence,
      detectedAt: 'Vừa xong',
      scanImageUrl: imagePath,
      treatments: treatments,
      description: r.diseaseInfo?.description ?? r.message,
      plantType: 'tomato',
      // Map từ raw → DetectionItem chính thức (gắn BoundingBox scaled).
      detections: r.detections
          .map((raw) => _toDetectionItem(
                raw,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ))
          .toList(growable: false),
      probabilities: r.probabilities,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Format tên bệnh từ backend (snake_case / PascalCase) sang dạng dễ đọc.
  ///
  /// Ví dụ: "Tomato_Late_blight" → "Tomato Late Blight",
  ///        "Bacterial_Spot" → "Bacterial Spot".
  static String _formatDiseaseName(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }

  // ─── Map Pest response → DiseaseResult ─────────────────────────────────────

  DiseaseResult _pestToResult(
    PestApiResponse r, {
    required String imagePath,
    required int imageWidth,
    required int imageHeight,
  }) {
    final rawName = r.pestClass;
    final displayName = rawName.isNotEmpty
        ? _formatPestName(rawName)
        : 'Sâu bệnh';
    final gatePestPercent = (r.gatePestConfidence * 100).toStringAsFixed(1);
    return DiseaseResult(
      diseaseName: displayName,
      diseaseSubtitle: rawName,
      severity: SeverityX.fromConfidence(r.effectiveConfidence),
      confidencePercent: r.confidencePercent,
      detectedAt: 'Vừa xong',
      scanImageUrl: imagePath,
      // Pest API không trả disease_info/treatment → để list rỗng, UI sẽ không hiển thị.
      treatments: const <TreatmentItem>[],
      description: 'Phát hiện sâu bệnh ${rawName.isEmpty ? "trên cây trồng" : rawName} '
          '(gate pest: $gatePestPercent%).',
      plantType: 'pest',
      detections: r.detections
          .map((raw) => _toDetectionItem(
                raw,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ))
          .toList(growable: false),
      probabilities: r.probabilities,
      annotatedImageBytes: r.annotatedImageBytes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Format tên sâu bệnh: thay `_` → space và Title Case.
  ///
  /// Ví dụ: "Tomato_Hornworm" → "Tomato Hornworm".
  static String _formatPestName(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }
}
