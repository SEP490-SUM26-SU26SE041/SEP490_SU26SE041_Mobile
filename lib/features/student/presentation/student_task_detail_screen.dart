import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../../core/api/models/task_report_model.dart' as report_model;
import '../../../core/api/services/task_report_api_service.dart' as report_api;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/providers/task_report_providers.dart' as report_providers;

class StudentTaskDetailScreen extends ConsumerStatefulWidget {
  const StudentTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<StudentTaskDetailScreen> createState() => _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState extends ConsumerState<StudentTaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLeafColor = 'Xanh đậm';
  String _selectedHealth = 'Khỏe mạnh';
  bool _isSubmitting = false;

  final List<String> _leafColors = ['Xanh đậm', 'Xanh', 'Vàng nhạt', 'Xanh bóng', 'Khác'];
  final List<String> _healthStatuses = ['Khỏe mạnh', 'Bình thường', 'Yếu', 'Rất tốt'];

  @override
  void dispose() {
    _heightController.dispose();
    _leafCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _statusColor(api.TaskStatus s) => switch (s) {
    api.TaskStatus.pending => AppColors.warning,
    api.TaskStatus.inProgress => AppColors.primary,
    api.TaskStatus.completed => AppColors.success,
    api.TaskStatus.approved => AppColors.success,
    api.TaskStatus.submitted => AppColors.info,
    _ => AppColors.error,
  };

  String _statusLabel(api.TaskStatus s) => switch (s) {
    api.TaskStatus.pending => 'Đang chờ',
    api.TaskStatus.inProgress => 'Đang làm',
    api.TaskStatus.completed => 'Hoàn thành',
    api.TaskStatus.approved => 'Đã duyệt',
    api.TaskStatus.submitted => 'Đã gửi',
    api.TaskStatus.rejected => 'Bị từ chối',
    _ => 'Quá hạn',
  };

  Color _typeColor(api.TaskType t) => switch (t) {
    api.TaskType.observation => AppColors.accent,
    api.TaskType.inspection => AppColors.warning,
    api.TaskType.planting => AppColors.success,
    api.TaskType.watering => AppColors.info,
    api.TaskType.fertilizing => AppColors.primary,
    _ => AppColors.accent,
  };

  IconData _typeIcon(api.TaskType t) => switch (t) {
    api.TaskType.observation => Icons.visibility_rounded,
    api.TaskType.inspection => Icons.search_rounded,
    api.TaskType.planting => Icons.eco_rounded,
    api.TaskType.watering => Icons.water_drop_rounded,
    api.TaskType.fertilizing => Icons.science_rounded,
    _ => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
                const SizedBox(height: AppSpacing.md),
                Text('Không thể tải công việc', style: tt.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('$e', textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => ref.invalidate(taskDetailProvider(widget.taskId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (task) => _buildBody(context, task, tt, cs),
      ),
    );
  }

  Widget _buildBody(BuildContext context, api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(task, tt, cs),
            const SizedBox(height: AppSpacing.lg),
            _buildExperimentInfo(task, tt, cs),
            const SizedBox(height: AppSpacing.lg),
            _buildAssignmentInfo(task, tt, cs),
            const SizedBox(height: AppSpacing.lg),
            _buildGuidanceCard(task, tt, cs),
            const SizedBox(height: AppSpacing.lg),
            if (task.status == api.TaskStatus.inProgress ||
                task.status == api.TaskStatus.pending) ...[
              _buildObservationReportSection(task, tt, cs),
              const SizedBox(height: AppSpacing.lg),
              _buildActionButtons(task, tt, cs),
            ] else if (task.status == api.TaskStatus.completed ||
                task.status == api.TaskStatus.submitted ||
                task.status == api.TaskStatus.approved) ...[
              _buildReportView(task, tt, cs),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _typeColor(task.taskType).withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_typeIcon(task.taskType), color: _typeColor(task.taskType), size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(task.status).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(task.status),
                            style: tt.labelSmall?.copyWith(
                              color: _statusColor(task.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor(task.taskType).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.taskType.labelVi,
                            style: tt.labelSmall?.copyWith(
                              color: _typeColor(task.taskType),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                task.description,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(179), height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperimentInfo(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              Text('Thông tin thí nghiệm',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (task.experimentTitle != null)
            _buildInfoRow(Icons.title_rounded, 'Tên thí nghiệm', task.experimentTitle!, tt, cs),
          if (task.experimentCode != null)
            _buildInfoRow(Icons.code_rounded, 'Mã thí nghiệm', task.experimentCode!, tt, cs),
          if (task.experimentStageName != null)
            _buildInfoRow(Icons.timelapse_rounded, 'Giai đoạn', task.experimentStageName!, tt, cs),
          if (task.batchCode != null)
            _buildInfoRow(Icons.batch_prediction_rounded, 'Lô cây', task.batchCode!, tt, cs),
          if (task.careScheduleTitle != null)
            _buildInfoRow(Icons.event_note_rounded, 'Lịch chăm sóc', task.careScheduleTitle!, tt, cs),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.sm),
              Text('Hạn hoàn thành', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              const Spacer(),
              Text(
                formatDate(task.dueDate),
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentInfo(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_ind_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: AppSpacing.xs),
              Text('Thông tin phân công',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (task.createdByName != null)
            _buildInfoRow(Icons.person_outline_rounded, 'Người tạo', task.createdByName!, tt, cs),
          if (task.assignedToName != null)
            _buildInfoRow(Icons.engineering_rounded, 'Người thực hiện', task.assignedToName!, tt, cs),
          _buildInfoRow(Icons.access_time_rounded, 'Ngày tạo',
              formatDateTime(task.createdAt), tt, cs),
          if (task.requiredSkillDescription != null)
            _buildInfoRow(Icons.psychology_rounded, 'Kỹ năng yêu cầu', task.requiredSkillDescription!, tt, cs),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withAlpha(128)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
          ),
          Expanded(
            child: Text(value,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final guidanceText = switch (task.taskType) {
      api.TaskType.observation =>
        '1. Quan sát sự phát triển: chiều cao, số lá, màu sắc.\n'
        '2. Ghi nhận các dấu hiệu bất thường (nếu có).\n'
        '3. Chụp ảnh minh chứng nếu phát hiện bất thường.\n'
        '4. Ghi nhận kết quả vào phần Báo cáo.',
      api.TaskType.inspection =>
        '1. Kiểm tra tổng thể: lá, thân, rễ.\n'
        '2. Ghi nhận tất cả các vấn đề phát hiện.\n'
        '3. Báo cáo ngay cho giáo viên hướng dẫn.\n'
        '4. Không tự ý xử lý nếu chưa được chỉ đạo.',
      api.TaskType.watering =>
        '1. Kiểm tra độ ẩm đất trước khi tưới.\n'
        '2. Tưới đều tại gốc cây, tránh làm ướt lá.\n'
        '3. Lượng nước khuyến nghị: 200-500ml/gốc cây.\n'
        '4. Ghi nhận lại lượng nước đã sử dụng.',
      _ => '1. Đọc kỹ mô tả công việc.\n2. Thực hiện đúng quy trình.\n3. Ghi nhận kết quả.\n4. Báo cáo nếu gặp vấn đề.',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...guidanceText.split('\n').map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(179), height: 1.5)),
          )),
        ],
      ),
    );
  }

  Widget _buildObservationReportSection(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Báo cáo quan sát', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
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
                        TextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: 'VD: 25.5', suffixText: 'cm'),
                          validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
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
                        TextFormField(
                          controller: _leafCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'VD: 8', suffixText: 'lá'),
                          validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
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
                initialValue: _selectedLeafColor,
                decoration: const InputDecoration(),
                items: _leafColors
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLeafColor = v ?? _selectedLeafColor),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tình trạng cây', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedHealth,
                decoration: const InputDecoration(),
                items: _healthStatuses
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedHealth = v ?? _selectedHealth),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Ghi chú quan sát', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'VD: Cây phát triển tốt, một số lá có dấu hiệu vàng nhẹ...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final isPending = task.status == api.TaskStatus.pending;
    final isInProgress = task.status == api.TaskStatus.inProgress;

    return Row(
      children: [
        if (isPending)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : () => _startTask(task.id),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (isPending) const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : () => _submitReport(task.id),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            label: Text(isInProgress ? 'Gửi báo cáo' : 'Gửi báo cáo',
                style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportView(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final reportAsync = ref.watch(taskReportByTaskProvider(task.id));
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => SNMSCard(
        child: Text('Chưa có báo cáo', style: tt.bodyMedium),
      ),
      data: (report) {
        if (report == null) {
          return SNMSCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Công việc đã hoàn thành', style: tt.bodyMedium)),
              ],
            ),
          );
        }
        return SNMSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Báo cáo đã gửi',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (report.submittedBy != null) ...[
                Text('Người gửi: ${report.submittedBy}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              ],
              Text('Thời gian: ${formatDateTime(report.submittedAt)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              if (report.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(report.description, style: tt.bodyMedium),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _startTask(String taskId) async {
    try {
      await ref.read(startTaskProvider(taskId).future);
      ref.invalidate(taskDetailProvider(taskId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bắt đầu công việc!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitReport(String taskId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final dto = report_api.CreateTaskReportDto(
        taskId: taskId,
        reportText: _noteController.text.isNotEmpty
            ? _noteController.text
            : 'Chiều cao: ${_heightController.text}cm, Số lá: ${_leafCountController.text}, Màu: $_selectedLeafColor, Tình trạng: $_selectedHealth',
        resultData: report_model.ReportResultData(
          condition: _selectedHealth,
          additionalNotes: _noteController.text,
        ),
      );
      await ref.read(report_providers.submitReportProvider(dto).future);

      ref.invalidate(taskDetailProvider(taskId));
      ref.invalidate(taskReportByTaskProvider(taskId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo đã được gửi!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}