import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/growth_task_model.dart' as task_model;
import '../../tasks/providers/task_providers.dart';

// Task list provider wrapper - convert API TaskModel to internal TaskModel
final researcherTasksListProvider = FutureProvider.autoDispose<List<task_model.TaskModel>>((ref) async {
  final scope = ref.watch(taskScopeFilterProvider);
  final apiTasks = await ref.read(taskRepoProvider).getResearcherCreatedTasks(scope: scope);
  return apiTasks.map((api) => task_model.TaskModel.fromApiJson({
    'id': api.id,
    'title': api.title,
    'description': api.description,
    'taskType': api.taskType.name,
    'status': api.status.name,
    'dueDate': api.dueDate.toIso8601String(),
    'createdAt': api.createdAt.toIso8601String(),
    'updatedAt': api.updatedAt.toIso8601String(),
    'experimentId': api.experimentId,
    'experimentTitle': api.experimentTitle,
    'experimentCode': api.experimentCode,
    'experimentStageId': api.experimentStageId,
    'experimentStageName': api.experimentStageName,
    'batchId': api.batchId,
    'batchCode': api.batchCode,
    'careScheduleId': api.careScheduleId,
    'careScheduleTitle': api.careScheduleTitle,
    'createdByName': api.createdByName,
    'assignedTo': api.assignedTo,
    'assignedToName': api.assignedToName,
  })).toList();
});

// Provider cho filter theo scope (sử dụng API endpoint filter)
final taskScopeFilterProvider = StateProvider<String?>((ref) => null);

// Provider cho date filter (quá hạn mấy ngày)
final overdueDaysFilterProvider = StateProvider<int?>((ref) => null);

