library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../tasks/providers/task_providers.dart';

/// `GET /tasks/today` — đúng những gì backend trả về.
final todayTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getTodayTasks();
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// `GET /tasks/upcoming?days=14` — đúng những gì backend trả về.
final upcomingTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getUpcomingTasks(days: 14);
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// `GET /tasks/overdue` — đúng những gì backend trả về.
final overdueTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getOverdueTasks();
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// `GET /tasks/my?status=Completed|Approved|Submitted` — đúng những gì backend trả về.
final completedTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getMyTasks(
          status: const ['Completed', 'Approved', 'Submitted'],
        );
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// Unified task provider — dùng cho TaskHub (Student/Technician).
///
/// Mỗi bucket lấy trực tiếp từ endpoint tương ứng để hiển thị đúng những gì
/// API trả về (không classify lại client-side, tránh sai lệch với backend):
/// - `todayTasksApiProvider` → `/tasks/today`
/// - `upcomingTasksApiProvider` → `/tasks/upcoming?days=14`
/// - `overdueTasksApiProvider` → `/tasks/overdue`
/// - `completedTasksApiProvider` → `/tasks/my?status=Completed|Approved|Submitted`
///
/// Trả về `TaskBucketSet` chứa 4 list riêng biệt cho từng filter chip.
class TaskBucketSet {
  const TaskBucketSet({
    required this.today,
    required this.upcoming,
    required this.overdue,
    required this.completed,
  });

  final List<api.TaskModel> today;
  final List<api.TaskModel> upcoming;
  final List<api.TaskModel> overdue;
  final List<api.TaskModel> completed;

  static const empty = TaskBucketSet(
    today: [],
    upcoming: [],
    overdue: [],
    completed: [],
  );
}

final myTasksProvider =
    FutureProvider.autoDispose<TaskBucketSet>((ref) async {
  // Gọi parallel 4 endpoint để mỗi bucket khớp 1-1 với API.
  final results = await Future.wait([
    ref.watch(todayTasksApiProvider.future),
    ref.watch(upcomingTasksApiProvider.future),
    ref.watch(overdueTasksApiProvider.future),
    ref.watch(completedTasksApiProvider.future),
  ]);

  return TaskBucketSet(
    today: results[0].where((t) => t.status != api.TaskStatus.cancelled).toList(),
    upcoming:
        results[1].where((t) => t.status != api.TaskStatus.cancelled).toList(),
    overdue:
        results[2].where((t) => t.status != api.TaskStatus.cancelled).toList(),
    completed: results[3]
        .where((t) => t.status != api.TaskStatus.cancelled)
        .toList(),
  );
});

/// Flatten all 4 buckets thành 1 list (cho các nơi cần tất cả task,
/// ví dụ dashboard summary). Sort theo dueDate tăng dần.
final myTasksFlatProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  final set = await ref.watch(myTasksProvider.future);
  final seen = <String>{};
  final merged = <api.TaskModel>[];
  for (final t in [
    ...set.overdue,
    ...set.today,
    ...set.upcoming,
    ...set.completed,
  ]) {
    if (seen.add(t.id)) merged.add(t);
  }
  merged.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return merged;
});
