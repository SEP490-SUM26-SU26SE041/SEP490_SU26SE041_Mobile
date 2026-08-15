import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'mock_ai_scan.dart' show DetectionCategory;

/// Raw bbox từ API — chưa biết kích thước ảnh gốc.
/// `BoundingBox` (trong mock_ai_scan.dart) yêu cầu `originalWidth/Height` để scale,
/// nên service layer giữ raw data; repository sẽ build `BoundingBox` khi có size.
///
/// Hai dạng backend trả:
///   - List<double>: `[x1, y1, x2, y2]`
///   - Map: `{"x1":..., "y1":..., "x2":..., "y2":...}`
class RawBoundingBox {
  const RawBoundingBox._({this.list, this.map});

  factory RawBoundingBox.fromJson(dynamic raw) {
    if (raw is List && raw.length == 4) {
      return RawBoundingBox._(list: List<dynamic>.from(raw));
    }
    if (raw is Map) {
      return RawBoundingBox._(map: Map<String, dynamic>.from(raw));
    }
    return const RawBoundingBox._();
  }

  final List<dynamic>? list;
  final Map<String, dynamic>? map;
}

/// ─── Raw API Response Models ────────────────────────────────────────────────

/// Response từ NhanDangBenhLaCaChua (Tomato) API.
///
/// Schema backend trả về (mới nhất 2026-08-13):
/// ```json
/// {
///   "gate": { "prediction": "...", "confidence": 0.0, "probabilities": {...}, "threshold": 0.6 },
///   "detections": [...],
///   "crop_predictions": [{
///     "rank": 1,
///     "box_xyxy": [...],
///     "detect_confidence": 0.0,
///     "prediction": "Tomato_Late_blight",
///     "confidence": 0.62
///   }],
///   "final_status": "tomato_leaf_classified" or "not_tomato_leaf" or "no_disease_detected",
///   "message": "...",
///   "best_disease_prediction": "Tomato_Late_blight",
///   "best_disease_confidence": 0.62
/// }
/// ```
class TomatoApiResponse {
  TomatoApiResponse({
    required this.className,
    required this.confidence,
    required this.label,
    required this.finalStatus,
    required this.message,
    this.diseaseInfo,
    this.detections = const <RawDetectionItem>[],
    this.probabilities = const <String, double>{},
  });

  /// Tên class (fallback sang `label` rỗng nếu API không trả).
  final String className;

  /// Độ tin cậy (0.0 → 1.0).
  final double confidence;

  /// Tên bệnh (label).
  final String label;

  /// Trạng thái cuối: "tomato_leaf_classified" / "not_tomato_leaf" / "no_disease_detected".
  final String finalStatus;

  /// Message từ server.
  final String message;

  /// Thông tin bệnh chi tiết (nếu backend trả về).
  final DiseaseInfoApi? diseaseInfo;

  /// Tất cả detections từ API (Tomato trả dạng `[{class_name, confidence, bbox}]`).
  /// Repository sẽ chuyển thành `DetectionItem` chính thức (gắn BoundingBox scaled).
  final List<RawDetectionItem> detections;

  /// Probabilities từng class — Tomato API trả khi `include_probabilities=true`.
  /// Key: class_name (snake_case). Value: probability (0.0 → 1.0).
  final Map<String, double> probabilities;