/// Smart Task Screen - Product Quality UI với API thật
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  TaskFilter _activeFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gọi API với scope filter
    final tasksAsync = ref.watch(researcherTasksListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // KPI Stats Row - calculated from actual data
          tasksAsync.when(
            data: (tasks) => _TaskStatsBar(tasks: tasks),
            loading: () => const _TaskStatsBarSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Search bar
          _SearchBar(
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          // Filter chips - gọi API với scope tương ứng
          _FilterChipsRow(
            activeFilter: _activeFilter,
            onFilterChanged: (f) {
              setState(() => _activeFilter = f);
              // Cập nhật scope filter cho API
              final scope = switch (f) {
                TaskFilter.all => null,
                TaskFilter.overdue => 'overdue',
                TaskFilter.today => 'today',
                TaskFilter.upcoming => 'upcoming',
                TaskFilter.completed => 'completed',
              };
              ref.read(taskScopeFilterProvider.notifier).state = scope;
            },
          ),
          // Overdue date filter (hiển thị khi filter là overdue)
          if (_activeFilter == TaskFilter.overdue)
            _OverdueDateFilter(),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) => _SmartTaskList(
                tasks: tasks,
                filter: _activeFilter,
                searchQuery: _searchQuery,
                overdueDays: ref.watch(overdueDaysFilterProvider),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(
        'Lịch trình công việc',
        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        // Nút xem báo cáo - sẽ hiển thị danh sách task completed để xem báo cáo
        _HeaderActionButton(
          icon: Icons.assessment_rounded,
          label: 'Báo cáo',
          onTap: () => _showCompletedTasksForReport(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showCompletedTasksForReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CompletedTasksReportSheet(),
    );
  }
}

// ─── Overdue Date Filter ────────────────────────────────────────────────

class _OverdueDateFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueDays = ref.watch(overdueDaysFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _DateChip(
              label: 'Tất cả',
              isSelected: overdueDays == null,
              onTap: () => ref.read(overdueDaysFilterProvider.notifier).state = null,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _DateChip(
              label: '1 ngày',
              isSelected: overdueDays == 1,
              onTap: () => ref.read(overdueDaysFilterProvider.notifier).state = 1,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _DateChip(
              label: '3 ngày',
              isSelected: overdueDays == 3,
              onTap: () => ref.read(overdueDaysFilterProvider.notifier).state = 3,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _DateChip(
              label: '7 ngày',
              isSelected: overdueDays == 7,
              onTap: () => ref.read(overdueDaysFilterProvider.notifier).state = 7,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _DateChip(
              label: '14 ngày',
              isSelected: overdueDays == 14,
              onTap: () => ref.read(overdueDaysFilterProvider.notifier).state = 14,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.isSelected, required this.onTap, required this.isDark});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.error : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.error : Colors.grey.withAlpha(60)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header Action Button ────────────────────────────────────────────────

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── KPI Stats Bar ─────────────────────────────────────────────────────

class _TaskStatsBar extends StatelessWidget {
  const _TaskStatsBar({required this.tasks});
  final List<task_model.TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekLater = today.add(const Duration(days: 7));

    int overdueCount = 0;
    int todayCount = 0;
    int upcomingCount = 0;
    int completedCount = 0;

    for (final task in tasks) {
      final dueDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      if (task.status == task_model.TaskStatus.completed) {
        completedCount++;
      } else if (dueDate.isBefore(today)) {
        overdueCount++;
      } else if (dueDate == today || dueDate == tomorrow) {
        todayCount++;
      } else if (dueDate.isBefore(weekLater)) {
        upcomingCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(child: _StatTile(label: 'Quá hạn', count: overdueCount, color: AppColors.error, icon: Icons.warning_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _StatTile(label: 'Hôm nay', count: todayCount, color: AppColors.warning, icon: Icons.today_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _StatTile(label: 'Sắp tới', count: upcomingCount, color: AppColors.info, icon: Icons.schedule_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _StatTile(label: 'Hoàn thành', count: completedCount, color: AppColors.success, icon: Icons.check_circle_rounded)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.count, required this.color, required this.icon});
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text('$count', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(label, style: tt.labelSmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontWeight: FontWeight.w500, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TaskStatsBarSkeleton extends StatelessWidget {
  const _TaskStatsBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: List.generate(4, (i) => [
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.grey.withAlpha(30), borderRadius: BorderRadius.circular(14)))),
        ]).expand((e) => e).toList(),
      ),
    );
  }
}

// ─── Search Bar ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm công việc...',
          hintStyle: tt.bodyMedium?.copyWith(color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153)),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 20),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ─── Filter Chips ───────────────────────────────────────────────────────

enum TaskFilter { all, today, upcoming, overdue, completed }

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.activeFilter, required this.onFilterChanged});
  final TaskFilter activeFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(label: 'Tất cả', isSelected: activeFilter == TaskFilter.all, onTap: () => onFilterChanged(TaskFilter.all)),
          const SizedBox(width: 8),
          _FilterChip(label: 'Quá hạn', isSelected: activeFilter == TaskFilter.overdue, onTap: () => onFilterChanged(TaskFilter.overdue), color: AppColors.error),
          const SizedBox(width: 8),
          _FilterChip(label: 'Hôm nay', isSelected: activeFilter == TaskFilter.today, onTap: () => onFilterChanged(TaskFilter.today), color: AppColors.warning),
          const SizedBox(width: 8),
          _FilterChip(label: 'Sắp tới', isSelected: activeFilter == TaskFilter.upcoming, onTap: () => onFilterChanged(TaskFilter.upcoming), color: AppColors.info),
          const SizedBox(width: 8),
          _FilterChip(label: 'Hoàn thành', isSelected: activeFilter == TaskFilter.completed, onTap: () => onFilterChanged(TaskFilter.completed), color: AppColors.success),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? activeColor : (isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}

// ─── Smart Task List ─────────────────────────────────────────────────────

class _SmartTaskList extends StatelessWidget {
  const _SmartTaskList({required this.tasks, required this.filter, required this.searchQuery, this.overdueDays});
  final List<task_model.TaskModel> tasks;
  final TaskFilter filter;
  final String searchQuery;
  final int? overdueDays;

  List<task_model.TaskModel> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekLater = today.add(const Duration(days: 7));

    List<task_model.TaskModel> result;

    switch (filter) {
      case TaskFilter.all:
        result = List.from(tasks);
        break;
      case TaskFilter.today:
        result = tasks.where((t) {
          final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return due == today || due == tomorrow;
        }).toList();
        break;
      case TaskFilter.upcoming:
        result = tasks.where((t) {
          final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return due.isAfter(today) && due.isBefore(weekLater);
        }).toList();
        break;
      case TaskFilter.overdue:
        result = tasks.where((t) {
          final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          if (due.isBefore(today) && t.status != task_model.TaskStatus.completed) {
            if (overdueDays != null) {
              final daysDiff = today.difference(due).inDays;
              return daysDiff <= overdueDays!;
            }
            return true;
          }
          return false;
        }).toList();
        break;
      case TaskFilter.completed:
        result = tasks.where((t) => t.status == task_model.TaskStatus.completed).toList();
        break;
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.taskName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (t.assignedTo?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (t.experimentTitle?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  Map<String, List<task_model.TaskModel>> get _grouped {
    final Map<String, List<task_model.TaskModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final task in _filtered) {
      final dueDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      String key;

      if (task.status == task_model.TaskStatus.completed) {
        key = 'Hoàn thành';
      } else if (dueDate.isBefore(today)) {
        final daysOverdue = today.difference(dueDate).inDays;
        if (daysOverdue == 1) {
          key = 'Quá hạn 1 ngày';
        } else if (daysOverdue <= 3) {
          key = 'Quá hạn 1-3 ngày';
        } else if (daysOverdue <= 7) {
          key = 'Quá hạn 3-7 ngày';
        } else {
          key = 'Quá hạn $daysOverdue ngày';
        }
      } else if (dueDate == today) {
        key = 'Hôm nay';
      } else if (dueDate == tomorrow) {
        key = 'Ngày mai';
      } else {
        key = 'Sắp tới';
      }

      grouped.putIfAbsent(key, () => []).add(task);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_filtered.isEmpty) {
      return _EmptyState(filter: filter, searchQuery: searchQuery);
    }

    final grouped = _grouped;
    final sections = grouped.keys.toList();

    // Sort sections in logical order
    sections.sort((a, b) {
      final order = ['Quá hạn 1 ngày', 'Quá hạn 1-3 ngày', 'Quá hạn 3-7 ngày', 'Hôm nay', 'Ngày mai', 'Sắp tới', 'Hoàn thành'];
      final aIndex = order.indexWhere((o) => b.contains(o));
      final bIndex = order.indexWhere((o) => a.contains(o));
      if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      return a.compareTo(b);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final section = sections[i];
        final sectionTasks = grouped[section]!;
        final isOverdueSection = section.contains('Quá hạn');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              label: section,
              count: sectionTasks.length,
              isOverdue: isOverdueSection,
              isCompleted: section == 'Hoàn thành',
            ),
            const SizedBox(height: 10),
            ...sectionTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumTaskCard(
                task: task,
                onReportTap: task.status == task_model.TaskStatus.completed ? () => _showTaskReport(context, task) : null,
              ),
            )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showTaskReport(BuildContext context, task_model.TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TaskReportDetailSheet(taskId: task.id, taskName: task.taskName),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count, this.isOverdue = false, this.isCompleted = false});
  final String label;
  final int count;
  final bool isOverdue;
  final bool isCompleted;

  Color get _color {
    if (isOverdue) return AppColors.error;
    if (isCompleted) return AppColors.success;
    if (label == 'Hôm nay') return AppColors.warning;
    if (label == 'Ngày mai') return AppColors.info;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _color.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOverdue) ...[Icon(Icons.warning_amber_rounded, size: 14, color: _color), const SizedBox(width: 4)],
              if (isCompleted) ...[Icon(Icons.check_circle_rounded, size: 14, color: _color), const SizedBox(width: 4)],
              Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: _color)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: _color)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [_color.withAlpha(60), _color.withAlpha(0)])))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.searchQuery});
  final TaskFilter filter;
  final String searchQuery;

  String get _label {
    if (searchQuery.isNotEmpty) return 'Không tìm thấy công việc phù hợp';
    return switch (filter) {
      TaskFilter.all => 'Chưa có công việc nào',
      TaskFilter.today => 'Không có công việc hôm nay',
      TaskFilter.upcoming => 'Không có công việc sắp tới',
      TaskFilter.overdue => 'Không có công việc quá hạn',
      TaskFilter.completed => 'Không có công việc hoàn thành',
    };
  }

  IconData get _icon => searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.task_alt_rounded;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, size: 80, color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77)),
          const SizedBox(height: 16),
          Text(_label, style: tt.titleMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Premium Task Card ────────────────────────────────────────────────────

class PremiumTaskCard extends StatelessWidget {
  const PremiumTaskCard({super.key, required this.task, this.onReportTap});
  final task_model.TaskModel task;
  final VoidCallback? onReportTap;

  Color get _statusColor => switch (task.status) {
    task_model.TaskStatus.pending => AppColors.warning,
    task_model.TaskStatus.inProgress => AppColors.info,
    task_model.TaskStatus.completed => AppColors.success,
    task_model.TaskStatus.overdue => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    task_model.TaskType.planting => Icons.grass_rounded,
    task_model.TaskType.watering => Icons.water_drop_rounded,
    task_model.TaskType.fertilizing => Icons.science_rounded,
    task_model.TaskType.observation => Icons.visibility_rounded,
    task_model.TaskType.inspection => Icons.search_rounded,
    task_model.TaskType.other => Icons.more_horiz_rounded,
  };

  String get _statusLabel => switch (task.status) {
    task_model.TaskStatus.pending => 'Chờ xử lý',
    task_model.TaskStatus.inProgress => 'Đang thực hiện',
    task_model.TaskStatus.completed => 'Hoàn thành',
    task_model.TaskStatus.overdue => 'Quá hạn',
  };

  bool get _isOverdue => task.status == task_model.TaskStatus.overdue ||
      (task.status != task_model.TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    // Tính số ngày quá hạn
    String? overdueText;
    if (_isOverdue && task.status != task_model.TaskStatus.completed) {
      final days = DateTime.now().difference(task.dueDate).inDays;
      overdueText = 'Quá hạn $days ngày';
    }

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isOverdue ? AppColors.error.withAlpha(50) : (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 8), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(_typeIcon, size: 22, color: _statusColor)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.taskName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (task.experimentTitle != null) ...[
                                const SizedBox(height: 2),
                                Text(task.experimentTitle!, style: tt.bodySmall?.copyWith(color: AppColors.primary.withAlpha(200), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        _MetaTag(icon: Icons.person_outline_rounded, label: task.assignedTo ?? 'Chưa giao', color: AppColors.primary),
                        _MetaTag(
                          icon: _isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                          label: overdueText ?? _formatDueDate(task.dueDate),
                          color: _isOverdue ? AppColors.error : AppColors.textSecondaryLight,
                        ),
                        if (task.batchCode != null) _MetaTag(icon: Icons.inventory_2_outlined, label: task.batchCode!, color: AppColors.success),
                        if (task.experimentStageName != null) _MetaTag(icon: Icons.layers_outlined, label: task.experimentStageName!, color: AppColors.info),
                      ],
                    ),
                  ],
                ),
              ),
              // Report button for completed tasks
              if (task.status == task_model.TaskStatus.completed && onReportTap != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(10),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                    border: Border(top: BorderSide(color: AppColors.success.withAlpha(30))),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onReportTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assessment_rounded, size: 18, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text('Xem báo cáo', style: tt.labelMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.success),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dt.year, dt.month, dt.day);
    if (due == today) return 'Hôm nay';
    if (due == today.add(const Duration(days: 1))) return 'Ngày mai';
    if (due.isBefore(today)) return 'Quá hạn';
    return '${dt.day}/${dt.month}';
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withAlpha(180)),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: tt.labelSmall?.copyWith(color: color.withAlpha(200), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ─── Task Detail Sheet ──────────────────────────────────────────────────

class TaskDetailSheet extends StatelessWidget {
  const TaskDetailSheet({super.key, required this.task});
  final task_model.TaskModel task;

  Color get _statusColor => switch (task.status) {
    task_model.TaskStatus.pending => AppColors.warning,
    task_model.TaskStatus.inProgress => AppColors.info,
    task_model.TaskStatus.completed => AppColors.success,
    task_model.TaskStatus.overdue => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    task_model.TaskType.planting => Icons.grass_rounded,
    task_model.TaskType.watering => Icons.water_drop_rounded,
    task_model.TaskType.fertilizing => Icons.science_rounded,
    task_model.TaskType.observation => Icons.visibility_rounded,
    task_model.TaskType.inspection => Icons.search_rounded,
    task_model.TaskType.other => Icons.more_horiz_rounded,
  };

  String get _statusLabel => switch (task.status) {
    task_model.TaskStatus.pending => 'Chờ xử lý',
    task_model.TaskStatus.inProgress => 'Đang thực hiện',
    task_model.TaskStatus.completed => 'Hoàn thành',
    task_model.TaskStatus.overdue => 'Quá hạn',
  };

  bool get _isOverdue => task.status == task_model.TaskStatus.overdue ||
      (task.status != task_model.TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128), borderRadius: BorderRadius.circular(2))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(14)), child: Icon(_typeIcon, size: 28, color: _statusColor)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.taskName, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600))),
                  ],
                )),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.experimentTitle != null) ...[
                    _DetailItem(icon: Icons.science_outlined, label: 'Thí nghiệm', value: task.experimentTitle!, subValue: task.experimentCode, color: AppColors.primary, isDark: isDark),
                    const SizedBox(height: 12),
                  ],
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    _DetailItem(icon: Icons.description_outlined, label: 'Mô tả', value: task.description!, color: AppColors.info, isDark: isDark),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    Expanded(child: _MiniDetailItem(icon: Icons.person_outline_rounded, label: 'Người được giao', value: task.assignedTo ?? 'Chưa giao', isDark: isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _MiniDetailItem(icon: _isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined, label: 'Thời hạn', value: _formatDate(task.dueDate), valueColor: _isOverdue ? AppColors.error : null, isDark: isDark)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _MiniDetailItem(icon: Icons.layers_outlined, label: 'Giai đoạn', value: task.experimentStageName ?? 'Không có', isDark: isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _MiniDetailItem(icon: Icons.inventory_2_outlined, label: 'Lô (Batch)', value: task.batchCode ?? 'Không có', isDark: isDark)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.label, required this.value, this.subValue, required this.color, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(30))),
      child: Row(children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tt.labelSmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (subValue != null) ...[const SizedBox(height: 2), Text(subValue!, style: tt.bodySmall?.copyWith(color: color.withAlpha(180), fontWeight: FontWeight.w500))],
        ])),
      ]),
    );
  }
}

