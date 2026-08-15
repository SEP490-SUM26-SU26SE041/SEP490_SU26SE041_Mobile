library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/utils/date_utils.dart';

/// Visual definition cho từng loại task — chuẩn hóa cho cả app.
class TaskVisualSpec {
  const TaskVisualSpec({
    required this.icon,
    required this.label,
    required this.color,
    required this.accentBg,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color accentBg;
}

api.TaskType detectTaskType(String raw) => api.TaskType.fromString(raw);

/// Tra cứu icon + màu theo `TaskType` để hiển thị thống nhất.
TaskVisualSpec getTaskVisualSpec(api.TaskType type) {
  switch (type) {
    case api.TaskType.planting:
      return const TaskVisualSpec(
        icon: Icons.eco_rounded,
        label: 'Trồng cây',
        color: Color(0xFF2E7D32),
        accentBg: Color(0xFFD7ECDC),
      );
    case api.TaskType.watering:
      return const TaskVisualSpec(
        icon: Icons.water_drop_rounded,
        label: 'Tưới nước',
        color: Color(0xFF0288D1),
        accentBg: Color(0xFFD5ECF8),
      );
    case api.TaskType.fertilizing:
      return const TaskVisualSpec(
        icon: Icons.science_rounded,
        label: 'Bón phân',
        color: Color(0xFFF57C00),
        accentBg: Color(0xFFFCE8D2),
      );
    case api.TaskType.observation:
      return const TaskVisualSpec(
        icon: Icons.visibility_rounded,
        label: 'Quan sát',
        color: Color(0xFF6A1B9A),
        accentBg: Color(0xFFE9D9F1),
      );
    case api.TaskType.inspection:
      return const TaskVisualSpec(
        icon: Icons.search_rounded,
        label: 'Kiểm tra',
        color: Color(0xFF00838F),
        accentBg: Color(0xFFD2EDF1),
      );
    case api.TaskType.measurement:
      return const TaskVisualSpec(
        icon: Icons.straighten_rounded,
        label: 'Đo lường',
        color: Color(0xFF1565C0),
        accentBg: Color(0xFFD7E5F7),
      );
    case api.TaskType.harvest:
      return const TaskVisualSpec(
        icon: Icons.agriculture_rounded,
        label: 'Thu hoạch',
        color: Color(0xFFE65100),
        accentBg: Color(0xFFF7E1CB),
      );
    case api.TaskType.other:
      return const TaskVisualSpec(
        icon: Icons.more_horiz_rounded,
        label: 'Khác',
        color: AppColors.textSecondaryLight,
        accentBg: Color(0xFFEDEDED),
      );
  }
}

/// Status pill spec — đồng bộ cho cả list & detail.
class TaskStatusPillSpec {
  const TaskStatusPillSpec({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
}

TaskStatusPillSpec getStatusPillSpec(api.TaskStatus status) {
  switch (status) {
    case api.TaskStatus.pending:
      return const TaskStatusPillSpec(
        label: 'Chờ xử lý',
        color: Color(0xFF1565C0),
        bg: Color(0xFFD7E5F7),
        icon: Icons.schedule_rounded,
      );
    case api.TaskStatus.inProgress:
      return const TaskStatusPillSpec(
        label: 'Đang làm',
        color: Color(0xFFEF6C00),
        bg: Color(0xFFFCE8D2),
        icon: Icons.trending_up_rounded,
      );
    case api.TaskStatus.completed:
    case api.TaskStatus.approved:
    case api.TaskStatus.submitted:
      return const TaskStatusPillSpec(
        label: 'Hoàn thành',
        color: Color(0xFF2E7D32),
        bg: Color(0xFFD7ECDC),
        icon: Icons.check_circle_rounded,
      );
    case api.TaskStatus.cancelled:
    case api.TaskStatus.rejected:
    case api.TaskStatus.resigned:
    case api.TaskStatus.reassigned:
      return const TaskStatusPillSpec(
        label: 'Đã hủy',
        color: Color(0xFFB71C1C),
        bg: Color(0xFFF8D7D7),
        icon: Icons.cancel_rounded,
      );
    case api.TaskStatus.overdue:
      return const TaskStatusPillSpec(
        label: 'Quá hạn',
        color: Color(0xFFB71C1C),
        bg: Color(0xFFF8D7D7),
        icon: Icons.warning_rounded,
      );
  }
}

/// Tính khoảng cách deadline so với hiện tại (theo UTC+7), trả về (label, màu).
class DeadlineChipData {
  const DeadlineChipData({
    required this.label,
    required this.color,
    required this.isOverdue,
  });
  final String label;
  final Color color;
  final bool isOverdue;
}

DeadlineChipData? computeDeadlineChip(
  DateTime? dueDate,
  api.TaskStatus status,
) {
  if (dueDate == null) return null;
  if (status == api.TaskStatus.completed ||
      status == api.TaskStatus.approved ||
      status == api.TaskStatus.submitted) {
    return null;
  }
  final today = todayInVN();
  final dueVN = dateOnlyInVN(dueDate);
  final diff = dueVN.difference(today).inDays;
  if (diff < 0) {
    final days = diff.abs();
    return DeadlineChipData(
      label: days == 0 ? 'Quá hạn hôm nay' : 'Quá hạn $days ngày',
      color: const Color(0xFFB71C1C),
      isOverdue: true,
    );
  }
  if (diff == 0) {
    return DeadlineChipData(
      label: 'Hết hạn hôm nay ${formatTime(dueDate)}',
      color: const Color(0xFFEF6C00),
      isOverdue: false,
    );
  }
  if (diff == 1) {
    return DeadlineChipData(
      label: 'Ngày mai ${formatTime(dueDate)}',
      color: const Color(0xFF1565C0),
      isOverdue: false,
    );
  }
  if (diff <= 7) {
    return DeadlineChipData(
      label: 'Còn $diff ngày',
      color: const Color(0xFF455A64),
      isOverdue: false,
    );
  }
  return DeadlineChipData(
    label: intl.DateFormat('dd/MM').format(_toVN(dueDate)),
    color: const Color(0xFF607D8B),
    isOverdue: false,
  );
}

DateTime _toVN(DateTime dt) {
  final utc = dt.isUtc ? dt : dt.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
  ).add(const Duration(hours: 7));
}

/// Tính % tiến độ theo ngày giữa createdDate và dueDate.
double computeDueProgress({
  required DateTime dueDate,
  DateTime? createdDate,
}) {
  final now = DateTime.now();
  if (now.isAfter(dueDate)) return 1;
  final created = createdDate ?? now.subtract(const Duration(days: 3));
  final total = dueDate.difference(created).inHours;
  if (total <= 0) return 0;
  final elapsed = now.difference(created).inHours;
  final p = elapsed / total;
  return p.clamp(0.0, 1.0);
}

/// 4 bucket filter chính — chuẩn cho cả Student & Technician.
enum TaskFilterBucket { today, upcoming, overdue, completed, all }

extension TaskFilterCopy on TaskFilterBucket {
  String get label => switch (this) {
        TaskFilterBucket.today => 'Hôm nay',
        TaskFilterBucket.upcoming => 'Sắp tới',
        TaskFilterBucket.overdue => 'Quá hạn',
        TaskFilterBucket.completed => 'Hoàn thành',
        TaskFilterBucket.all => 'Tất cả',
      };

  IconData get icon => switch (this) {
        TaskFilterBucket.today => Icons.today_rounded,
        TaskFilterBucket.upcoming => Icons.upcoming_rounded,
        TaskFilterBucket.overdue => Icons.error_outline_rounded,
        TaskFilterBucket.completed => Icons.check_circle_outline_rounded,
        TaskFilterBucket.all => Icons.list_alt_rounded,
      };
}

/// Helper classify 1 task theo bucket để đỡ lặp code.
TaskFilterBucket classifyTask(api.TaskModel t) {
  if (t.status == api.TaskStatus.completed ||
      t.status == api.TaskStatus.approved ||
      t.status == api.TaskStatus.submitted) {
    return TaskFilterBucket.completed;
  }
  final due = t.dueDate;
  if (due.isBefore(DateTime.fromMillisecondsSinceEpoch(1))) {
    return TaskFilterBucket.all;
  }
  final today = todayInVN();
  final dueDate = dateOnlyInVN(due);
  final diff = dueDate.difference(today).inDays;
  if (diff < 0) return TaskFilterBucket.overdue;
  if (diff == 0) return TaskFilterBucket.today;
  if (diff > 0 && diff <= 7) return TaskFilterBucket.upcoming;
  return TaskFilterBucket.all;
}

/// Filter 1 list theo bucket (an toàn cho null).
List<api.TaskModel> applyBucketFilter(
  List<api.TaskModel> source,
  TaskFilterBucket bucket,
) {
  switch (bucket) {
    case TaskFilterBucket.today:
      return source.where((t) => classifyTask(t) == TaskFilterBucket.today)
          .toList();
    case TaskFilterBucket.upcoming:
      return source
          .where((t) =>
              classifyTask(t) == TaskFilterBucket.upcoming ||
              classifyTask(t) == TaskFilterBucket.today)
          .toList();
    case TaskFilterBucket.overdue:
      return source.where((t) => classifyTask(t) == TaskFilterBucket.overdue)
          .toList();
    case TaskFilterBucket.completed:
      return source.where((t) => classifyTask(t) == TaskFilterBucket.completed)
          .toList();
    case TaskFilterBucket.all:
      return List.unmodifiable(source);
  }
}

/// Group by date label (Hôm nay / Ngày mai / dd/MM) theo UTC+7.
Map<String, List<api.TaskModel>> groupTasksByDate(List<api.TaskModel> tasks) {
  final map = <String, List<api.TaskModel>>{};
  for (final t in tasks) {
    final due = t.dueDate;
    final today = todayInVN();
    final dueDate = dateOnlyInVN(due);
    final diff = dueDate.difference(today).inDays;
    final key = switch (diff) {
      0 => 'Hôm nay',
      1 => 'Ngày mai',
      -1 => 'Hôm qua',
      _ when diff < 0 => 'Quá hạn (${diff.abs()} ngày trước)',
      _ when diff <= 7 => intl.DateFormat('EEEE').format(dueDate),
      _ => intl.DateFormat('dd/MM/yyyy').format(dueDate),
    };
    map.putIfAbsent(key, () => []).add(t);
  }
  return map;
}

/// Sort thứ tự ổn định — gom nhóm theo date label và sắp theo thời gian trong nhóm.
List<MapEntry<String, List<api.TaskModel>>> sortedGroups(Map<String, List<api.TaskModel>> groups) {
  final order = {'Hôm nay': 0, 'Ngày mai': 1, 'Hôm qua': -1};
  final entries = groups.entries.toList();
  entries.sort((a, b) {
    final oa = order[a.key];
    final ob = order[b.key];
    if (oa != null || ob != null) {
      if (oa == null) return 1;
      if (ob == null) return -1;
      return oa.compareTo(ob);
    }
    return a.key.compareTo(b.key);
  });
  for (final entry in entries) {
    entry.value.sort((a, b) {
      return a.dueDate.compareTo(b.dueDate);
    });
  }
  return entries;
}

/// Helper padding/margin chuẩn product.
const double taskCardRadius = 16;
const taskCardHPadding = AppSpacing.lg;
const taskCardVPadding = AppSpacing.md;
