import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/models/task_model.dart' as api;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/models/growth_task_model.dart' as internal;
import '../../../shared/utils/report_field_labels.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/presentation/widgets/measurement_recording_sheet.dart';
import '../../student/presentation/widgets/task_report_action_panel.dart';
import '../../student/presentation/widgets/task_report_view_sheet.dart';

class TechnicianTaskDetailScreen extends ConsumerStatefulWidget {
  const TechnicianTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TechnicianTaskDetailScreen> createState() => _TechnicianTaskDetailScreenState();
}

class _TechnicianTaskDetailScreenState extends ConsumerState<TechnicianTaskDetailScreen> {
  // NOTE: Form báo cáo giờ dùng TaskReportActionPanel y hệt Student
  // → render UI + quản lý state nội bộ của nó.
  // Technician giữ lại action `_startTask` để bắt đầu task khi ở trạng thái pending.
  bool _isStartingTask = false;

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
    _ => 'Quá hạn',
  };

  Color _typeColor(api.TaskType t) => switch (t) {
    api.TaskType.watering => AppColors.info,
    api.TaskType.fertilizing => AppColors.primary,
    api.TaskType.inspection => AppColors.warning,
    api.TaskType.planting => AppColors.success,
    api.TaskType.harvest => AppColors.accent,
    _ => AppColors.accent,
  };

  IconData _typeIcon(api.TaskType t) => switch (t) {
    api.TaskType.watering => Icons.water_drop_rounded,
    api.TaskType.fertilizing => Icons.grass_rounded,
    api.TaskType.inspection => Icons.search_rounded,
    api.TaskType.planting => Icons.eco_rounded,
    api.TaskType.harvest => Icons.agriculture_rounded,
    _ => Icons.agriculture_rounded,
  };

  String _typeLabel(api.TaskType t) => t.labelVi;

  /// Mở form xem lại báo cáo (read-only) sau khi submit thành công.
  /// Logic y hệt Student — dùng chung sheet `showTaskReportViewSheet`
  /// để hiển thị text + ảnh + kết quả AI scan có ý nghĩa.
  Future<void> _openReportViewSheet(String taskId) async {
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
          // Nút xem lịch sử báo cáo — giống Student.
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
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
            const SizedBox(height: AppSpacing.md),
            Text('Không thể tải công việc',
                style: tt.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text('$e', textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ElevatedButton(
                onPressed: () => ref.invalidate(taskDetailProvider(widget.taskId)),
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
        data: (task) => _buildBody(context, task, tt, cs),
      ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final isCompleted = task.status == api.TaskStatus.completed ||
        task.status == api.TaskStatus.approved ||
        task.status == api.TaskStatus.submitted;

    // Kiểm tra task đã có report chưa (mỗi task chỉ được gửi 1 report).
    final reportsAsync = ref.watch(taskReportByTaskProvider(task.id));
    final hasReport = reportsAsync.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    // Technician cũng dùng cùng logic với Student:
    //   - completed/approved/submitted/rejected/cancelled → không cho submit
    //   - task đã có report → không cho submit
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
          else ...[
            // Form báo cáo dynamic từ BE (y hệt Student):
            // tự load measurement definitions theo experiment, chọn AI provider,
            // upload ảnh + submit TaskReport + MeasurementRecords + TaskImages.
            TaskReportActionPanel(
              task: task,
              onReportSubmitted: () {
                _openReportViewSheet(task.id);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // Các action riêng của Technician: Bắt đầu / Bảng đo / Tăng trưởng.
            _buildTechnicianActions(task),
          ],
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
                            _typeLabel(task.taskType),
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
      api.TaskType.watering =>
        '1. Kiểm tra độ ẩm đất trước khi tưới.\n'
        '2. Tưới đều tại gốc cây, tránh làm ướt lá.\n'
        '3. Lượng nước khuyến nghị: 200-500ml/gốc cây.\n'
        '4. Ghi nhận lại lượng nước đã sử dụng.',
      api.TaskType.fertilizing =>
        '1. Pha loãng phân theo tỷ lệ khuyến nghị.\n'
        '2. Bổ sung sau khi tưới nước.\n'
        '3. Tránh bón phân trực tiếp vào thân cây.\n'
        '4. Theo dõi phản ứng của cây sau 24h.',
      api.TaskType.inspection =>
        '1. Kiểm tra tổng thể: lá, thân, rễ.\n'
        '2. Ghi nhận các dấu hiệu bất thường.\n'
        '3. Chụp ảnh minh chứng nếu cần.\n'
        '4. Báo cáo cho Researcher.',
      api.TaskType.planting =>
        '1. Chuẩn bị đất và hố trồng.\n'
        '2. Đặt cây con vào đúng vị trí.\n'
        '3. Lấp đất và tưới nước ngay.\n'
        '4. Ghi nhận số lượng cây đã trồng.',
      api.TaskType.harvest =>
        '1. Kiểm tra độ chín của quả/lá.\n'
        '2. Thu hoạch đúng kỹ thuật.\n'
        '3. Cân đo và ghi nhận sản lượng.\n'
        '4. Bảo quản đúng quy trình.',
      _ => '1. Đọc kỹ mô tả công việc.\n2. Thực hiện đúng quy trình.\n3. Ghi nhận kết quả.\n4. Báo cáo nếu gặp vấn đề.',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withAlpha(25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
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

  // ─── Care report section & legacy submit đã được thay bằng TaskReportActionPanel
  // (y hệt Student — dùng chung widget). Các nút hành động bên dưới giữ riêng
  // cho Technician: Bắt đầu (pending), Bảng đo, Xem chỉ số tăng trưởng.
  Widget _buildTechnicianActions(api.TaskModel task) {
    final isPending = task.status == api.TaskStatus.pending;

    return Column(
      children: [
        if (isPending) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isStartingTask ? null : () => _startTask(task.id),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_isStartingTask ? 'Đang bắt đầu...' : 'Bắt đầu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showMeasurementRecordingSheet(
                  context,
                  task,
                  onMeasurementComplete: () {
                    ref.invalidate(taskReportByTaskProvider(task.id));
                    ref.invalidate(taskDetailProvider(task.id));
                    if (mounted) context.pop();
                  },
                ),
                icon: const Icon(Icons.straighten_rounded, size: 18),
                label: const Text('Bảng đo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (task.batchId != null && task.batchId!.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/growth/${task.batchId}?batchCode=${Uri.encodeComponent(task.batchCode ?? task.batchId!)}&experimentId=${task.experimentId}',
                  ),
                  icon: const Icon(Icons.trending_up_rounded, size: 18),
                  label: const Text('Tăng trưởng'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(color: AppColors.success.withAlpha(80)),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReportView(api.TaskModel task, TextTheme tt, ColorScheme cs, {bool hasReport = false}) {
    final reportAsync = ref.watch(taskReportByTaskProvider(task.id));
    final hasSubmittedReport = hasReport ||
        task.status == api.TaskStatus.completed ||
        task.status == api.TaskStatus.approved ||
        task.status == api.TaskStatus.submitted;

    if (!hasSubmittedReport) {
      // Công việc chưa được gửi báo cáo.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text('Không thể gửi báo cáo',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SNMSCard(
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Công việc ở trạng thái "${_statusLabel(task.status)}" nên không thể gửi báo cáo.',
                    style: tt.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => SNMSCard(
        child: Text('Chưa có báo cáo', style: tt.bodyMedium),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return SNMSCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Công việc chưa có báo cáo nào', style: tt.bodyMedium)),
              ],
            ),
          );
        }
        // Mỗi task chỉ có 1 báo cáo chính — lấy báo cáo mới nhất.
        final latest = [...reports]
          .reduce((a, b) => a.submittedAt.isAfter(b.submittedAt) ? a : b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Báo cáo đã gửi',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Nút "Xem đầy đủ" mở sheet y hệt Student.
                TextButton.icon(
                  onPressed: () => _openReportViewSheet(task.id),
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                  label: const Text('Xem đầy đủ'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildReportCard(latest, tt, cs),
          ],
        );
      },
    );
  }

  /// Build chips từ description (parse key=value) hoặc plain text.
  /// Keys đã có trong rawResultData được bỏ qua.
  List<Widget> _buildDescriptionChips(
    String description,
    Map<String, dynamic>? rd,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final parsed = _parseKeyValueDescription(description);
    if (parsed != null && parsed.isNotEmpty) {
      final chips = <Widget>[];
      parsed.forEach((key, value) {
        if (value.isEmpty) return;
        if (rd != null && rd.containsKey(key)) return;
        chips.add(Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${labelForReportKey(key)}: $value',
            style: tt.labelSmall?.copyWith(color: AppColors.success),
          ),
        ));
        chips.add(const SizedBox(width: AppSpacing.xs));
      });
      return chips.isEmpty ? [Text(description, style: tt.bodyMedium)] : chips;
    }
    return [Text(description, style: tt.bodyMedium)];
  }

  /// Parse text dạng "key=value, key2=value2, ..." trả về Map.
  Map<String, String>? _parseKeyValueDescription(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !trimmed.contains('=')) return null;
    final parts = trimmed.split(RegExp(r',\s*'));
    final result = <String, String>{};
    int matchedCount = 0;
    for (final part in parts) {
      final eqIdx = part.indexOf('=');
      if (eqIdx <= 0) continue;
      final key = part.substring(0, eqIdx).trim();
      final value = part.substring(eqIdx + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      result[key] = value;
      matchedCount++;
    }
    return matchedCount >= 2 ? result : null;
  }

  Widget _buildReportCard(internal.TaskReportModel r, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SNMSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  formatDateTime(r.submittedAt),
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                ),
                const Spacer(),
                if (r.submittedBy != null)
                  Text(
                    '· ${r.submittedBy}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128)),
                  ),
              ],
            ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ..._buildDescriptionChips(r.description, r.rawResultData, tt, cs),
            ],
            if (r.rawResultData != null && r.rawResultData!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: r.rawResultData!.entries
                    .where((e) => e.key != 'additionalNotes')
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${labelForReportKey(e.key)}: ${e.value}',
                            style: tt.labelSmall?.copyWith(color: AppColors.success),
                          ),
                        ))
                    .toList(),
              ),
            ],
            // Ảnh minh chứng đính kèm báo cáo.
            if (r.images.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildReportImages(r.images, cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportImages(List<internal.TaskImageModel> images, ColorScheme cs) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final img = images[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: () => _showFullImage(context, img.imageUrl),
              child: Image.network(
                img.imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 88,
                    height: 88,
                    color: cs.surfaceContainerHighest.withAlpha(80),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 88,
                  height: 88,
                  color: cs.errorContainer.withAlpha(60),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: cs.error,
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          child: Center(
            child: Hero(
              tag: imageUrl,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTask(String taskId) async {
    setState(() => _isStartingTask = true);
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
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingTask = false);
    }
  }
}