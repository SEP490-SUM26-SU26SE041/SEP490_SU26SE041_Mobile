import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/growth_task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

class TaskRepository {
  Future<List<TaskModel>> getTasks() async {
    // TODO: Gọi API thật
    return [];
  }

  Future<List<TaskModel>> getTasksForTechnician(String userId) async {
    // TODO: Gọi API thật
    return [];
  }

  Future<List<TaskModel>> getTasksForStudent(String userId) async {
    // TODO: Gọi API thật
    return [];
  }

  Future<TaskModel?> getTaskById(String id) async {
    // TODO: Gọi API thật
    return null;
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