  factory TomatoApiResponse.fromJson(Map<String, dynamic> json) {
    // ─── 1. Ưu tiên top-level fields (best_disease_*) ─────────────────
    String detectedLabel = '';
    double detectedConf = 0.0;

    final bestLabel = json['best_disease_prediction'];
    final bestConf = json['best_disease_confidence'];
    if (bestLabel is String && bestLabel.isNotEmpty) {
      detectedLabel = bestLabel;
    }
    if (bestConf is num) {
      detectedConf = bestConf.toDouble();
    }

    // ─── 2. Fallback: crop_predictions[0].prediction / confidence ─────
    if (detectedLabel.isEmpty) {
      final cropPreds = json['crop_predictions'] as List<dynamic>?;
      if (cropPreds != null && cropPreds.isNotEmpty && cropPreds.first is Map) {
        final first = cropPreds.first as Map<String, dynamic>;
        detectedLabel = (first['prediction'] ??
                first['class_name'] ??
                first['class'] ??
                first['label'] ??
                '')
            .toString();
        detectedConf =
            (first['confidence'] ?? first['detect_confidence'] ?? 0.0)
                .toDouble();
      }
    }

    // ─── 3. Fallback: detections[0].class_name / detect_confidence ────
    if (detectedLabel.isEmpty) {
      final detections = json['detections'] as List<dynamic>?;
      if (detections != null && detections.isNotEmpty && detections.first is Map) {
        final first = detections.first as Map<String, dynamic>;
        detectedLabel = (first['class_name'] ??
                first['class'] ??
                first['label'] ??
                '')
            .toString();
        detectedConf =
            (first['detect_confidence'] ?? first['confidence'] ?? 0.0)
                .toDouble();
      }
    }

    // ─── 4. Fallback cuối: gate.confidence ─────────────────────────────
    if (detectedConf == 0) {
      final gate = json['gate'] as Map<String, dynamic>?;
      detectedConf = (gate?['confidence'] ?? 0.0).toDouble();
    }

    // ─── 5. Disease info (nếu backend trả kèm) ────────────────────────
    final diseaseInfoJson = json['disease_info'];
    DiseaseInfoApi? diseaseInfo;
    if (diseaseInfoJson is Map<String, dynamic>) {
      diseaseInfo = DiseaseInfoApi.fromJson(diseaseInfoJson);
    }

    // ─── 6. detections list (raw bbox — repository build sau) ──────────
    final detectionsList = <RawDetectionItem>[];
    final rawDetections = json['detections'] as List<dynamic>?;
    if (rawDetections != null) {
      for (final raw in rawDetections) {
        if (raw is! Map) continue;
        final m = raw as Map<String, dynamic>;
        detectionsList.add(_parseTomatoRawDetection(m));
      }
    }

    // ─── 7. probabilities map ─────────────────────────────────────────
    final probs = <String, double>{};
    final rawProbs = json['probabilities'];
    if (rawProbs is Map) {
      rawProbs.forEach((k, v) {
        if (v is num) probs[k.toString()] = v.toDouble();
      });
    }

    return TomatoApiResponse(
      className: detectedLabel,
      confidence: detectedConf,
      label: detectedLabel,
      finalStatus: (json['final_status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      diseaseInfo: diseaseInfo,
      detections: detectionsList,
      probabilities: probs,
    );
  }
}

/// Một detection thô từ API (Tomato hoặc Pest) — service chưa biết kích thước ảnh
/// gốc để build BoundingBox chính xác, nên giữ raw bbox + label.
/// Repository sẽ chuyển thành DetectionItem sau khi decode file.
class RawDetectionItem {
  const RawDetectionItem({
    required this.label,
    required this.confidence,
    this.rawBox,
    this.classId,
    this.detectorClassId,
    this.category = DetectionCategory.disease,
  });

  final String label;
  final double confidence;
  final RawBoundingBox? rawBox;
  final int? classId;
  final int? detectorClassId;
  final DetectionCategory category;
}

/// Helper parse 1 raw detection từ Tomato API.
RawDetectionItem _parseTomatoRawDetection(Map<String, dynamic> m) {
  final label = (m['class_name'] ?? m['class'] ?? m['label'] ?? m['prediction'] ?? '')
      .toString();

  final conf = ((m['confidence'] ?? m['detect_confidence'] ?? 0.0) as num).toDouble();

  RawBoundingBox? rawBox;
  final bboxRaw = m['bbox'];
  if (bboxRaw != null) {
    rawBox = RawBoundingBox.fromJson(bboxRaw);
  } else {
    final xyxy = m['box_xyxy'];
    if (xyxy != null) rawBox = RawBoundingBox.fromJson(xyxy);
  }

  // Tomato: detection có bbox trong crop_predictions là disease bbox.
  // Detection từ "gate" thường là "tomato_leaf" và không có bbox riêng.
  final category = label.toLowerCase().contains('tomato_leaf') ||
          label.toLowerCase().contains('gate')
      ? DetectionCategory.gate
      : DetectionCategory.disease;

  return RawDetectionItem(
    label: label,
    confidence: conf,
    rawBox: rawBox,
    category: category,
  );
}

class DiseaseInfoApi {
  DiseaseInfoApi({required this.description, required this.treatment});

  final String description;
  final String treatment;

  factory DiseaseInfoApi.fromJson(Map<String, dynamic> json) {
    return DiseaseInfoApi(
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
    );
  }
}

/// Response từ Argo_Pest API.
///
/// Schema backend trả về (mới nhất 2026-08-13):
/// ```json
/// {
///   "is_pest": true,
///   "gate_confidence": { "non_pest": 0.004, "pest": 0.996 },
///   "detections": [{
///     "class_id": 3,
///     "class_name": "Caterpillars",
///     "classification_confidence": 0.977,
///     "detection_confidence": 0.467,
///     "detector_class_id": 0,
///     "box": { "x1": 104, "y1": 5, "x2": 233, "y2": 199 }
///   }],
///   "annotated_image_base64": "..."
/// }
/// ```
class PestApiResponse {
  PestApiResponse({
    required this.pestClass,
    required this.classificationConfidence,
    required this.detectionConfidence,
    required this.isPest,
    required this.gateNonPestConfidence,
    required this.gatePestConfidence,
    this.detections = const <RawDetectionItem>[],
    this.annotatedImageBytes,
    this.probabilities = const <String, double>{},
  });

  /// Tên lớp sâu bệnh (ví dụ: "Caterpillars").
  final String pestClass;

  /// Độ tin cậy phân loại sâu bệnh (0.0 → 1.0) — lấy từ `classification_confidence`.
  final double classificationConfidence;

  /// Độ tin cậy detector (0.0 → 1.0) — lấy từ `detection_confidence`.
  final double detectionConfidence;

  /// Cờ server xác định ảnh có phải sâu bệnh không.
  final bool isPest;

  /// Gate confidence cho class "non_pest".
  final double gateNonPestConfidence;

  /// Gate confidence cho class "pest".
  final double gatePestConfidence;

  /// Tất cả detections (raw bbox) — mỗi detection có thể là pest khác nhau.
  final List<RawDetectionItem> detections;

  /// Annotated image bytes — Pest API trả về base64 → decode sẵn tại đây.
  /// Nếu có, Mobile có thể hiển thị thẳng ảnh đã vẽ bbox (server làm sẵn).
  final Uint8List? annotatedImageBytes;

  /// Probabilities từng class (nếu backend trả kèm).
  /// Key: tên class. Value: probability 0.0 → 1.0.
  final Map<String, double> probabilities;

  /// Confidence dùng để hiển thị — ưu tiên classification (cao hơn thường).
  double get effectiveConfidence =>
      classificationConfidence > 0 ? classificationConfidence : detectionConfidence;

  int get confidencePercent => (effectiveConfidence * 100).round();

  factory PestApiResponse.fromJson(Map<String, dynamic> json) {
    // ─── 1. detections[0] cho main class (ưu tiên) ───────────────────
    String detectedClass = '';
    double classConf = 0.0;
    double detectConf = 0.0;

    final rawDetections = json['detections'] as List<dynamic>?;
    final detections = <RawDetectionItem>[];
    if (rawDetections != null) {
      for (final raw in rawDetections) {
        if (raw is! Map) continue;
        final m = raw as Map<String, dynamic>;
        detections.add(_parsePestRawDetection(m));
      }

      if (detections.isNotEmpty) {
        final first = rawDetections.first as Map<String, dynamic>;
        detectedClass = (first['class_name'] ?? first['class'] ?? '')
            .toString();
        classConf = (first['classification_confidence'] ?? 0.0).toDouble();
        detectConf = (first['detection_confidence'] ?? 0.0).toDouble();
      }
    }

    // ─── 2. Fallback schema cũ: `class` + `confidence_*` top-level ─────
    if (detectedClass.isEmpty) {
      detectedClass = (json['class'] ?? '').toString();
    }
    final confKidney = (json['confidence_kidney'] ?? 0.0).toDouble();
    final confPercentile = (json['confidence_percentile'] ?? 0.0).toDouble();
    final confAbsolute = (json['confidence_absolute'] ?? 0.0).toDouble();
    classConf = classConf > 0 ? classConf : confKidney;
    detectConf = detectConf > 0 ? detectConf : confPercentile;
    if (classConf == 0) classConf = confAbsolute;

    // ─── 3. Gate confidence ─────────────────────────────────────────────
    final gate = json['gate_confidence'] as Map<String, dynamic>?;
    final gatePest = (gate?['pest'] ?? 0.0).toDouble();
    final gateNonPest = (gate?['non_pest'] ?? 0.0).toDouble();

    // ─── 4. Annotated image (base64 → bytes) ──────────────────────────
    Uint8List? annotatedBytes;
    final annotatedB64 = json['annotated_image_base64'];
    if (annotatedB64 is String && annotatedB64.isNotEmpty) {
      try {
        annotatedBytes = base64Decode(annotatedB64);
      } catch (e) {
        debugPrint('[PestApiResponse] Base64 decode failed: $e');
      }
    }

    // ─── 5. Probabilities (nếu backend trả kèm) ───────────────────────
    final probs = <String, double>{};
    final rawProbs = json['probabilities'];
    if (rawProbs is Map) {
      rawProbs.forEach((k, v) {
        if (v is num) probs[k.toString()] = v.toDouble();
      });
    }

    return PestApiResponse(
      pestClass: detectedClass,
      classificationConfidence: classConf,
      detectionConfidence: detectConf,
      isPest: json['is_pest'] == true,
      gatePestConfidence: gatePest,
      gateNonPestConfidence: gateNonPest,
      detections: detections,
      annotatedImageBytes: annotatedBytes,
      probabilities: probs,
    );
  }
}

/// Helper parse 1 raw detection Pest API.
RawDetectionItem _parsePestRawDetection(Map<String, dynamic> m) {
  final label = (m['class_name'] ?? m['class'] ?? '').toString();

  final conf = ((m['classification_confidence'] ??
          m['detection_confidence'] ??
          m['confidence'] ??
          0.0) as num)
      .toDouble();

  RawBoundingBox? rawBox;
  final boxRaw = m['box'] ?? m['bbox'];
  if (boxRaw != null) {
    rawBox = RawBoundingBox.fromJson(boxRaw);
  }

  final classId = (m['class_id'] is num) ? (m['class_id'] as num).toInt() : null;
  final detectorClassId =
      (m['detector_class_id'] is num) ? (m['detector_class_id'] as num).toInt() : null;

  // Pest: mọi detection có box đều là sâu bệnh (gate_pest đã filter trước khi trả detection).
  return RawDetectionItem(
    label: label,
    confidence: conf,
    rawBox: rawBox,
    classId: classId,
    detectorClassId: detectorClassId,
    category: DetectionCategory.disease,
  );
}

/// ─── API Service ────────────────────────────────────────────────────────────

class AiScanService {
  AiScanService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _tomatoBase = 'https://tomato-onnx-backend.onrender.com';
  static const String _pestBase = 'https://argo-pest-api.onrender.com';

  /// POST có retry 2 lần cho cold-start 502/503/504 của render.com.
  ///
  /// Cold-start: request đầu tiên render.com container wake-up thường trả 502/503.
  /// Retry 2 lần (cách nhau 2s) — nếu vẫn fail thì mới trả error.
  /// Tổng wait time: ~4s, chấp nhận được cho cold-start.
  Future<Response<dynamic>> _postWithRetry(
    String url, {
    required FormData data,
    required String tag,
  }) async {
    const retryable = {500, 502, 503, 504};
    const maxRetries = 2;
    final opts = Options(
      contentType: 'multipart/form-data',
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      // Tắt auto-transform response: khi 502 trả HTML, Dio throw DioException
      // với response.body rỗng — ta vẫn cần statusCode.
      receiveDataWhenStatusError: true,
      validateStatus: (status) => status != null && status < 500,
    );

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final res = await _dio.post(url, data: data, options: opts);
        // Nếu 502/503/504 → retry (Dio sẽ throw vì validateStatus=false).
        return res;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final isLast = attempt == maxRetries;
        if (status != null && retryable.contains(status) && !isLast) {
          debugPrint(
              '[$tag] Cold-start HTTP $status (attempt ${attempt + 1}/$maxRetries) — retry sau 2s...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        // Hết retry hoặc không phải retryable → ném lên caller với statusCode ensured.
        // Nếu e.response có statusCode → propagate; nếu không (connection error)
        // thì tạo DioException mới với response giả để caller nhận diện.
        if (status != null) {
          rethrow;
        }
        // Connection/DNS error không có response → rethrow.
        rethrow;
      }
    }
    // Không bao giờ vào đây (loop hoặc throw), nhưng Dart cần return.
    throw StateError('Unreachable: _postWithRetry');
  }

  /// Gọi Tomato API — phát hiện bệnh trên lá cà chua.
  ///
  /// [imageFile] — file ảnh từ device (sau khi chụp/chọn).
  /// Trả về `AiScanResult.failure` nếu lỗi, `AiScanResult.success(...)` nếu ok.
  /// KHÔNG throw — luôn trả về `AiScanResult` để UI xử lý được message thân thiện.
  Future<AiScanResult<TomatoApiResponse>> detectTomatoDisease(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _postWithRetry(
        '$_tomatoBase/predict',
        data: formData,
        tag: 'AiScanService.Tomato',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final parsed = TomatoApiResponse.fromJson(data);
        debugPrint(
            '[AiScanService] Tomato API success: label="${parsed.label}", '
            'confidence=${parsed.confidence}, status=${parsed.finalStatus}');
        // final_status = "tomato_leaf_classified" → có kết quả bệnh.
        // Các status khác ("not_tomato_leaf", "no_disease_detected", …) → failure.
        if (parsed.finalStatus != 'tomato_leaf_classified') {
          return AiScanResult.failure(
            parsed.message.isNotEmpty
                ? parsed.message
                : 'Ảnh không phải lá cà chua hoặc không phát hiện được bệnh.',
          );
        }
        return AiScanResult.success(parsed);
      }
      debugPrint('[AiScanService] Tomato API error: ${response.statusCode}');
      return AiScanResult.failure(
        'Server trả về lỗi HTTP ${response.statusCode}.',
      );
    } on DioException catch (e) {
      debugPrint('[AiScanService] Tomato API DioException: '
          'type=${e.type}, status=${e.response?.statusCode}, '
          'message=${e.message}, data=${e.response?.data}');
      // Phân loại lỗi để UI hiển thị message dễ hiểu.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AiScanResult.failure(
          'Server phản hồi chậm (timeout). Vui lòng thử lại sau ít phút (render.com cold-start).',
        );
      }
      final status = e.response?.statusCode;
      if (status == 500 || status == 502 || status == 503 || status == 504) {
        return AiScanResult.failure(
          'Server tạm thời không khả dụng (HTTP $status). Vui lòng thử lại sau ít phút.',
        );
      }
      return AiScanResult.failure(
        'Lỗi kết nối: ${e.type.name} (${e.message ?? "không rõ"})',
      );
    } catch (e, stack) {
      debugPrint('[AiScanService] Tomato API unexpected: $e\n$stack');
      return AiScanResult.failure('Lỗi không xác định: $e');
    }
  }

  /// Gọi Argo_Pest API — phát hiện sâu bệnh cây trồng.
  Future<AiScanResult<PestApiResponse>> detectPest(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _postWithRetry(
        '$_pestBase/predict',
        data: formData,
        tag: 'AiScanService.Pest',
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = PestApiResponse.fromJson(response.data);
        debugPrint(
            '[AiScanService] Pest API success: class="${parsed.pestClass}", '
            'classConf=${parsed.classificationConfidence}, '
            'isPest=${parsed.isPest}, '
            'gatePest=${parsed.gatePestConfidence}');
        // Nếu server xác nhận không phải sâu bệnh → failure với message thân thiện.
        if (!parsed.isPest || parsed.pestClass.isEmpty) {
          return AiScanResult.failure(
            'Không phát hiện sâu bệnh trong ảnh này.',
          );
        }
        return AiScanResult.success(parsed);
      }
      debugPrint('[AiScanService] Pest API error: ${response.statusCode}');
      return AiScanResult.failure(
        'Server trả về lỗi HTTP ${response.statusCode}.',
      );
    } on DioException catch (e) {
      debugPrint('[AiScanService] Pest API DioException: '
          'type=${e.type}, status=${e.response?.statusCode}, '
          'message=${e.message}, data=${e.response?.data}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AiScanResult.failure(
          'Server phản hồi chậm (timeout). Vui lòng thử lại sau.',
        );
      }
      final status = e.response?.statusCode;
      if (status == 500 || status == 502 || status == 503 || status == 504) {
        return AiScanResult.failure(
          'Server tạm thời không khả dụng (HTTP $status). Vui lòng thử lại sau ít phút.',
        );
      }
      return AiScanResult.failure(
        'Lỗi kết nối: ${e.type.name} (${e.message ?? "không rõ"})',
      );
    } catch (e, stack) {
      debugPrint('[AiScanService] Pest API unexpected: $e\n$stack');
      return AiScanResult.failure('Lỗi không xác định: $e');
    }
  }
}

/// Kết quả gọi API dạng `Result<T>` — phân biệt success vs failure mà KHÔNG throw.
class AiScanResult<T> {
  AiScanResult._(this.data, this.errorMessage);

  final T? data;
  final String? errorMessage;

  bool get isSuccess => data != null && errorMessage == null;
  bool get isFailure => errorMessage != null;

  /// Unwrap data — throw nếu failure (chỉ dùng khi caller đã check isSuccess).
  T get value {
    if (isFailure) {
      throw StateError('AiScanResult is failure: $errorMessage');
    }
    return data as T;
  }

  factory AiScanResult.success(T data) => AiScanResult._(data, null);
  factory AiScanResult.failure(String message) => AiScanResult._(null, message);
}

/// Singleton instance.
final aiScanService = AiScanService();
