import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/utils/experiment_helper.dart';
import '../providers/student_task_providers.dart';
import '../../tasks/providers/task_report_providers.dart' as report_providers;
import 'widgets/quick_report_sheet.dart';
import 'widgets/quick_measurement_sheet.dart';
import 'widgets/task_report_view_sheet.dart';

final studentTaskFilterProvider = StateProvider<StudentTaskFilter>((ref) {
  return StudentTaskFilter.today;
});

enum StudentTaskFilter { today, thisWeek, all, completed }

// Use API provider from student_task_providers.dart
final filteredStudentTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasks = ref.watch(studentTasksProvider);
  final filter = ref.watch(studentTaskFilterProvider);

  return tasks.whenData((list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    return list.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return switch (filter) {
        StudentTaskFilter.today     => taskDate == today,
        StudentTaskFilter.thisWeek => taskDate.isAfter(today.subtract(const Duration(days: 1))) && taskDate.isBefore(endOfWeek),
        StudentTaskFilter.all      => true,
        StudentTaskFilter.completed => task.status == TaskStatus.completed,
      };
    }).toList();
  });
});

class StudentTasksScreen extends ConsumerWidget {
  const StudentTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final filter = ref.watch(studentTaskFilterProvider);
    final tasks = ref.watch(filteredStudentTasksProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Cong viec cua toi', style: tt.titleLarge),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _FilterTabs(filter: filter, ref: ref, tt: tt, cs: cs),
          Expanded(
            child: tasks.when(
              data: (taskList) => taskList.isEmpty
                ? _EmptyState(tt: tt, cs: cs)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: taskList.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: _StudentTaskCard(
                        task: taskList[index],
                        tt: tt,
                        cs: cs,
                        onTap: () => _showTaskDetail(context, ref, taskList[index]),
                      ),
                    ),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(BuildContext context, WidgetRef ref, TaskModel task) {
    context.push('/student/tasks/${task.id}');
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.filter, required this.ref, required this.tt, required this.cs});
  final StudentTaskFilter filter;
  final WidgetRef ref;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: StudentTaskFilter.values.map((f) {
            final isSelected = f == filter;
            final label = switch (f) {
              StudentTaskFilter.today     => 'Hom nay',
              StudentTaskFilter.thisWeek => 'Tuan nay',
              StudentTaskFilter.all      => 'Tat ca',
              StudentTaskFilter.completed => 'Da xong',
            };
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(
                label: label,
                isSelected: isSelected,
                tt: tt,
                cs: cs,
                onTap: () => ref.read(studentTaskFilterProvider.notifier).state = f,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.tt, required this.cs, required this.onTap});
  final String label;
  final bool isSelected;
  final TextTheme tt;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : cs.outline.withAlpha(77)),
        ),
        child: Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: isSelected ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: cs.onSurface.withAlpha(51)),
          const SizedBox(height: AppSpacing.md),
          Text('Khong co cong viec', style: tt.titleMedium?.copyWith(color: cs.onSurface.withAlpha(128))),
          const SizedBox(height: AppSpacing.xs),
          Text('Tim thay cong viec phu hop', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(102))),
        ],
      ),
    );
  }
}

class _StudentTaskCard extends ConsumerWidget {
  const _StudentTaskCard({required this.task, required this.tt, required this.cs, required this.onTap});
  final TaskModel task;
  final TextTheme tt;
  final ColorScheme cs;
  final VoidCallback onTap;

  bool get _isOverdue {
    return task.status != TaskStatus.completed &&
        task.dueDate.isBefore(DateTime.now());
  }

  Color get _statusColor {
    return switch (task.status) {
      TaskStatus.pending    => _isOverdue ? AppColors.error : AppColors.warning,
      TaskStatus.inProgress => _isOverdue ? AppColors.error : AppColors.primary,
      TaskStatus.completed  => AppColors.success,
      TaskStatus.overdue    => AppColors.error,
    };
  }

