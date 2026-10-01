library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/dashboard_model.dart';
import '../../../core/api/models/task_model.dart' as task_model_api;
import '../../../core/api/services/dashboard_api_service.dart';
import '../../../core/api/services/task_api_service.dart';
import '../../../core/api/services/task_report_api_service.dart';
import '../../../shared/models/growth_task_model.dart' as internal;
import '../../tasks/providers/my_tasks_provider.dart';
import '../../tasks/providers/task_providers.dart';

/// Parallel fetch of (today, upcoming, overdue) tasks for current user.
/// Designed for Student/Technician dashboards — mirrors the JS FE
/// `Promise.allSettled` behavior: lỗi 1 API không chặn các ô KPI còn lại.
class TaskKpiBundle {
  const TaskKpiBundle({
    required this.today,
    required this.upcoming,
    required this.overdue,
    required this.errors,
  });

  final List<task_model_api.TaskModel> today;
  final List<task_model_api.TaskModel> upcoming;
  final List<task_model_api.TaskModel> overdue;
  final Map<String, String> errors;

  bool get hasAny =>
      today.isNotEmpty || upcoming.isNotEmpty || overdue.isNotEmpty;
}

class _TaskSlot {
  _TaskSlot.success(this.key, this.items) : failureMessage = null;
  _TaskSlot.failure(this.key, this.failureMessage)
      : items = const <task_model_api.TaskModel>[];

  final String key;
  final List<task_model_api.TaskModel> items;
  final String? failureMessage;

  String? get error => failureMessage;
}

final taskKpiBundleProvider =
    FutureProvider.autoDispose<TaskKpiBundle>((ref) async {
  final svc = ref.read(taskApiServiceProvider);
  final today = <task_model_api.TaskModel>[];
  final upcoming = <task_model_api.TaskModel>[];
  final overdue = <task_model_api.TaskModel>[];
  final errors = <String, String>{};

  Future<_TaskSlot> safe(
      Future<List<task_model_api.TaskModel>> Function() fn, String key) async {
    try {
      return _TaskSlot.success(key, await fn());
    } catch (e) {
      return _TaskSlot.failure(key, e.toString());
    }
  }

  final results = await Future.wait([
    safe(() => svc.getTodayTasks(), 'today'),
    safe(() => svc.getUpcomingTasks(days: 7), 'upcoming'),
    safe(() => svc.getOverdueTasks(), 'overdue'),
  ]);

  for (final r in results) {
    final err = r.error;
    if (err != null) {
      errors[r.key] = err;
    } else {
      switch (r.key) {
        case 'today':
          today.addAll(r.items);
          break;
        case 'upcoming':
          upcoming.addAll(r.items);
          break;
        case 'overdue':
          overdue.addAll(r.items);
          break;
      }
    }
  }

  return TaskKpiBundle(
    today: today,
    upcoming: upcoming,
    overdue: overdue,
    errors: errors,
  );
});

// ─── Overview Provider ────────────────────────────────────────────────

final dashboardOverviewProvider =
    FutureProvider.autoDispose<DashboardOverviewModel>((ref) async {
  try {
    final svc = ref.read(dashboardApiServiceProvider);
    return await svc.overview();
  } catch (_) {
    return DashboardOverviewModel.empty();
  }
});

final dashboardAlertsProvider =
    FutureProvider.autoDispose<List<DashboardAlertModel>>((ref) async {
  try {
    final svc = ref.read(dashboardApiServiceProvider);
    return await svc.alerts();
  } catch (_) {
    return const <DashboardAlertModel>[];
  }
});

final dashboardKpisProvider =
    FutureProvider.autoDispose<List<DashboardKpiModel>>((ref) async {
  try {
    final svc = ref.read(dashboardApiServiceProvider);
    return await svc.kpis();
  } catch (_) {
    return const <DashboardKpiModel>[];
  }
});

// ─── Recent Reports (images) cho "Báo cáo gần đây" ──────────────────────

