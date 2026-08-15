import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../tasks/providers/my_tasks_provider.dart';
import '../../../tasks/providers/task_providers.dart';
import 'task_card.dart';
import 'task_visual.dart';

/// State provider cho bucket filter chuẩn product.
final taskHubBucketProvider = StateProvider<TaskFilterBucket>((ref) {
  return TaskFilterBucket.today;
});

/// Số task đã báo cáo theo từng taskId. Riverpod autoDispose.
final taskHubReportedByTaskProvider = FutureProvider.autoDispose<
    Map<String, int>>((ref) async {
  // Trả về đếm "đã có report" — chỗ nào UI cần set badge thì dùng.
  return <String, int>{};
});

/// Modern Task Hub shell — dùng chung Student + Technician.
class TaskHub extends ConsumerWidget {
  const TaskHub({
    super.key,
    required this.tasks,
    required this.rolePath,
    this.title = 'Công việc của tôi',
    this.subtitle = 'Theo dõi các tác vụ theo ngày',
    this.calendar = true,
    this.onQuickReport,
    this.onStartTask,
    this.onCompleteTask,
  });

  /// `AsyncValue<TaskBucketSet>` từ provider — 4 bucket riêng biệt khớp với
  /// các API tương ứng (today/upcoming/overdue/completed).
  final AsyncValue<TaskBucketSet> tasks;

  /// Route prefix cho task detail (`student` | `technician`).
  final String rolePath;

  /// Title & subtitle trên header.
  final String title;
  final String subtitle;

  /// Hiển thị nút chọn ngày calendar không?
  final bool calendar;

  /// Custom callback khi user bấm "Báo cáo nhanh" trên card → để có thể
  /// dùng cho TaskDetailScreen cũ vẫn gọi được bottom sheet.
  final Future<void> Function(api.TaskModel)? onQuickReport;

  final Future<void> Function(api.TaskModel)? onStartTask;
  final Future<void> Function(api.TaskModel)? onCompleteTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bucket = ref.watch(taskHubBucketProvider);
    final buckets = tasks.maybeWhen<TaskBucketSet>(
        data: (s) => s, orElse: () => TaskBucketSet.empty);
    // Tập taskId đã có report (dùng để override status "Hoàn thành").
    final reportedIds = ref.watch(reportedTaskIdsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => <String>{},
        );

    // Lấy danh sách task cho bucket đang chọn — KHỚP với API trả về (1-1).
    List<api.TaskModel> filtered;
    switch (bucket) {
      case TaskFilterBucket.today:
        filtered = buckets.today;
        break;
      case TaskFilterBucket.upcoming:
        filtered = buckets.upcoming;
        break;
      case TaskFilterBucket.overdue:
        filtered = buckets.overdue;
        break;
      case TaskFilterBucket.completed:
        filtered = buckets.completed;
        break;
      case TaskFilterBucket.all:
        // All = union 4 bucket đã dedupe.
        final seen = <String>{};
        filtered = [];
        for (final t in [
          ...buckets.overdue,
          ...buckets.today,
          ...buckets.upcoming,
          ...buckets.completed,
        ]) {
          if (seen.add(t.id)) filtered.add(t);
        }
        break;
    }
    final counts = <TaskFilterBucket, int>{
      TaskFilterBucket.today: buckets.today.length,
      TaskFilterBucket.upcoming: buckets.upcoming.length,
      TaskFilterBucket.overdue: buckets.overdue.length,
      TaskFilterBucket.completed: buckets.completed.length,
      TaskFilterBucket.all: filtered.length,
    };
    final grouped = sortedGroups(groupTasksByDate(filtered));

