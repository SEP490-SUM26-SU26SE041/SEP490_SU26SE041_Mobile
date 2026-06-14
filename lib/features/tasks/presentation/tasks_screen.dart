import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../experiments/providers/experiment_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'All Tasks',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm task...',
                hintStyle: tt.bodyMedium?.copyWith(
                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: 20,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark.withAlpha(128)
                    : AppColors.backgroundLight.withAlpha(128),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          // Tab bar
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              labelStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Tất cả'),
                Tab(text: 'Chờ xử lý'),
                Tab(text: 'Đang thực hiện'),
                Tab(text: 'Hoàn thành'),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: tasks.when(
              data: (taskList) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _TaskListView(tasks: taskList, filter: null, searchQuery: _searchQuery),
                    _TaskListView(tasks: taskList, filter: TaskStatus.pending, searchQuery: _searchQuery),
                    _TaskListView(tasks: taskList, filter: TaskStatus.inProgress, searchQuery: _searchQuery),
                    _TaskListView(tasks: taskList, filter: TaskStatus.completed, searchQuery: _searchQuery),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.tasks, required this.filter, required this.searchQuery});
  final List<TaskModel> tasks;
  final TaskStatus? filter;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    var filtered = filter == null
        ? tasks
        : tasks.where((t) => t.status == filter).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
          t.taskName.toLowerCase().contains(searchQuery) ||
          (t.description?.toLowerCase().contains(searchQuery) ?? false) ||
          (t.assignedTo?.toLowerCase().contains(searchQuery) ?? false) ||
          t.taskTypeLabel.toLowerCase().contains(searchQuery)
      ).toList();
    }

    if (filtered.isEmpty) {
      return _EmptyState(filter: filter, searchQuery: searchQuery);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _ResearchTaskCard(task: filtered[index]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.searchQuery});
  final TaskStatus? filter;
  final String searchQuery;

  String get _label {
    if (searchQuery.isNotEmpty) return 'Không tìm thấy task phù hợp';
    return switch (filter) {
      TaskStatus.pending    => 'Không có task chờ xử lý',
      TaskStatus.inProgress => 'Không có task đang thực hiện',
      TaskStatus.completed => 'Không có task hoàn thành',
      TaskStatus.overdue   => 'Không có task quá hạn',
      null                 => 'Chưa có task nào',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(102),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _label,
            style: tt.bodyLarge?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearchTaskCard extends StatelessWidget {
  const _ResearchTaskCard({required this.task});
  final TaskModel task;

  Color get _statusColor => switch (task.status) {
    TaskStatus.pending    => AppColors.warning,
    TaskStatus.inProgress => AppColors.info,
    TaskStatus.completed => AppColors.success,
    TaskStatus.overdue   => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    TaskType.planting     => Icons.grass_rounded,
    TaskType.watering    => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.science_rounded,
    TaskType.observation  => Icons.visibility_rounded,
    TaskType.inspection  => Icons.search_rounded,
  };

  String get _statusLabel => switch (task.status) {
    TaskStatus.pending    => 'Chờ xử lý',
    TaskStatus.inProgress => 'Đang thực hiện',
    TaskStatus.completed => 'Hoàn thành',
    TaskStatus.overdue   => 'Quá hạn',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isOverdue = task.status == TaskStatus.overdue ||
        (task.status != TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? AppColors.error.withAlpha(60) : borderColor.withAlpha(80),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 22 : 10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showTaskDetail(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: type icon + task name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor.withAlpha(30), width: 0.8),
                      ),
                      child: Icon(_typeIcon, size: 22, color: _statusColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskName,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (task.description != null && task.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                task.description!,
                                style: tt.bodySmall?.copyWith(
                                  color: textSecondary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _statusColor.withAlpha(35), width: 0.8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: tt.labelSmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Meta row: assignee + deadline + batch
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 8,
                  children: [
                    // Assignee
                    if (task.assignedTo != null && task.assignedTo!.isNotEmpty)
                      _MetaChip(
                        icon: Icons.person_outline_rounded,
                        label: task.assignedTo!,
                        color: AppColors.primary,
                      ),
                    // Deadline
                    _MetaChip(
                      icon: isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
                      label: 'Hạn: ${_formatDate(task.dueDate)}',
                      color: isOverdue ? AppColors.error : textSecondary,
                    ),
                    // Batch
                    if (task.batchId != null && task.batchId!.isNotEmpty)
                      _MetaChip(
                        icon: Icons.batch_prediction_rounded,
                        label: task.batchId!,
                        color: AppColors.success,
                      ),
                    // AI suggestion
                    if (task.aiSuggestion != null)
                      _MetaChip(
                        icon: Icons.auto_awesome,
                        label: 'AI gợi ý',
                        color: AppColors.info,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TaskDetailSheet(task: task),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withAlpha(180)),
        const SizedBox(width: 4),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: color.withAlpha(180),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({required this.task});
  final TaskModel task;

  Color get _statusColor => switch (task.status) {
    TaskStatus.pending    => AppColors.warning,
    TaskStatus.inProgress => AppColors.info,
    TaskStatus.completed => AppColors.success,
    TaskStatus.overdue   => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    TaskType.planting     => Icons.grass_rounded,
    TaskType.watering    => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.science_rounded,
    TaskType.observation  => Icons.visibility_rounded,
    TaskType.inspection  => Icons.search_rounded,
  };

  String get _statusLabel => switch (task.status) {
    TaskStatus.pending    => 'Chờ xử lý',
    TaskStatus.inProgress => 'Đang thực hiện',
    TaskStatus.completed => 'Hoàn thành',
    TaskStatus.overdue   => 'Quá hạn',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isOverdue = task.status == TaskStatus.overdue ||
        (task.status != TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _statusColor.withAlpha(35)),
                ),
                child: Icon(_typeIcon, size: 26, color: _statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: tt.labelSmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Mô tả', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 6),
            Text(task.description!, style: tt.bodyMedium),
          ],
          const SizedBox(height: 20),
          // Meta info
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Người được giao',
            value: task.assignedTo ?? 'Chưa giao',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
            label: 'Thời hạn',
            value: _formatDate(task.dueDate),
            valueColor: isOverdue ? AppColors.error : null,
            isDark: isDark,
          ),
          if (task.batchId != null && task.batchId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.batch_prediction_rounded,
              label: 'Batch',
              value: task.batchId!,
              isDark: isDark,
            ),
          ],
          if (task.stageId != null && task.stageId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.layers_outlined,
              label: 'Giai đoạn',
              value: task.stageId!,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary.withAlpha(153)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: tt.bodyMedium?.copyWith(color: textSecondary),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