/// Recent images cho widget `PlantPhotoGallery` trên dashboard.
///
/// Fallback chain (đảm bảo section "Báo cáo gần đây" không bao giờ rỗng
/// khi user đã có báo cáo):
///   1. `overview.recentImages` từ `/dashboard/overview` (BE trả về sẵn).
///   2. Nếu rỗng → quét `getMyTasks(status: Completed|Approved|Submitted)`
///      lấy các task đã hoàn thành gần nhất → gọi `/task-reports/task/{id}`
///      để lấy report kèm ảnh embed.
///   3. Gom ảnh, dedupe, sort theo `uploadedAt` desc → trả về tối đa 20.
///
/// Luôn trả về list (kể cả rỗng) để UI dùng `maybeWhen` ổn định.
final dashboardRecentImagesProvider =
    FutureProvider.autoDispose<List<TaskImageItem>>((ref) async {
  // 1. Thử lấy từ overview trước (cache cheap, 1 request).
  final overview = await ref.watch(dashboardOverviewProvider.future);
  if (overview.recentImages.isNotEmpty) {
    return overview.recentImages;
  }

  // 2. Fallback: quét task đã hoàn thành gần nhất.
  try {
    final repo = ref.read(taskRepoProvider);
    // Lấy nhiều status "đóng" để bao phủ cả approved/submitted.
    final completed = await repo.getMyTasks(
      status: const [
        'Completed',
        'Approved',
        'Submitted',
      ],
    );

    // Lấy tối đa 12 task mới nhất (theo updatedAt desc) để giảm tải.
    final recentTasks = [...completed]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final taskPool = recentTasks.take(12).toList();

    // 3. Gọi song song `/task-reports/task/{id}` để lấy report + ảnh embed.
    //    Pair kết quả với `t.id` (task ID) để map đúng vào `TaskImageItem.taskId`
    //    — trước đây lấy nhầm `r.id` (report ID) → `/task-reports/task/{reportId}`
    //    trả `[]` vì không tồn tại report nào theo report ID.
    final paired = await Future.wait(
      taskPool.map((t) async {
        try {
          final reports = await ref
              .read(taskReportApiServiceProvider)
              .getReportsByTask(t.id);
          return (taskId: t.id, taskTitle: t.title, reports: reports);
        } catch (_) {
          return (taskId: t.id, taskTitle: t.title, reports: <dynamic>[]);
        }
      }),
    );

    // 4. Gom ảnh từ tất cả reports → `TaskImageItem`.
    final items = <TaskImageItem>[];
    for (final entry in paired) {
      final taskIdForEntry = entry.taskId;
      final taskTitleForEntry = entry.taskTitle;
      for (final r in entry.reports) {
        final imgsRaw = (r as dynamic).images;
        final imgs = (imgsRaw is List)
            ? imgsRaw.whereType<dynamic>().toList()
            : const [];
        for (final img in imgs) {
          if (img == null) continue;
          final url = (img as dynamic).imageUrl as String? ?? '';
          if (url.isEmpty) continue;
          // Lấy `r.taskId` (taskId của report) — nếu BE trả về cùng task thì
          // vẫn dùng làm fallback. Nhưng **ưu tiên** taskId từ `taskPool` (entry)
          // vì chắc chắn đúng — `r.taskId` có thể null hoặc sai ở một số
          // response cũ.
          final rTaskId = (r as dynamic).taskId?.toString();
          final resolvedTaskId =
              (rTaskId != null && rTaskId.isNotEmpty) ? rTaskId : taskIdForEntry;
          items.add(TaskImageItem(
            id: (img as dynamic).id?.toString() ?? '',
            imageUrl: url,
            uploadedAt: (img as dynamic).createdAt as DateTime? ??
                DateTime.now(),
            caption: (img as dynamic).caption as String?,
            batchId: (img as dynamic).batchId as String?,
            batchCode: (img as dynamic).batchCode as String?,
            taskId: resolvedTaskId,
            taskTitle: (r as dynamic).taskTitle as String? ??
                taskTitleForEntry,
          ));
        }
      }
    }

    // 5. Dedupe theo imageUrl + sort desc theo uploadedAt.
    final seen = <String>{};
    final deduped = <TaskImageItem>[];
    for (final it in items) {
      if (seen.add(it.imageUrl)) deduped.add(it);
    }
    deduped.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return deduped.take(20).toList();
  } catch (_) {
    return const <TaskImageItem>[];
  }
});

// ─── Internal adapter (API TaskModel → internal TaskModel) ─────────────

final internalTaskListProvider =
    Provider.autoDispose<AsyncValue<List<internal.TaskModel>>>((ref) {
  return ref.watch(myTasksFlatProvider).when(
        data: (list) {
          return AsyncValue.data(list.map(_toInternal).toList());
        },
        loading: () => const AsyncValue<List<internal.TaskModel>>.loading(),
        error: (e, st) =>
            AsyncValue<List<internal.TaskModel>>.error(e, st),
      );
});

internal.TaskModel _toInternal(task_model_api.TaskModel a) {
  return internal.TaskModel(
    id: a.id,
    taskName: a.title,
    taskType: _toInternalType(a.taskType),
    experimentId: a.experimentId,
    stageId: a.experimentStageId,
    batchId: a.batchId,
    status: _toInternalStatus(a.status),
    assignedTo: a.assignedTo,
    dueDate: a.dueDate,
    description: a.description,
    experimentTitle: a.experimentTitle,
    experimentCode: a.experimentCode,
    experimentStageName: a.experimentStageName,
    batchCode: a.batchCode,
  );
}

internal.TaskType _toInternalType(task_model_api.TaskType t) {
  return switch (t) {
    task_model_api.TaskType.planting => internal.TaskType.planting,
    task_model_api.TaskType.watering => internal.TaskType.watering,
    task_model_api.TaskType.fertilizing => internal.TaskType.fertilizing,
    task_model_api.TaskType.observation => internal.TaskType.observation,
    task_model_api.TaskType.inspection => internal.TaskType.inspection,
    // harvest + measurement are not part of the legacy internal enum —
    // they collapse into existing categories for UI consumers that
    // haven't been updated to the new enum shape.
    task_model_api.TaskType.harvest => internal.TaskType.inspection,
    task_model_api.TaskType.measurement => internal.TaskType.observation,
    task_model_api.TaskType.other => internal.TaskType.other,
  };
}

internal.TaskStatus _toInternalStatus(task_model_api.TaskStatus s) {
  // Mọi status "đóng" (task đã kết thúc vòng đời dù thành công hay thất bại)
  // đều map về `completed` để:
  //   - Hiển thị trong bucket "Hoàn thành".
  //   - KHÔNG hiển thị badge "Quá hạn X ngày" dù dueDate đã trôi qua.
  return switch (s) {
    task_model_api.TaskStatus.pending => internal.TaskStatus.pending,
    task_model_api.TaskStatus.inProgress => internal.TaskStatus.inProgress,
    task_model_api.TaskStatus.completed ||
    task_model_api.TaskStatus.approved ||
    task_model_api.TaskStatus.submitted ||
    task_model_api.TaskStatus.rejected ||
    task_model_api.TaskStatus.cancelled ||
    task_model_api.TaskStatus.resigned ||
    task_model_api.TaskStatus.reassigned =>
      internal.TaskStatus.completed,
    task_model_api.TaskStatus.overdue => internal.TaskStatus.overdue,
  };
}
