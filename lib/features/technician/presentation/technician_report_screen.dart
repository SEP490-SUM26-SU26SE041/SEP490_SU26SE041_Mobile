import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/models/growth_task_model.dart';
import '../providers/technician_task_providers.dart';

class TechnicianReportScreen extends ConsumerStatefulWidget {
  const TechnicianReportScreen({super.key});

  @override
  ConsumerState<TechnicianReportScreen> createState() => _TechnicianReportScreenState();
}

class _TechnicianReportScreenState extends ConsumerState<TechnicianReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workDoneController = TextEditingController();
  final _issuesFoundController = TextEditingController();

  String? _selectedTaskId;
  String _selectedSeverity = 'Low';
  bool _showReportHistory = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _workDoneController.dispose();
    _issuesFoundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final tasksAsync = ref.watch(technicianTasksProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Báo cáo', style: tt.titleLarge),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showReportHistory = !_showReportHistory),
            icon: Icon(
              _showReportHistory ? Icons.add_rounded : Icons.history_rounded,
              size: 20,
            ),
            label: Text(_showReportHistory ? 'Viết báo cáo' : 'Lịch sử'),
          ),
        ],
      ),
      body: _showReportHistory
          ? _buildReportHistory(context)
          : _buildReportForm(context, tasksAsync),
    );
  }

  Widget _buildReportForm(BuildContext context, AsyncValue<List<TaskModel>> tasksAsync) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SNMSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Báo cáo gửi Researcher',
                          style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ghi nhận công việc đã thực hiện và các vấn đề phát hiện được.',
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Chọn công việc liên quan', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            tasksAsync.when(
              data: (tasks) {
                final pendingOrInProgress = tasks
                    .where((t) =>
                        t.status == TaskStatus.pending ||
                        t.status == TaskStatus.inProgress)
                    .toList();

                if (pendingOrInProgress.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text('Không có công việc cần báo cáo',
                              style: tt.bodyMedium),
                        ),
                      ],
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedTaskId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.task_alt_rounded),
                    hintText: 'Chọn công việc',
                  ),
                  items: pendingOrInProgress
                      .map((task) => DropdownMenuItem(
                            value: task.id,
                            child: Text(task.taskName, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedTaskId = value),
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn công việc' : null,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi: $e'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Tóm tắt công việc đã làm', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _workDoneController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả chi tiết công việc đã thực hiện...',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập mô tả công việc' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Vấn đề phát hiện', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _issuesFoundController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ghi nhận các vấn đề (nếu có)...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mức độ nghiêm trọng', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['Low', 'Medium', 'High'].map((s) {
                return ChoiceChip(
                  label: Text(s),
                  selected: _selectedSeverity == s,
                  onSelected: (_) =>
                      setState(() => _selectedSeverity = s),
                  selectedColor: AppColors.primary.withAlpha(50),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text('Gửi báo cáo',
                        style: tt.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHistory(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: AppSpacing.md),
          Text('Lịch sử báo cáo', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Tính năng đang phát triển...',
              style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128))),
        ],
      ),
    );
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // TODO: Implement API call to submit report to /api/task-reports
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Báo cáo đã được gửi cho Researcher!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _workDoneController.clear();
        _issuesFoundController.clear();
        _selectedTaskId = null;
        _selectedSeverity = 'Low';
        _isSubmitting = false;
      });
    }
  }
}