  String get _statusLabelText {
    return switch (task.status) {
      TaskStatus.pending    => _isOverdue ? 'Quá hạn' : 'Chờ',
      TaskStatus.inProgress => _isOverdue ? 'Quá hạn' : 'Đang làm',
      TaskStatus.completed  => 'Hoàn thành',
      TaskStatus.overdue    => 'Quá hạn',
    };
  }

  IconData get _icon {
    return switch (task.taskType) {
      TaskType.planting    => Icons.eco_rounded,
      TaskType.watering   => Icons.water_drop_rounded,
      TaskType.fertilizing => Icons.science_rounded,
      TaskType.observation => Icons.visibility_rounded,
      TaskType.inspection  => Icons.search_rounded,
      TaskType.other       => Icons.more_horiz_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expCode = task.experimentCode ?? ExperimentHelper.getExperimentCode(task.experimentId);
    final stageName = task.experimentStageName ?? ExperimentHelper.getStageName(task.experimentId, task.stageId);
    final stageStatus = ExperimentHelper.getStageStatus(task.experimentId, task.stageId);
    final stageStatusColor = _getStageStatusColor(stageStatus, cs);
    final batchLabel = (task.batchCode != null && task.batchCode!.isNotEmpty)
        ? task.batchCode!
        : ExperimentHelper.getBatchLabel(task.batchId);
    final reportAsync = ref.watch(report_providers.taskReportByTaskProvider(task.id));
    final hasReport = reportAsync.maybeWhen(data: (r) => r != null, orElse: () => false);

    return SNMSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 20, color: _statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.taskName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(expCode, style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stageName,
                            style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabelText, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MetaItem(icon: Icons.calendar_today_rounded, label: formatDate(task.dueDate), tt: tt, cs: cs),
              const SizedBox(width: AppSpacing.md),
              _MetaItem(icon: _icon, label: task.taskTypeLabel, tt: tt, cs: cs),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stageStatusColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ExperimentHelper.getStageStatusLabel(stageStatus),
                  style: tt.labelSmall?.copyWith(color: stageStatusColor, fontWeight: FontWeight.w500, fontSize: 10),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withAlpha(102)),
            ],
          ),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.batch_prediction_rounded, size: 13, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(batchLabel, style: tt.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 10)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timelapse_rounded, size: 13, color: stageStatusColor),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stageStatusColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ExperimentHelper.getStageStatusLabel(stageStatus),
                      style: tt.labelSmall?.copyWith(color: stageStatusColor, fontWeight: FontWeight.w500, fontSize: 10),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13, color: cs.onSurface.withAlpha(102)),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(task.dueDate),
                    style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          if (task.status == TaskStatus.pending || task.status == TaskStatus.inProgress) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasReport
                        ? () => showTaskReportViewSheet(context, task.id)
                        : () => showQuickReportSheet(context, task),
                    icon: Icon(hasReport ? Icons.visibility_rounded : Icons.fact_check_rounded, size: 16),
                    label: Text(hasReport ? 'Xem báo cáo' : 'Báo cáo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: hasReport ? AppColors.info : AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showQuickMeasurementSheet(context, task),
                    icon: const Icon(Icons.straighten_rounded, size: 16),
                    label: const Text('Chỉ số'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStageStatusColor(StageStatus? status, ColorScheme cs) {
    if (status == null) return cs.onSurface.withAlpha(102);
    return switch (status) {
      StageStatus.active    => AppColors.primary,
      StageStatus.completed => AppColors.success,
      StageStatus.upcoming  => AppColors.warning,
    };
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, required this.tt, required this.cs});
  final IconData icon;
  final String label;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withAlpha(102)),
        const SizedBox(width: 4),
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
      ],
    );
  }
}

class _TaskDetailSheet extends StatefulWidget {
  const _TaskDetailSheet({required this.task});
  final TaskModel task;

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLeafColor = 'Xanh đậm';
  String _selectedHealth = 'Tốt';
  final List<String> _photoUrls = [];
  bool _showReportForm = false;

