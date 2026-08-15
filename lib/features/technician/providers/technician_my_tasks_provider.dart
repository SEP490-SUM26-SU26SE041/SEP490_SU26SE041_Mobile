library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../tasks/providers/my_tasks_provider.dart';
import '../../tasks/providers/task_providers.dart';

/// Provider riêng cho Technician — wrapper quanh các bucket API dùng chung
/// trong `tasks/features/my_tasks_provider.dart`.
///
/// Mục đích:
/// - Tách biệt về mặt kiến trúc: Technician screen chỉ depend vào đây, không
///   trực tiếp depend vào Student-shared providers.
/// - Về data flow, cả 2 đều gọi cùng endpoint `/tasks/{today,upcoming,overdue,my}`
///   (backend filter theo current user, không phải role-specific), nên kết quả
///   cho Technician giống hệt với khi dùng Student-shared providers.
///
/// Nếu sau này Technician cần logic khác (VD: chỉ task Inspection/Maintenance,
/// sort ưu tiên theo location, ...), chỉ cần đổi implementation trong file
/// này mà không động đến Student.

/// `GET /tasks/today` — tasks đến hạn hôm nay của current user.
final technicianTodayTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getTodayTasks();
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// `GET /tasks/upcoming?days=14` — tasks sắp tới.
final technicianUpcomingTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getUpcomingTasks(days: 14);
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// `GET /tasks/overdue` — tasks quá hạn.
final technicianOverdueTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getOverdueTasks();
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// `GET /tasks/my?status=Completed|Approved|Submitted` — tasks đã hoàn thành.
final technicianCompletedTasksApiProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  try {
    return await ref.read(taskRepoProvider).getMyTasks(
          status: const ['Completed', 'Approved', 'Submitted'],
        );
  } catch (_) {
    return <api.TaskModel>[];
  }
});

/// Unified bucket set cho Technician — dùng cho TaskHub / dashboard KPI.
class TechnicianTaskBucketSet {
  const TechnicianTaskBucketSet({
    required this.today,
    required this.upcoming,
    required this.overdue,
    required this.completed,
  });

  final List<api.TaskModel> today;
  final List<api.TaskModel> upcoming;
  final List<api.TaskModel> overdue;
  final List<api.TaskModel> completed;

  static const empty = TechnicianTaskBucketSet(
    today: [],
    upcoming: [],
    overdue: [],
    completed: [],
  );
}

/// Bucket enum riêng cho Technician — mirror với Student-shared
/// `TaskFilterBucket` trong `tasks/features/my_tasks_provider.dart`.
enum TechnicianTaskBucket {
  today,
  upcoming,
  overdue,
  completed,
  all,
}

/// Provider gộp 4 bucket cho Technician — song song 4 endpoint.
final technicianMyTasksProvider =
    FutureProvider.autoDispose<TechnicianTaskBucketSet>((ref) async {
  // Gọi parallel 4 endpoint → mỗi bucket khớp 1-1 với API.
  final results = await Future.wait([
    ref.watch(technicianTodayTasksApiProvider.future),
    ref.watch(technicianUpcomingTasksApiProvider.future),
    ref.watch(technicianOverdueTasksApiProvider.future),
    ref.watch(technicianCompletedTasksApiProvider.future),
  ]);

  return TechnicianTaskBucketSet(
    today: results[0]
        .where((t) => t.status != api.TaskStatus.cancelled)
        .toList(),
    upcoming: results[1]
        .where((t) => t.status != api.TaskStatus.cancelled)
        .toList(),
    overdue: results[2]
        .where((t) => t.status != api.TaskStatus.cancelled)
        .toList(),
    completed: results[3]
        .where((t) => t.status != api.TaskStatus.cancelled)
        .toList(),
  );
});

/// Adapter: chuyển `TechnicianTaskBucketSet` → `TaskBucketSet` (shared) để
/// có thể dùng `TaskHub` widget (shared widget chỉ accept TaskBucketSet).
///
/// Lưu ý: việc Student và Technician cùng dùng `TaskHub` là intentional —
/// widget là shared. Data flow vẫn đi qua provider riêng của từng role.
final technicianBucketAsSharedProvider =
    Provider.autoDispose<AsyncValue<TaskBucketSet>>((ref) {
  final async = ref.watch(technicianMyTasksProvider);
  return async.whenData(
    (b) => TaskBucketSet(
      today: b.today,
      upcoming: b.upcoming,
      overdue: b.overdue,
      completed: b.completed,
    ),
  );
});

/// Flatten all 4 buckets thành 1 list (cho các nơi cần tất cả task).
/// Sort theo dueDate tăng dần.
final technicianMyTasksFlatProvider =
    FutureProvider.autoDispose<List<api.TaskModel>>((ref) async {
  final set = await ref.watch(technicianMyTasksProvider.future);
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
