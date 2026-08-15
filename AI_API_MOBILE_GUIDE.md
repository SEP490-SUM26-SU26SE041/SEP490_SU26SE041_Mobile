# Hướng Dẫn Fetch API Cho Mobile - AI Disease Detection

## Tổng Quan

Tài liệu này hướng dẫn cách gọi 2 API AI đã deploy để phát hiện bệnh trên cây trồng từ ứng dụng mobile (Flutter).

---

## 1. NhanDangBenhLaCaChua - Phát Hiện Bệnh Lá Cà Chua

### Thông Tin API

| Thông số | Giá trị |
|----------|---------|
| **Base URL** | `https://tomato-onnx-backend.onrender.com` |
| **Endpoint** | `POST /predict` |
| **Content-Type** | `multipart/form-data` |
| **OpenAPI** | 3.1.0 |

### Request Parameters (multipart/form-data)

| Parameter | Type | Required | Default | Mô tả |
|-----------|------|----------|---------|-------|
| `file` | binary | **Yes** | - | File ảnh (jpg, png, etc.) |
| `gate_threshold` | number | No | 0.6 | Ngưỡng gate để lọc predictions |
| `detect_conf` | number | No | 0.25 | Confidence threshold cho detection |
| `detect_iou` | number | No | 0.45 | IoU threshold cho NMS |
| `max_detections` | integer | No | 3 | Số lượng detection tối đa trả về |
| `include_probabilities` | boolean | No | false | Bao gồm probabilities trong response |

### Response Schema

```json
{
  "class_name": "string",          // Tên lớp bệnh (VD: "Tomato_Late_blight")
  "confidence": "number",          // Độ tin cậy (0.0 - 1.0)
  "label": "string",               // Nhãn mô tả bệnh (VD: "Bệnh muộn trên cà chua")
  "disease_info": {                // Thông tin chi tiết về bệnh (nếu có)
    "description": "string",       // Mô tả bệnh
    "treatment": "string"          // Phương pháp điều trị
  },
  "detections": [                  // Danh sách detections (nếu include_probabilities=true)
    {
      "class_name": "string",
      "confidence": "number",
      "bbox": [x1, y1, x2, y2]    // Bounding box
    }
  ],
  "probabilities": {}             // Dictionary probabilities của tất cả classes
}
```

