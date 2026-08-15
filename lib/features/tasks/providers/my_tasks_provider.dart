library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../tasks/providers/task_providers.dart';

/// Unified task provider — dùng cho TaskHub (Student/Technician).
///
/// Trả về danh sách tasks đầy đủ để classify theo bucket (`today`/`upcoming`/
/// `overdue`/`completed`/`all`). Backend `/tasks/my` đôi khi filter sẵn theo
/// status mặc định (vd chỉ InProgress), nên ta **merge** kết quả từ 3 API
/// riêng biệt:
/// - `GET /tasks/today` → deadline = hôm nay
/// - `GET /tasks/upcoming?days=14` → deadline trong 14 ngày tới
/// - `GET /tasks/overdue` → đã quá hạn
///
/// Sau đó dedupe theo `task.id` rồi sort theo `dueDate` tăng dần.
final myTasksProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  final repo = ref.read(taskRepoProvider);

  // Gọi parallel 3 endpoint + myTasks để bắt mọi status filter mặc định.
  final results = await Future.wait([
    _safe(() => repo.getTodayTasks()),
    _safe(() => repo.getUpcomingTasks(days: 14)),
    _safe(() => repo.getOverdueTasks()),
    _safe(() => repo.getMyTasks()),
  ]);

  final seen = <String>{};
  final merged = <api.TaskModel>[];
  for (final list in results) {
    for (final t in list) {
      if (seen.add(t.id)) merged.add(t);
    }
  }

  // Lấy thêm các task đã hoàn thành từ `getMyTasks(status=['Completed'])`
  // để bucket "Hoàn thành" hiển thị đầy đủ.
  try {
    final completed = await repo.getMyTasks(status: const ['Completed', 'Approved', 'Submitted']);
    for (final t in completed) {
      if (seen.add(t.id)) merged.add(t);
    }
  } catch (_) {}

  // Loại bỏ cancelled (không còn liên quan).
  final active = merged
      .where((t) => t.status != api.TaskStatus.cancelled)
      .toList();
  // Sort theo dueDate tăng dần (sớm nhất trước) → overdue đầu, today giữa, upcoming cuối.
  active.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return active;
});

Future<List<api.TaskModel>> _safe(
    Future<List<api.TaskModel>> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    return <api.TaskModel>[];
  }
}

/// Today tasks — dùng cho widget embedded cần tối ưu payload.
final myTodayTasksProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getTodayTasks();
});

/// Overdue tasks — dùng để render badge/cảnh báo.
final myOverdueTasksProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getOverdueTasks();
});

/// Upcoming (7 ngày tới).
final myUpcomingTasksProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  return ref.read(taskRepoProvider).getUpcomingTasks(days: 7);
});
