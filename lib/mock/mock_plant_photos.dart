import '../../shared/models/care_activity_model.dart';

class PlantPhotoModel {
  const PlantPhotoModel({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.imageUrl,
    this.imageType,
    this.caption,
  });

  final String id;
  final String batchId;
  final String batchName;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String imageUrl;
  final PlantImageType? imageType;
  final String? caption;
}

final mockPlantPhotos = [
  PlantPhotoModel(
    id: 'pp-001',
    batchId: 'batch-ctrl-01',
    batchName: 'Nhóm Đối Chứng (B01)',
    uploadedBy: 'usr-student-001',
    uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
    imageUrl: 'https://picsum.photos/seed/tomato01/400/300',
    imageType: PlantImageType.growth,
    caption: 'Cà chua bi tuần 4 - chiều cao 18.5cm',
  ),
  PlantPhotoModel(
    id: 'pp-002',
    batchId: 'batch-trt-01',
    batchName: 'Nhóm Thực Nghiệm (B02)',
    uploadedBy: 'usr-student-001',
    uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
    imageUrl: 'https://picsum.photos/seed/tomato02/400/300',
    imageType: PlantImageType.growth,
    caption: 'Cà chua bi tuần 4 - chiều cao 21.4cm',
  ),
  PlantPhotoModel(
    id: 'pp-003',
    batchId: 'batch-ctrl-01',
    batchName: 'Nhóm Đối Chứng (B01)',
    uploadedBy: 'usr-technician-001',
    uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
    imageUrl: 'https://picsum.photos/seed/leaf01/400/300',
    imageType: PlantImageType.general,
    caption: 'Lá cây bình thường, không sâu bệnh',
  ),
  PlantPhotoModel(
    id: 'pp-004',
    batchId: 'batch-trt-01',
    batchName: 'Nhóm Thực Nghiệm (B02)',
    uploadedBy: 'usr-technician-001',
    uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
    imageUrl: 'https://picsum.photos/seed/sensor01/400/300',
    imageType: PlantImageType.environment,
    caption: 'Kiểm tra cảm biến độ ẩm đất',
  ),
  PlantPhotoModel(
    id: 'pp-005',
    batchId: 'batch-ctrl-01',
    batchName: 'Nhóm Đối Chứng (B01)',
    uploadedBy: 'usr-student-002',
    uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    imageUrl: 'https://picsum.photos/seed/soil01/400/300',
    imageType: PlantImageType.general,
    caption: 'Đất ẩm, cấu trúc tốt',
  ),
];