  @override
  void initState() {
    super.initState();
    _showReportForm = widget.task.taskType == TaskType.observation || widget.task.taskType == TaskType.inspection;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _leafCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final expCode = widget.task.experimentCode ?? ExperimentHelper.getExperimentCode(widget.task.experimentId);
    final stageName = widget.task.experimentStageName ?? ExperimentHelper.getStageName(widget.task.experimentId, widget.task.stageId);
    final stage = ExperimentHelper.getStage(widget.task.experimentId, widget.task.stageId);
    final batchLabel = (widget.task.batchCode != null && widget.task.batchCode!.isNotEmpty)
        ? widget.task.batchCode!
        : ExperimentHelper.getBatchLabel(widget.task.batchId);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Chi tiết công việc', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),

                // Experiment + Stage info
                SNMSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.task.taskName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(label: expCode, color: AppColors.primary, tt: tt),
                          _InfoChip(label: stageName, color: AppColors.info, tt: tt),
                          if (batchLabel != '—') _InfoChip(label: batchLabel, color: AppColors.warning, tt: tt),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _InfoRow(icon: Icons.calendar_today_rounded, label: 'Hạn', value: formatDate(widget.task.dueDate), tt: tt, cs: cs),
                          const SizedBox(width: AppSpacing.xl),
                          _InfoRow(icon: _getTaskIcon(widget.task.taskType), label: 'Loại', value: widget.task.taskTypeLabel, tt: tt, cs: cs),
                        ],
                      ),
                      if (stage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(icon: Icons.timelapse_rounded, label: 'Giai đoạn', value: stage.stageName, tt: tt, cs: cs),
                      ],
                      if (widget.task.description != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(widget.task.description!, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _StudentGuidanceCard(taskType: widget.task.taskType, tt: tt, cs: cs),
                const SizedBox(height: AppSpacing.xl),

                if (_showReportForm) ...[
                  Text('Báo cáo quan sát', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.md),
                  SNMSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Chiều cao (cm)', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: _heightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: 'VD: 25.5',
                                      suffixText: 'cm',
                                      filled: true,
                                      fillColor: cs.surfaceContainerHighest.withAlpha(128),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Số lá', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: _leafCountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'VD: 8',
                                      suffixText: 'lá',
                                      filled: true,
                                      fillColor: cs.surfaceContainerHighest.withAlpha(128),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Màu lá', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: _selectedLeafColor,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withAlpha(128),
                          ),
                          items: ['Xanh đậm', 'Xanh nhạt', 'Vàng nhẹ', 'Vàng', 'Nâu'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedLeafColor = v ?? _selectedLeafColor),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Tình trạng cây', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: _selectedHealth,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withAlpha(128),
                          ),
                          items: ['Tốt', 'Bình thường', 'Yếu', 'Có dấu hiệu bệnh'].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                          onChanged: (v) => setState(() => _selectedHealth = v ?? _selectedHealth),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Ghi chú quan sát', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'VD: Cây phát triển tốt, một số lá có dấu hiệu vàng nhẹ...',
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withAlpha(128),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _PhotoAttachmentSection(
                          tt: tt, cs: cs,
                          photoUrls: _photoUrls,
                          onRemove: (url) => setState(() => _photoUrls.remove(url)),
                          onAdd: () => setState(() => _photoUrls.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Gửi báo cáo', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  _PhotoAttachmentSection(
                    tt: tt, cs: cs,
                    photoUrls: _photoUrls,
                    onRemove: (url) => setState(() => _photoUrls.remove(url)),
                    onAdd: () => setState(() => _photoUrls.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showReportForm = true),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Báo cáo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xác nhận hoàn thành!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Xác nhận xong', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Báo cáo quan sát đã được gửi!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  IconData _getTaskIcon(TaskType type) {
    return switch (type) {
      TaskType.planting    => Icons.eco_rounded,
      TaskType.watering   => Icons.water_drop_rounded,
      TaskType.fertilizing => Icons.science_rounded,
      TaskType.observation => Icons.visibility_rounded,
      TaskType.inspection  => Icons.search_rounded,
      TaskType.other       => Icons.more_horiz_rounded,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color, required this.tt});
  final String label;
  final Color color;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Text(label, style: tt.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.tt, required this.cs});
  final IconData icon;
  final String label;
  final String value;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withAlpha(128)),
        const SizedBox(width: 4),
        Text('$label: ', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
        Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PhotoAttachmentSection extends StatelessWidget {
  const _PhotoAttachmentSection({
    required this.tt,
    required this.cs,
    required this.photoUrls,
    required this.onRemove,
    required this.onAdd,
  });
  final TextTheme tt;
  final ColorScheme cs;
  final List<String> photoUrls;
  final void Function(String) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_rounded, size: 16, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Hinh anh minh chung', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: AppSpacing.xs),
            Text('(tuy chon)', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(102))),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...photoUrls.map((url) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        color: cs.outline.withAlpha(20),
                        child: Icon(Icons.image_rounded, size: 32, color: cs.outline.withAlpha(77)),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(url),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(51)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 28, color: AppColors.primary.withAlpha(179)),
                      const SizedBox(height: 4),
                      Text('Them anh', style: tt.labelSmall?.copyWith(color: AppColors.primary.withAlpha(179))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (photoUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('${photoUrls.length} hinh anh duoc chon', style: tt.bodySmall?.copyWith(color: AppColors.primary)),
        ],
      ],
    );
  }
}

