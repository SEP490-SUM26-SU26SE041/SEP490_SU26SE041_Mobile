class CareActivityModel {
  const CareActivityModel({
    required this.id,
    required this.taskId,
    required this.batchId,
    required this.performedBy,
    required this.performedAt,
    this.waterAmount,
    this.fertilizerAmount,
    this.soilMoisture,
    this.temperature,
    this.note,
    this.imageUrls,
  });

  final String id;
  final String taskId;
  final String batchId;
  final String performedBy;
  final DateTime performedAt;
  final double? waterAmount;
  final double? fertilizerAmount;
  final double? soilMoisture;
  final double? temperature;
  final String? note;
  final List<String>? imageUrls;
}

class PlantObservationModel {
  const PlantObservationModel({
    required this.id,
    required this.taskId,
    required this.batchId,
    required this.observedBy,
    required this.observedAt,
    required this.observation,
    this.plantHealth,
    this.pestSigns,
    this.diseaseSigns,
    this.note,
    this.imageUrls,
  });

  final String id;
  final String taskId;
  final String batchId;
  final String observedBy;
  final DateTime observedAt;
  final String observation;
  final String? plantHealth;
  final String? pestSigns;
  final String? diseaseSigns;
  final String? note;
  final List<String>? imageUrls;
}

class PlantImageModel {
  const PlantImageModel({
    required this.id,
    required this.batchId,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.imageUrl,
    this.imageType,
    this.aiAnalysis,
    this.note,
  });

  final String id;
  final String batchId;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String imageUrl;
  final PlantImageType? imageType;
  final AIAnalysisResult? aiAnalysis;
  final String? note;
}

enum LeafColor { xanhDam, xanh, vangNhat, xanhBong, khac }

enum PlantHealth { khoeManh, binhThuong, yeu, ratTot }

enum PlantImageType { growth, pest, disease, environment, general }

class PlantEnums {
  PlantEnums._();

  static const List<String> leafColors = ['Xanh đậm', 'Xanh', 'Vàng nhạt', 'Xanh bóng', 'Khác'];
  static const List<String> healthStatuses = ['Khỏe mạnh', 'Bình thường', 'Yếu', 'Rất tốt'];
  static const List<String> pestOptions = ['Không phát hiện', 'Có dấu hiệu sâu ăn lá', 'Có dấu hiệu rệp', 'Khác'];
}

class AIAnalysisResult {
  const AIAnalysisResult({
    required this.analyzedAt,
    this.healthStatus,
    this.pestDetected,
    this.diseaseDetected,
    this.confidence,
    this.recommendations,
  });

  final DateTime analyzedAt;
  final String? healthStatus;
  final String? pestDetected;
  final String? diseaseDetected;
  final double? confidence;
  final List<String>? recommendations;
}
