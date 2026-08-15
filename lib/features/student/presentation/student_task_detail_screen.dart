import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/task_model.dart' as api;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../tasks/providers/task_providers.dart';
import 'widgets/task_report_action_panel.dart';
import 'widgets/task_report_view_sheet.dart';

class StudentTaskDetailScreen extends ConsumerStatefulWidget {
  const StudentTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<StudentTaskDetailScreen> createState() =>
      _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState
    extends ConsumerState<StudentTaskDetailScreen> {
  Color _statusColor(api.TaskStatus s) => switch (s) {
        api.TaskStatus.pending => AppColors.warning,
        api.TaskStatus.inProgress => AppColors.primary,
        api.TaskStatus.completed => AppColors.success,
        api.TaskStatus.approved => AppColors.success,
        api.TaskStatus.submitted => AppColors.info,
        api.TaskStatus.overdue => AppColors.error,
        api.TaskStatus.rejected => AppColors.error,
        _ => AppColors.error,
      };

  String _statusLabel(api.TaskStatus s) => switch (s) {
        api.TaskStatus.pending => 'Đang chờ',
        api.TaskStatus.inProgress => 'Đang làm',
        api.TaskStatus.completed => 'Hoàn thành',
        api.TaskStatus.approved => 'Đã duyệt',
        api.TaskStatus.submitted => 'Đã gửi',
        api.TaskStatus.rejected => 'Bị từ chối',
        api.TaskStatus.overdue => 'Quá hạn',
        _ => 'Không xác định',
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

  /// Mở form xem lại báo cáo (read-only) sau khi submit thành công.
  Future<void> _openReportViewSheet(String taskId) async {
    // Invalidate để chắc chắn dữ liệu mới nhất.
    ref.invalidate(taskReportByTaskProvider(taskId));
    ref.invalidate(taskImagesByTaskProvider(taskId));
    await showTaskReportViewSheet(context, taskId);
  }

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
        actions: [
          // Nút xem lịch sử báo cáo — luôn hiển thị cho task đã có report.
          IconButton(
            tooltip: 'Lịch sử báo cáo',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _openReportViewSheet(widget.taskId),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(taskDetailProvider(widget.taskId));
          ref.invalidate(taskReportByTaskProvider(widget.taskId));
          ref.invalidate(taskImagesByTaskProvider(widget.taskId));
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: taskAsync.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 200),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => _buildError(e, tt, cs),
          data: (task) => _buildBody(task, tt, cs),
        ),
      ),
    );
  }

  Widget _buildError(Object e, TextTheme tt, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
        const SizedBox(height: AppSpacing.md),
        Text('Không thể tải công việc',
            style: tt.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text('$e',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(taskDetailProvider(widget.taskId)),
            child: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final isCompleted = task.status == api.TaskStatus.completed ||
        task.status == api.TaskStatus.approved ||
        task.status == api.TaskStatus.submitted;

    // Kiểm tra task đã có report chưa (mỗi task chỉ được gửi 1 report).
    final reportsAsync = ref.watch(taskReportByTaskProvider(task.id));
    final hasReport = reportsAsync.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    // Các status không cho phép submit: completed/approved/submitted/rejected/cancelled
    // hoặc task đã có report (1 report / task).
    final cannotSubmit = isCompleted ||
        task.status == api.TaskStatus.rejected ||
        task.status == api.TaskStatus.cancelled ||
        hasReport;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          if (cannotSubmit)
            _buildReportView(task, tt, cs, hasReport: hasReport)
          else
            TaskReportActionPanel(
              task: task,
              onReportSubmitted: () {
                _openReportViewSheet(task.id);
              },
            ),
          const SizedBox(height: AppSpacing.huge),
        ],
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
                child: Icon(_typeIcon(task.taskType),
                    color: _typeColor(task.taskType), size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                style: tt.bodyMedium
                    ?.copyWith(color: cs.onSurface.withAlpha(179), height: 1.5),
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
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (task.experimentTitle != null)
            _buildInfoRow(
                Icons.title_rounded, 'Tên thí nghiệm', task.experimentTitle!, tt, cs),
          if (task.experimentCode != null)
            _buildInfoRow(
                Icons.code_rounded, 'Mã thí nghiệm', task.experimentCode!, tt, cs),
          if (task.experimentStageName != null)
            _buildInfoRow(Icons.timelapse_rounded, 'Giai đoạn',
                task.experimentStageName!, tt, cs),
          if (task.batchCode != null)
            _buildInfoRow(
                Icons.batch_prediction_rounded, 'Lô cây', task.batchCode!, tt, cs),
          if (task.careScheduleTitle != null)
            _buildInfoRow(Icons.event_note_rounded, 'Lịch chăm sóc',
                task.careScheduleTitle!, tt, cs),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.sm),
              Text('Hạn hoàn thành',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              const Spacer(),
              Text(
                formatDueDate(task.dueDate),
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
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (task.createdByName != null)
            _buildInfoRow(Icons.person_outline_rounded, 'Người tạo',
                task.createdByName!, tt, cs),
          if (task.assignedToName != null)
            _buildInfoRow(Icons.engineering_rounded, 'Người thực hiện',
                task.assignedToName!, tt, cs),
          _buildInfoRow(Icons.access_time_rounded, 'Ngày tạo',
              formatDateTime(task.createdAt), tt, cs),
          if (task.requiredSkillDescription != null)
            _buildInfoRow(Icons.psychology_rounded, 'Kỹ năng yêu cầu',
                task.requiredSkillDescription!, tt, cs),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withAlpha(128)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: Text(label,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
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
              Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện',
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...guidanceText.split('\n').map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface.withAlpha(179), height: 1.5)),
              )),
        ],
      ),
    );
  }

  /// Read-only view khi task đã done.
  Widget _buildReportView(
    api.TaskModel task,
    TextTheme tt,
    ColorScheme cs, {
    bool hasReport = false,
  }) {
    final hasSubmittedReport = hasReport ||
        task.status == api.TaskStatus.completed ||
        task.status == api.TaskStatus.approved ||
        task.status == api.TaskStatus.submitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasSubmittedReport ? Icons.history_rounded : Icons.lock_outline_rounded,
              size: 18,
              color: hasSubmittedReport ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              hasSubmittedReport ? 'Báo cáo đã gửi' : 'Không thể gửi báo cáo',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (hasSubmittedReport)
              TextButton.icon(
                onPressed: () => _openReportViewSheet(task.id),
                icon: const Icon(Icons.open_in_full_rounded, size: 16),
                label: const Text('Xem đầy đủ'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SNMSCard(
          child: Row(
            children: [
              Icon(
                hasSubmittedReport ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: hasSubmittedReport ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasSubmittedReport
                      ? 'Công việc đã có báo cáo. Mỗi task chỉ được gửi 1 báo cáo. Báo cáo chi tiết hiển thị ở phần "Xem đầy đủ".'
                      : 'Công việc ở trạng thái "${_statusLabel(task.status)}" nên không thể gửi báo cáo.',
                  style: tt.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
