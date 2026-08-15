library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/dashboard_model.dart';
import '../../../core/api/models/task_model.dart' as tApi;
import '../../../core/api/services/dashboard_api_service.dart';
import '../../../core/api/services/task_api_service.dart';
import '../../../shared/models/growth_task_model.dart' as internal;
import '../../tasks/providers/my_tasks_provider.dart';

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

  final List<tApi.TaskModel> today;
  final List<tApi.TaskModel> upcoming;
  final List<tApi.TaskModel> overdue;
  final Map<String, String> errors;

  bool get hasAny =>
      today.isNotEmpty || upcoming.isNotEmpty || overdue.isNotEmpty;
}

class _TaskSlot {
  _TaskSlot.success(this.key, this.items) : failureMessage = null;
  _TaskSlot.failure(this.key, this.failureMessage)
      : items = const <tApi.TaskModel>[];

  final String key;
  final List<tApi.TaskModel> items;
  final String? failureMessage;

  String? get error => failureMessage;
}

final taskKpiBundleProvider =
    FutureProvider.autoDispose<TaskKpiBundle>((ref) async {
  final svc = ref.read(taskApiServiceProvider);
  final today = <tApi.TaskModel>[];
  final upcoming = <tApi.TaskModel>[];
  final overdue = <tApi.TaskModel>[];
  final errors = <String, String>{};

  Future<_TaskSlot> safe(
      Future<List<tApi.TaskModel>> Function() fn, String key) async {
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

internal.TaskModel _toInternal(tApi.TaskModel a) {
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

internal.TaskType _toInternalType(tApi.TaskType t) {
  return switch (t) {
    tApi.TaskType.planting => internal.TaskType.planting,
    tApi.TaskType.watering => internal.TaskType.watering,
    tApi.TaskType.fertilizing => internal.TaskType.fertilizing,
    tApi.TaskType.observation => internal.TaskType.observation,
    tApi.TaskType.inspection => internal.TaskType.inspection,
    // harvest + measurement are not part of the legacy internal enum —
    // they collapse into existing categories for UI consumers that
    // haven't been updated to the new enum shape.
    tApi.TaskType.harvest => internal.TaskType.inspection,
    tApi.TaskType.measurement => internal.TaskType.observation,
    tApi.TaskType.other => internal.TaskType.other,
  };
}

internal.TaskStatus _toInternalStatus(tApi.TaskStatus s) {
  return switch (s) {
    tApi.TaskStatus.pending => internal.TaskStatus.pending,
    tApi.TaskStatus.inProgress => internal.TaskStatus.inProgress,
    tApi.TaskStatus.completed => internal.TaskStatus.completed,
    tApi.TaskStatus.approved => internal.TaskStatus.completed,
    tApi.TaskStatus.submitted => internal.TaskStatus.completed,
    tApi.TaskStatus.rejected => internal.TaskStatus.overdue,
    tApi.TaskStatus.cancelled => internal.TaskStatus.overdue,
    tApi.TaskStatus.resigned => internal.TaskStatus.overdue,
    tApi.TaskStatus.reassigned => internal.TaskStatus.overdue,
    tApi.TaskStatus.overdue => internal.TaskStatus.overdue,
  };
}