### Code Flutter/Dart - Service Class

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TomatoDiseaseService {
  static const String _baseUrl = 'https://tomato-onnx-backend.onrender.com';

  /// Phát hiện bệnh trên lá cà chua từ ảnh
  /// 
  /// [imageFile] - File ảnh cần phân tích
  /// [gateThreshold] - Ngưỡng gate (default: 0.6)
  /// [detectConf] - Confidence threshold (default: 0.25)
  /// [detectIou] - IoU threshold (default: 0.45)
  /// [maxDetections] - Số detection tối đa (default: 3)
  /// [includeProbabilities] - Include all probabilities (default: false)
  static Future<TomatoDiseaseResult?> predictDisease(
    File imageFile, {
    double gateThreshold = 0.6,
    double detectConf = 0.25,
    double detectIou = 0.45,
    int maxDetections = 3,
    bool includeProbabilities = false,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      // Thêm file ảnh vào request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Thêm các parameters (tùy chọn - chỉ thêm nếu khác default)
      request.fields['gate_threshold'] = gateThreshold.toString();
      request.fields['detect_conf'] = detectConf.toString();
      request.fields['detect_iou'] = detectIou.toString();
      request.fields['max_detections'] = maxDetections.toString();
      request.fields['include_probabilities'] = includeProbabilities.toString();

      // Gửi request với timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TomatoDiseaseResult.fromJson(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Kiểm tra health của API
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Kết quả phát hiện bệnh lá cà chua
class TomatoDiseaseResult {
  final String className;           // Tên lớp bệnh
  final double confidence;         // Độ tin cậy (0.0 - 1.0)
  final String label;               // Nhãn mô tả
  final DiseaseInfo? diseaseInfo;    // Thông tin chi tiết về bệnh
  final List<Detection>? detections; // Danh sách detections
  final Map<String, double>? probabilities; // Probabilities của tất cả classes

  TomatoDiseaseResult({
    required this.className,
    required this.confidence,
    required this.label,
    this.diseaseInfo,
    this.detections,
    this.probabilities,
  });

  factory TomatoDiseaseResult.fromJson(Map<String, dynamic> json) {
    return TomatoDiseaseResult(
      className: json['class_name'] ?? '',
      confidence: _toDouble(json['confidence']),
      label: json['label'] ?? '',
      diseaseInfo: json['disease_info'] != null
          ? DiseaseInfo.fromJson(json['disease_info'])
          : null,
      detections: json['detections'] != null
          ? (json['detections'] as List)
              .map((d) => Detection.fromJson(d))
              .toList()
          : null,
      probabilities: json['probabilities'] != null
          ? Map<String, double>.from(
              (json['probabilities'] as Map).map(
                (k, v) => MapEntry(k.toString(), _toDouble(v)),
              ),
            )
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Lấy độ tin cậy dạng phần trăm
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Thông tin chi tiết về bệnh
class DiseaseInfo {
  final String description;  // Mô tả bệnh
  final String treatment;    // Phương pháp điều trị

  DiseaseInfo({required this.description, required this.treatment});

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
    );
  }
}

/// Detection object
class Detection {
  final String className;
  final double confidence;
  final List<double>? bbox; // [x1, y1, x2, y2]

  Detection({
    required this.className,
    required this.confidence,
    this.bbox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['class_name'] ?? '',
      confidence: TomatoDiseaseResult._toDouble(json['confidence']),
      bbox: json['bbox'] != null
          ? (json['bbox'] as List).map((e) => TomatoDiseaseResult._toDouble(e)).toList()
          : null,
    );
  }
}
```

### Ví Dụ Sử Dụng

```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Chọn ảnh từ camera
final picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.camera);

if (image != null) {
  final result = await TomatoDiseaseService.predictDisease(
    File(image.path),
    detectConf: 0.3,      // Tăng confidence threshold
    maxDetections: 5,     // Lấy 5 detections
  );
  
  if (result != null) {
    print('Bệnh: ${result.className}');
    print('Độ tin cậy: ${result.confidencePercent}');
    print('Nhãn: ${result.label}');
    
    if (result.diseaseInfo != null) {
      print('Mô tả: ${result.diseaseInfo!.description}');
      print('Điều trị: ${result.diseaseInfo!.treatment}');
    }
    
    // Xem tất cả probabilities
    if (result.probabilities != null) {
      result.probabilities!.forEach((className, prob) {
        print('$className: ${(prob * 100).toStringAsFixed(1)}%');
      });
    }
  }
}
```

---

## 2. Argo_Pest - Phát Hiện Sâu Bệnh Cây Trồng

### Thông Tin API

| Thông số | Giá trị |
|----------|---------|
| **Base URL** | `https://argo-pest-api.onrender.com` |
| **Endpoint** | `POST /predict` |
| **Content-Type** | `multipart/form-data` |
| **OpenAPI** | 3.1.0 |

### Request Parameters (multipart/form-data)

| Parameter | Type | Required | Default | Mô tả |
|-----------|------|----------|---------|-------|
| `file` | binary | **Yes** | - | File ảnh (jpg, png, etc.) |
| `conf` | number | No | 0.4 | Confidence threshold |
| `iou` | number | No | 0.45 | IoU threshold cho NMS |

### Response Schema

```json
{
  "class": "string",                    // Tên loại sâu bệnh
  "confidence_kidney": "number",         // Confidence dạng kidney (0.0 - 1.0)
  "confidence_percentile": "number",    // Confidence dạng percentile (0.0 - 1.0)
  "confidence_absolute": "number",      // Confidence tuyệt đối (0.0 - 1.0)
  "detections": [                        // Danh sách detections chi tiết (nếu có)
    {
      "class": "string",
      "confidence": "number",
      "bbox": [x1, y1, x2, y2]
    }
  ]
}
```

### Code Flutter/Dart - Service Class

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArgoPestService {
  static const String _baseUrl = 'https://argo-pest-api.onrender.com';

  /// Phát hiện sâu bệnh trên cây trồng từ ảnh
  /// 
  /// [imageFile] - File ảnh cần phân tích
  /// [conf] - Confidence threshold (default: 0.4)
  /// [iou] - IoU threshold (default: 0.45)
  static Future<PestResult?> predictPest(
    File imageFile, {
    double conf = 0.4,
    double iou = 0.45,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      // Thêm file ảnh vào request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Thêm parameters (tùy chọn)
      request.fields['conf'] = conf.toString();
      request.fields['iou'] = iou.toString();

      // Gửi request với timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PestResult.fromJson(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Kiểm tra health của API
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Kết quả phát hiện sâu bệnh
class PestResult {
  final String pestClass;                    // Tên loại sâu bệnh
  final double confidenceKidney;             // Confidence dạng kidney
  final double confidencePercentile;         // Confidence dạng percentile
  final double confidenceAbsolute;           // Confidence tuyệt đối
  final List<PestDetection>? detections;     // Danh sách detections chi tiết

  PestResult({
    required this.pestClass,
    required this.confidenceKidney,
    required this.confidencePercentile,
    required this.confidenceAbsolute,
    this.detections,
  });

  factory PestResult.fromJson(Map<String, dynamic> json) {
    return PestResult(
      pestClass: json['class'] ?? '',
      confidenceKidney: _toDouble(json['confidence_kidney']),
      confidencePercentile: _toDouble(json['confidence_percentile']),
      confidenceAbsolute: _toDouble(json['confidence_absolute']),
      detections: json['detections'] != null
          ? (json['detections'] as List)
              .map((d) => PestDetection.fromJson(d))
              .toList()
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Lấy độ tin cậy cao nhất trong 3 loại
  double get maxConfidence {
    return [confidenceKidney, confidencePercentile, confidenceAbsolute]
        .reduce((a, b) => a > b ? a : b);
  }

  /// Lấy độ tin cậy dạng phần trăm
  String get confidencePercent => '${(maxConfidence * 100).toStringAsFixed(1)}%';

  /// Lấy mô tả loại confidence cao nhất
  String get confidenceType {
    if (maxConfidence == confidenceKidney) return 'kidney';
    if (maxConfidence == confidencePercentile) return 'percentile';
    return 'absolute';
  }
}

/// Pest Detection object
class PestDetection {
  final String pestClass;
  final double confidence;
  final List<double>? bbox; // [x1, y1, x2, y2]

  PestDetection({
    required this.pestClass,
    required this.confidence,
    this.bbox,
  });

  factory PestDetection.fromJson(Map<String, dynamic> json) {
    return PestDetection(
      pestClass: json['class'] ?? '',
      confidence: PestResult._toDouble(json['confidence']),
      bbox: json['bbox'] != null
          ? (json['bbox'] as List).map((e) => PestResult._toDouble(e)).toList()
          : null,
    );
  }
}
```

### Ví Dụ Sử Dụng

```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Chọn ảnh từ gallery
final picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);

if (image != null) {
  final result = await ArgoPestService.predictPest(
    File(image.path),
    conf: 0.5,     // Tăng confidence threshold
  );
  
  if (result != null) {
    print('Loại sâu bệnh: ${result.pestClass}');
    print('Độ tin cậy cao nhất: ${result.confidencePercent}');
    print('Loại confidence: ${result.confidenceType}');
    print('Confidence Kidney: ${(result.confidenceKidney * 100).toStringAsFixed(1)}%');
    print('Confidence Percentile: ${(result.confidencePercentile * 100).toStringAsFixed(1)}%');
    print('Confidence Absolute: ${(result.confidenceAbsolute * 100).toStringAsFixed(1)}%');
    
    // Xem detections chi tiết
    if (result.detections != null) {
      for (var detection in result.detections!) {
        print('Detection: ${detection.pestClass} - ${(detection.confidence * 100).toStringAsFixed(1)}%');
      }
    }
  }
}
```

---

## 3. Ví Dụ Widget UI Hoàn Chỉnh (Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({Key? key}) : super(key: key);

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  TomatoDiseaseResult? _tomatoResult;
  PestResult? _pestResult;
  String _selectedApi = 'tomato'; // 'tomato' hoặc 'pest'

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _tomatoResult = null;
        _pestResult = null;
      });
    }
  }

  Future<void> _detectDisease() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedApi == 'tomato') {
        final result = await TomatoDiseaseService.predictDisease(_selectedImage!);
        setState(() => _tomatoResult = result);
      } else {
        final result = await ArgoPestService.predictPest(_selectedImage!);
        setState(() => _pestResult = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phát Hiện Bệnh Cây Trồng'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.api),
            onSelected: (value) {
              setState(() {
                _selectedApi = value;
                _tomatoResult = null;
                _pestResult = null;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tomato',
                child: Text('Bệnh Lá Cà Chua'),
              ),
              const PopupMenuItem(
                value: 'pest',
                child: Text('Sâu Bệnh Cây Trồng'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tomato', label: Text('Cà Chua')),
                ButtonSegment(value: 'pest', label: Text('Sâu Bệnh')),
              ],
              selected: {_selectedApi},
              onSelectionChanged: (value) {
                setState(() {
                  _selectedApi = value.first;
                  _tomatoResult = null;
                  _pestResult = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Hiển thị ảnh đã chọn
            if (_selectedImage != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Nút chọn ảnh
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp Ảnh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn Ảnh'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nút phát hiện bệnh
            ElevatedButton(
              onPressed: _selectedImage != null && !_isLoading
                  ? _detectDisease
                  : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Phát Hiện ${_selectedApi == 'tomato' ? 'Bệnh Cà Chua' : 'Sâu Bệnh'}'),
            ),
            
            const SizedBox(height: 24),
            
            // Hiển thị kết quả Tomato
            if (_tomatoResult != null) _buildTomatoResultCard(),
            
            // Hiển thị kết quả Pest
            if (_pestResult != null) _buildPestResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTomatoResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Kết Quả Bệnh Lá Cà Chua',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            _buildResultRow('Bệnh', _tomatoResult!.className),
            _buildResultRow('Độ tin cậy', _tomatoResult!.confidencePercent),
            _buildResultRow('Nhãn', _tomatoResult!.label),
            if (_tomatoResult!.diseaseInfo != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Mô tả bệnh'),
              Text(_tomatoResult!.diseaseInfo!.description),
              const SizedBox(height: 12),
              _buildSectionTitle('Phương pháp điều trị'),
              Text(_tomatoResult!.diseaseInfo!.treatment),
            ],
            if (_tomatoResult!.detections != null && 
                _tomatoResult!.detections!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Detections'),
              ..._tomatoResult!.detections!.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${d.className}: ${(d.confidence * 100).toStringAsFixed(1)}%'),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPestResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Kết Quả Sâu Bệnh',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            _buildResultRow('Loại sâu bệnh', _pestResult!.pestClass),
            _buildResultRow('Độ tin cậy cao nhất', _pestResult!.confidencePercent),
            const Divider(),
            const Text(
              'Chi tiết Confidence:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildResultRow('  Kidney', 
              '${(_pestResult!.confidenceKidney * 100).toStringAsFixed(1)}%'),
            _buildResultRow('  Percentile', 
              '${(_pestResult!.confidencePercentile * 100).toStringAsFixed(1)}%'),
            _buildResultRow('  Absolute', 
              '${(_pestResult!.confidenceAbsolute * 100).toStringAsFixed(1)}%'),
            if (_pestResult!.detections != null && 
                _pestResult!.detections!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Detections'),
              ..._pestResult!.detections!.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${d.pestClass}: ${(d.confidence * 100).toStringAsFixed(1)}%'),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
```

---

## 4. Dependencies Cần Thiết (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  image_picker: ^1.0.4
```

### Cài đặt

```bash
flutter pub get
```

### Cấu hình Android (android/app/src/main/AndroidManifest.xml)

```xml
<!-- Thêm quyền truy cập Internet và Camera -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### Cấu hình iOS (ios/Runner/Info.plist)

```xml
<!-- Thêm quyền truy cập Camera và Photo Library -->
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để chụp ảnh cây trồng</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền truy cập thư viện ảnh để chọn ảnh cây trồng</string>
```

---

## 5. Lưu Ý Quan Trọng

### Timeout Handling
Render.com có thời gian response chậm (đặc biệt khi cold start), nên đặt timeout đủ dài:

```dart
await request.send().timeout(
  const Duration(seconds: 120),  // 2 phút cho cold start
);
```

### Image Optimization
Resize ảnh trước khi gửi để giảm thời gian upload:

```dart
final XFile? image = await picker.pickImage(
  source: source,
  maxWidth: 1024,    // Resize width
  maxHeight: 1024,   // Resize height
  imageQuality: 85,  // JPEG quality
);
```

### Error Handling
Luôn xử lý các trường hợp lỗi:

```dart
try {
  final result = await service.predictDisease(imageFile);
  if (result != null) {
    // Xử lý kết quả
  } else {
    // API trả về null (lỗi nhưng không exception)
  }
} on SocketException {
  // Không có kết nối mạng
} on TimeoutException {
  // Request timeout
} catch (e) {
  // Các lỗi khác
}
```

### Health Check
Kiểm tra API health trước khi sử dụng:

```dart
final isHealthy = await TomatoDiseaseService.healthCheck();
if (!isHealthy) {
  // Show warning: "API đang bận hoặc không khả dụng"
}
```

---

## 6. API Response Examples (Chi Tiết)

### NhanDangBenhLaCaChua Response - Đầy Đủ

```json
{
  "class_name": "Tomato_Late_blight",
  "confidence": 0.9234,
  "label": "Bệnh muộn trên cà chua",
  "disease_info": {
    "description": "Bệnh muộn (Late blight) là bệnh nguy hiểm trên cây cà chua, do nấm Phytophthora infestans gây ra. Bệnh thường xuất hiện trong điều kiện thời tiết ẩm ướt, mát mẻ.",
    "treatment": "1. Loại bỏ và tiêu hủy các lá bị bệnh\n2. Phun thuốc trừ nấm đồng hoặc Mancozeb\n3. Đảm bảo thoát nước tốt\n4. Tránh tưới nước lên lá"
  },
  "detections": [
    {
      "class_name": "Tomato_Late_blight",
      "confidence": 0.9234,
      "bbox": [125, 80, 450, 320]
    },
    {
      "class_name": "Tomato_healthy",
      "confidence": 0.045,
      "bbox": [500, 100, 700, 350]
    }
  ],
  "probabilities": {
    "Tomato_healthy": 0.045,
    "Tomato_Late_blight": 0.9234,
    "Tomato_Early_blight": 0.015,
    "Tomato_Septoria_leaf_spot": 0.008,
    "Tomato_Spider_mites_Two_spotted_spider_mite": 0.005,
    "Tomato_Yellow_Curl_Virus": 0.002,
    "Tomato_mosaic_virus": 0.002
  }
}
```

### Argo_Pest Response - Đầy Đủ

```json
{
  "class": "Aphid",
  "confidence_kidney": 0.8723,
  "confidence_percentile": 0.8945,
  "confidence_absolute": 0.8567,
  "detections": [
    {
      "class": "Aphid",
      "confidence": 0.8945,
      "bbox": [50, 100, 200, 280]
    },
    {
      "class": "Aphid",
      "confidence": 0.756,
      "bbox": [300, 150, 450, 350]
    }
  ]
}
```

### Danh Sách Các Loại Bệnh/Sâu

#### Tomato Leaf Disease Classes:
- `Tomato_healthy` - Cây cà chua khỏe mạnh
- `Tomato_Late_blight` - Bệnh muộn
- `Tomato_Early_blight` - Bệnh sớm
- `Tomato_Septoria_leaf_spot` - Bệnh đốm lá Septoria
- `Tomato_Spider_mites_Two_spotted_spider_mite` - Nhện đỏ hai chấm
- `Tomato_Yellow_Curl_Virus` - Virus xoăn lá vàng
- `Tomato_mosaic_virus` - Virus khảm

#### Pest Classes (Ví dụ):
- `Aphid` - Rệp
- `Armyworm` - Sâu army
- `Beetle` - Bọ cánh cứng
- `Bollworm` - Sâu bông
- `Grasshopper` - Châu chấu
- `Mites` - Nhện
- `Mosquito` - Muỗi
- `Sawfly` - Ong cưa
- `Stem_borer` - Sâu thân
- `Thrips` - Bọ trĩ
- `Weevil` - Bọ gậy

---

## 7. So Sánh 2 API

| Feature | NhanDangBenhLaCaChua | Argo_Pest |
|---------|---------------------|-----------|
| **Base URL** | tomato-onnx-backend.onrender.com | argo-pest-api.onrender.com |
| **Mục đích** | Phát hiện bệnh lá cà chua | Phát hiện sâu bệnh cây trồng |
| **Model** | YOLOv8 ONNX | YOLOv8 |
| **Parameters** | gate_threshold, detect_conf, detect_iou, max_detections, include_probabilities | conf, iou |
| **Confidence types** | confidence | confidence_kidney, confidence_percentile, confidence_absolute |
| **Disease info** | Có (description, treatment) | Không |
| **Probabilities** | Có (tùy chọn) | Không |

---

## 8. Links

- **Swagger UI - NhanDangBenhLaCaChua**: https://tomato-onnx-backend.onrender.com/docs
- **Swagger UI - Argo_Pest**: https://argo-pest-api.onrender.com/docs
- **OpenAPI Spec - NhanDangBenhLaCaChua**: https://tomato-onnx-backend.onrender.com/openapi.json
- **OpenAPI Spec - Argo_Pest**: https://argo-pest-api.onrender.com/openapi.json

---

## 9. Backend SmartFarm Task Images — Lưu ý quan trọng

**Quy ước nhúng ảnh** (đã thấy qua logs ngày 2026-08-15):

- Backend trả `images: [...]` **inline trong từng report** khi gọi `GET /api/task-reports/task/{taskId}`.
- Endpoint `GET /api/task-images/report/{reportId}` trả **404 Not Found** → KHÔNG dùng endpoint này riêng lẻ.
- Khi cần ảnh của task → parse `report.images` từ response của `/task-reports/task/{taskId}`.

**Code pattern đang dùng**:
```dart
final reports = await _apiTaskReport.getReportsByTask(taskId);
for (final r in reports) {
  for (final img in r.images ?? const []) {
    // img.imageUrl (Cloudinary URL), img.taskReportId, img.id...
  }
}
```
