import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/care_activity_model.dart';

final careActivityRepositoryProvider = Provider<CareActivityRepository>((ref) {
  return CareActivityRepository();
});

class CareActivityRepository {
  Future<List<CareActivityModel>> getCareActivities() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCareActivities;
  }

  Future<void> submitCareActivity(CareActivityModel activity) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final careActivitiesProvider = FutureProvider<List<CareActivityModel>>((ref) async {
  return ref.read(careActivityRepositoryProvider).getCareActivities();
});

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  return ObservationRepository();
});

class ObservationRepository {
  Future<List<PlantObservationModel>> getObservations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockObservations;
  }

  Future<void> submitObservation(PlantObservationModel obs) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final observationsProvider = FutureProvider<List<PlantObservationModel>>((ref) async {
  return ref.read(observationRepositoryProvider).getObservations();
});

final _mockCareActivities = [
  CareActivityModel(
    id: 'ca-001',
    taskId: 'task-t001',
    batchId: 'batch-ctrl-01',
    performedBy: 'usr-technician-001',
    performedAt: DateTime.now().subtract(const Duration(days: 1)),
    waterAmount: 200,
    note: 'Đã tưới đều cho 30 gốc cây.',
  ),
  CareActivityModel(
    id: 'ca-002',
    taskId: 'task-t002',
    batchId: 'batch-trt-01',
    performedBy: 'usr-technician-001',
    performedAt: DateTime.now().subtract(const Duration(days: 2)),
    waterAmount: 150,
    fertilizerAmount: 5.0,
    note: 'Bón NPK 20-20-20, 5g/cây sau khi tưới.',
  ),
];

final _mockObservations = [
  PlantObservationModel(
    id: 'obs-001',
    taskId: 'task-s001',
    batchId: 'batch-ctrl-01',
    observedBy: 'usr-student-001',
    observedAt: DateTime.now().subtract(const Duration(days: 1)),
    observation: 'Cây phát triển tốt, chiều cao trung bình 18.5cm.',
    plantHealth: 'Khỏe mạnh',
  ),
  PlantObservationModel(
    id: 'obs-002',
    taskId: 'task-s002',
    batchId: 'batch-ctrl-01',
    observedBy: 'usr-student-001',
    observedAt: DateTime.now().subtract(const Duration(days: 3)),
    observation: 'Một số lá có dấu hiệu vàng nhẹ ở gốc.',
    plantHealth: 'Bình thường',
    pestSigns: 'Không phát hiện',
  ),
];