class _StudentGuidanceCard extends StatelessWidget {
  const _StudentGuidanceCard({required this.taskType, required this.tt, required this.cs});
  final TaskType taskType;
  final TextTheme tt;
  final ColorScheme cs;

  String get _guidanceText {
    return switch (taskType) {
      TaskType.watering =>
        '1. Kiểm tra độ ẩm đất bằng ngón tay (độ sâu 2cm).\n'
        '2. Tưới đều tại gốc cây, tránh làm ướt lá.\n'
        '3. Sử dụng bình tưới nhỏ để kiểm soát lượng nước.\n'
        '4. Ghi nhận kết quả vào phần Báo cáo.',
      TaskType.fertilizing =>
        '1. Pha loãng phân theo hướng dẫn trên bao bì.\n'
        '2. Bổ sung sau khi tưới nước 30 phút.\n'
        '3. Tránh để phân chạm trực tiếp vào thân cây.\n'
        '4. Theo dõi phản ứng của cây trong 24h.',
      TaskType.observation =>
        '1. Quan sát sự phát triển của cây: chiều cao, số lá, màu sắc.\n'
        '2. Ghi nhận các dấu hiệu bất thường (nếu có).\n'
        '3. Chụp ảnh minh chứng nếu phát hiện bất thường.\n'
        '4. Ghi nhận kết quả vào phần Báo cáo.',
      TaskType.inspection =>
        '1. Kiểm tra tổng thể: lá, thân, rễ.\n'
        '2. Ghi nhận tất cả các vấn đề phát hiện.\n'
        '3. Báo cáo ngay cho giáo viên hướng dẫn.\n'
        '4. Không tự ý xử lý nếu chưa được chỉ đạo.',
      TaskType.planting =>
        '1. Chuẩn bị đất: xới phóng, phân hữu cơ theo tỷ lệ.\n'
        '2. Tạo lỗ chấm nước 2-3cm sau cây.\n'
        '3. Tưới nước nhẹ ngay sau trồng.\n'
        '4. Theo dõi 3-5 ngày đầu sau trồng.',
      TaskType.other =>
        '1. Thực hiện theo hướng dẫn của giáo viên.\n'
        '2. Ghi nhận tiến độ và kết quả.\n'
        '3. Báo cáo khi hoàn thành.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện', style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._guidanceText.split('\n').map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withAlpha(179),
              height: 1.5,
            )),
          )),
        ],
      ),
    );
  }
}
