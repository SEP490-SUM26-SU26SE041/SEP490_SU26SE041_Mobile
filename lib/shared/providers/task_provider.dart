import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/growth_task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

class TaskRepository {
  Future<List<TaskModel>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockTasks;
  }

  Future<List<TaskModel>> getTasksForTechnician(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockTasks.where((t) => t.assignedTo == userId).toList();
  }

  Future<List<TaskModel>> getTasksForStudent(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockTasks.where((t) => t.assignedTo == userId).toList();
  }

  Future<TaskModel?> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockTasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

final allTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return ref.read(taskRepositoryProvider).getTasks();
});

final technicianTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return ref.read(taskRepositoryProvider).getTasksForTechnician('usr-technician-001');
});

final studentTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return ref.read(taskRepositoryProvider).getTasksForStudent('usr-student-001');
});

final taskByIdProvider = FutureProvider.family<TaskModel?, String>((ref, id) async {
  return ref.read(taskRepositoryProvider).getTaskById(id);
});

final _mockTasks = [
  TaskModel(
    id: 'task-t001',
    taskName: 'Tưới nước - Nhóm Đối Chứng',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.pending,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now(),
    description: 'Tưới nhỏ giọt 200ml/gốc cây cho nhóm đối chứng trong giai đoạn tăng trưởng.',
  ),
  TaskModel(
    id: 'task-t002',
    taskName: 'Bón phân NPK - Nhóm Thực Nghiệm',
    taskType: TaskType.fertilizing,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-trt-01',
    status: TaskStatus.inProgress,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now(),
    description: 'Bón phân NPK 20-20-20, 5g/cây cho nhóm thực nghiệm.',
  ),
  TaskModel(
    id: 'task-t003',
    taskName: 'Kiểm tra độ ẩm đất',
    taskType: TaskType.inspection,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.pending,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now(),
  ),
  TaskModel(
    id: 'task-t004',
    taskName: 'Tưới nước - Khu thủy canh',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-002',
    batchId: 'batch-trt-01',
    status: TaskStatus.completed,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TaskModel(
    id: 'task-t005',
    taskName: 'Điều chỉnh độ ẩm đất',
    taskType: TaskType.inspection,
    experimentId: 'exp-001',
    stageId: 'stage-002',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.completed,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TaskModel(
    id: 'task-s001',
    taskName: 'Quan sát tăng trưởng Nhóm Đối Chứng - Tuần 4',
    taskType: TaskType.observation,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.inProgress,
    assignedTo: 'usr-student-001',
    dueDate: DateTime.now(),
    description: 'Theo dõi sự phát triển của cây trong nhóm đối chứng trong giai đoạn tăng trưởng.',
  ),
  TaskModel(
    id: 'task-s002',
    taskName: 'Ghi nhận chiều cao cây - Ngày 09/06',
    taskType: TaskType.observation,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.pending,
    assignedTo: 'usr-student-001',
    dueDate: DateTime.now(),
  ),
  TaskModel(
    id: 'task-s003',
    taskName: 'Kiểm tra tình trạng lá - Nhóm Thực Nghiệm',
    taskType: TaskType.inspection,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-trt-01',
    status: TaskStatus.completed,
    assignedTo: 'usr-student-001',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