class _MiniDetailItem extends StatelessWidget {
  const _MiniDetailItem({required this.icon, required this.label, required this.value, this.valueColor, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgCard = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 14, color: textSecondary.withAlpha(153)), const SizedBox(width: 6), Text(label, style: tt.labelSmall?.copyWith(color: textSecondary.withAlpha(153)))]),
        const SizedBox(height: 4),
        Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── Completed Tasks Report Sheet ────────────────────────────────────────

class CompletedTasksReportSheet extends ConsumerWidget {
  const CompletedTasksReportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(researcherTasksListProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128), borderRadius: BorderRadius.circular(2))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assessment_rounded, color: AppColors.success, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Báo cáo công việc', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text('Chọn công việc đã hoàn thành để xem báo cáo', style: tt.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ])),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: tasksAsync.when(
              data: (allTasks) {
                final completedTasks = allTasks.where((t) => t.status == task_model.TaskStatus.completed).toList();
                if (completedTasks.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt_rounded, size: 64, color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77)),
                      const SizedBox(height: 12),
                      Text('Chưa có công việc hoàn thành', style: tt.titleMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
                    return _CompletedTaskItem(
                      task: task,
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => TaskReportDetailSheet(taskId: task.id, taskName: task.taskName),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedTaskItem extends StatelessWidget {
  const _CompletedTaskItem({required this.task, required this.onTap});
  final task_model.TaskModel task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.success.withAlpha(30), child: Icon(Icons.check_circle_rounded, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.taskName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(task.experimentTitle ?? '', style: tt.bodySmall?.copyWith(color: AppColors.primary.withAlpha(180)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Task Report Detail Sheet (gọi API theo task ID) ──────────────────

class TaskReportDetailSheet extends ConsumerWidget {
  const TaskReportDetailSheet({super.key, required this.taskId, required this.taskName});
  final String taskId;
  final String taskName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportAsync = ref.watch(taskReportByTaskProvider(taskId));
    final imagesAsync = ref.watch(taskImagesByTaskProvider(taskId));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128), borderRadius: BorderRadius.circular(2))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assessment_rounded, color: AppColors.success, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Báo cáo: $taskName', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('Thông tin báo cáo từ người thực hiện', style: tt.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ])),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: reportAsync.when(
              data: (report) {
                if (report == null) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 64, color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77)),
                      const SizedBox(height: 12),
                      Text('Chưa có báo cáo', style: tt.titleMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      Text('Báo cáo sẽ được cập nhật sau khi công việc hoàn thành', style: tt.bodySmall?.copyWith(color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153))),
                    ],
                  ));
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReportDetailItem(icon: Icons.description_rounded, label: 'Nội dung báo cáo', value: report.description.isNotEmpty ? report.description : report.title, color: AppColors.info, isDark: isDark),
                      const SizedBox(height: 12),
                      _ReportDetailItem(icon: Icons.person_rounded, label: 'Người nộp', value: report.submittedBy ?? 'Không xác định', color: AppColors.primary, isDark: isDark),
                      const SizedBox(height: 12),
                      _ReportDetailItem(icon: Icons.calendar_today_rounded, label: 'Ngày nộp', value: _formatDateTime(report.submittedAt), color: AppColors.success, isDark: isDark),
                      
                      // Task Images
                      const SizedBox(height: 24),
                      Row(children: [
                        Icon(Icons.photo_library_rounded, size: 20, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('Hình ảnh', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      imagesAsync.when(
                        data: (images) {
                          if (images.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight).withAlpha(128),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text('Chưa có hình ảnh', style: tt.bodyMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                            );
                          }
                          return SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final image = images[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: index < images.length - 1 ? 12 : 0),
                                  child: GestureDetector(
                                    onTap: () => _showImageFullScreen(context, image.imageUrl),
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.primary.withAlpha(20),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(image.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded))),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Lỗi tải ảnh: $e'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ReportDetailItem extends StatelessWidget {
  const _ReportDetailItem({required this.icon, required this.label, required this.value, required this.color, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(30))),
      child: Row(children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tt.labelSmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 3, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}