    return Column(
      children: [
        _HubHero(
          title: title,
          subtitle: subtitle,
          overdueCount: counts[TaskFilterBucket.overdue] ?? 0,
          todayCount: counts[TaskFilterBucket.today] ?? 0,
          upcomingCount: counts[TaskFilterBucket.upcoming] ?? 0,
          completedCount: counts[TaskFilterBucket.completed] ?? 0,
          allCount: counts[TaskFilterBucket.all] ?? 0,
        ),
        const SizedBox(height: AppSpacing.md),
        _FilterTabs(
          current: bucket,
          counts: counts,
          onChange: (b) =>
              ref.read(taskHubBucketProvider.notifier).state = b,
          tt: tt,
          cs: cs,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorRetry(
              error: e,
              onRetry: () {
                // Reload by re-checking source provider.
                final c = ref.read(taskHubBucketProvider.notifier).state;
                ref.read(taskHubBucketProvider.notifier).state = c;
              },
            ),
            data: (all_) {
              if (grouped.isEmpty) {
                return _EmptyBucket(bucket: bucket, cs: cs, tt: tt);
              }
              // Build danh sách widget: mỗi group có 1 header + N tasks.
              final children = <Widget>[];
              for (final entry in grouped) {
                // Header cho nhóm ngày.
                children.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm, AppSpacing.lg,
                        AppSpacing.sm, AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius:
                                BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(entry.key,
                            style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(
                          '${entry.value.length} tác vụ',
                          style: tt.labelMedium?.copyWith(
                              color: cs.onSurface
                                  .withAlpha(153)),
                        ),
                      ],
                    ),
                  ),
                );
                // Mỗi task trong nhóm.
                for (final t2 in entry.value) {
                  children.add(
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: TaskCard(
                        task: t2,
                        hasReport: reportedIds.contains(t2.id),
                        onTap: () =>
                            context.push('/$rolePath/tasks/${t2.id}'),
                      ),
                    ),
                  );
                }
              }
              return RefreshIndicator(
                onRefresh: () async {
                  // Re-fetch toàn bộ task + reports để cập nhật badge "Đã báo cáo".
                  ref.invalidate(reportedTaskIdsProvider);
                  ref.invalidate(myTasksProvider);
                  final c = ref.read(taskHubBucketProvider.notifier).state;
                  ref.read(taskHubBucketProvider.notifier).state = c;
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md,
                      AppSpacing.huge),
                  itemCount: children.length,
                  itemBuilder: (_, i) => children[i],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HubHero extends StatelessWidget {
  const _HubHero({
    required this.title,
    required this.subtitle,
    required this.overdueCount,
    required this.todayCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.allCount,
  });
  final String title;
  final String subtitle;
  final int overdueCount;
  final int todayCount;
  final int upcomingCount;
  final int completedCount;
  final int allCount;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withAlpha(60),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: tt.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: tt.bodySmall?.copyWith(color: Colors.white.withAlpha(204)),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _HubStat(label: 'Hôm nay', value: todayCount, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                _HubStat(
                    label: 'Sắp tới',
                    value: upcomingCount,
                    color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                _HubStat(
                    label: 'Quá hạn',
                    value: overdueCount,
                    color: const Color(0xFFFFCDD2)),
                const SizedBox(width: AppSpacing.md),
                _HubStat(
                    label: 'Hoàn thành',
                    value: completedCount,
                    color: Colors.white),
              ],
            ),
            if (overdueCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.priority_high_rounded,
                        color: Color(0xFFB71C1C), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$overdueCount tác vụ quá hạn cần xử lý',
                      style: tt.labelMedium?.copyWith(
                          color: const Color(0xFFB71C1C),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubStat extends StatelessWidget {
  const _HubStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$value',
                style: tt.headlineMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
            Text(label,
                style: tt.labelSmall
                    ?.copyWith(color: color.withAlpha(204), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.current,
    required this.counts,
    required this.onChange,
    required this.tt,
    required this.cs,
  });
  final TaskFilterBucket current;
  final Map<TaskFilterBucket, int> counts;
  final ValueChanged<TaskFilterBucket> onChange;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: TaskFilterBucket.values.map((b) {
          final selected = b == current;
          final count = counts[b] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChange(b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outline.withAlpha(60),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: cs.primary.withAlpha(50),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      b.icon,
                      size: 14,
                      color: selected ? Colors.white : cs.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      b.label,
                      style: tt.labelMedium?.copyWith(
                        color: selected ? Colors.white : cs.onSurface,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withAlpha(40)
                            : cs.surfaceContainerHighest.withAlpha(60),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count',
                        style: tt.labelSmall?.copyWith(
                          color: selected ? Colors.white : cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyBucket extends StatelessWidget {
  const _EmptyBucket({
    required this.bucket,
    required this.cs,
    required this.tt,
  });
  final TaskFilterBucket bucket;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final msg = switch (bucket) {
      TaskFilterBucket.today => 'Không có công việc hôm nay',
      TaskFilterBucket.upcoming => 'Chưa có công việc sắp tới',
      TaskFilterBucket.overdue => 'Tuyệt vời! Không có task quá hạn',
      TaskFilterBucket.completed => 'Chưa hoàn thành tác vụ nào',
      TaskFilterBucket.all => 'Danh sách trống',
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Icon(bucket.icon,
                      size: 40, color: cs.primary.withAlpha(180)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(msg,
                    style: tt.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: cs.onSurface.withAlpha(80)),
            const SizedBox(height: AppSpacing.md),
            Text('Không tải được công việc',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${error ?? ""}',
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(128)),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hiển thị thời gian overdue theo ngày + cảnh báo nổi bật. Helper export.
String formatOverdueDays(DateTime? dueDate) {
  if (dueDate == null) return '';
  final today = todayInVN();
  final due = dateOnlyInVN(dueDate);
  final diff = due.difference(today).inDays;
  if (diff >= 0) return '';
  return '${diff.abs()} ngày quá hạn';
}
