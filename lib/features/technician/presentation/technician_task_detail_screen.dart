import 'dart:io';
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
import '../../tasks/data/task_report_constants.dart';
import '../../tasks/data/task_report_submit_service.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/presentation/widgets/task_image_picker.dart';
import '../../tasks/presentation/widgets/measurement_recording_sheet.dart';
import '../../tasks/presentation/widgets/modern_quick_report_sheet.dart';
import '../../tasks/presentation/widgets/task_visual.dart';
import '../../../shared/utils/report_field_labels.dart';

class TechnicianTaskDetailScreen extends ConsumerStatefulWidget {
  const TechnicianTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TechnicianTaskDetailScreen> createState() => _TechnicianTaskDetailScreenState();
}

class _TechnicianTaskDetailScreenState extends ConsumerState<TechnicianTaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _waterController = TextEditingController();
  final _fertilizerController = TextEditingController();
  final _noteController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  String _selectedHealth = 'Tốt';
  bool _isSubmitting = false;
  List<File> _selectedImages = [];

  @override
  void dispose() {
    _waterController.dispose();
    _fertilizerController.dispose();
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
            if (task.status == api.TaskStatus.pending ||
                task.status == api.TaskStatus.inProgress) ...[
              _buildCareReportSection(task, tt, cs),
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

  Widget _buildCareReportSection(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final isWatering = task.taskType == api.TaskType.watering;
    final isFertilizing = task.taskType == api.TaskType.fertilizing;
    final showBoth = isWatering || isFertilizing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 18, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Báo cáo công việc', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SNMSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBoth) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lượng nước (ml)',
                              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _waterController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'VD: 500',
                              suffixText: 'ml',
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
                          Text('Phân bón (g)',
                              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _fertilizerController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'VD: 50',
                              suffixText: 'g',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Ghi chú công việc',
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Mô tả chi tiết công việc đã thực hiện...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập ghi chú' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TaskImagePicker(
                images: _selectedImages,
                onImagesChanged: (imgs) => setState(() => _selectedImages = imgs),
                isUploading: _isSubmitting,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final isPending = task.status == api.TaskStatus.pending;
    final typeSpec = getTaskVisualSpec(task.taskType);

    return Column(
      children: [
        // Big primary CTA — open modern Quick Report sheet.
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : () async {
                    await showApiQuickReportSheet(context, task);
                    if (mounted) {
                      ref.invalidate(taskReportByTaskProvider(task.id));
                      ref.invalidate(taskDetailProvider(task.id));
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: typeSpec.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.flash_on_rounded,
                size: 18, color: Colors.white),
            label: Text(
              'Hoàn thành & Báo cáo · ${typeSpec.label}',
              style: tt.titleSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _submitReport(
                    task.id, task.taskType,
                    experimentId: task.experimentId,
                    batchId: task.batchId,
                  ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                label: Text('Hoàn thành',
                    style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        if (isPending) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
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
        ],
        if (task.batchId != null && task.batchId!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '/growth/${task.batchId}?batchCode=${Uri.encodeComponent(task.batchCode ?? task.batchId!)}&experimentId=${task.experimentId}',
              ),
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: const Text('Xem chỉ số tăng trưởng'),
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
    );
  }

  Widget _buildReportView(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    final reportAsync = ref.watch(taskReportByTaskProvider(task.id));
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
                Icon(Icons.assignment_turned_in_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Báo cáo',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
    }
  }

  Future<void> _submitReport(String taskId, api.TaskType taskType, {
    String? experimentId,
    String? batchId,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final reportText = _buildReportText(taskType);
      final resultData = _buildResultData(taskType);

      final imageParams = _selectedImages
          .map((f) => TaskReportImageParam(
                file: f,
                uploadedAt: DateTime.now(),
              ))
          .toList();

      final params = SubmitParams(
        taskId: taskId,
        reportText: reportText,
        resultData: resultData,
        images: imageParams,
        experimentId: experimentId,
        batchId: batchId,
        markComplete: true,
        hasNewContent: true,
      );

      final outcome = await ref
          .read(taskReportSubmitServiceProvider)
          .submitAndOptionallyComplete(params);

      ref.invalidate(taskDetailProvider(taskId));
      ref.invalidate(taskReportByTaskProvider(taskId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(outcome.toUserMessage()),
            backgroundColor: outcome.mode == SubmitMode.error
                ? AppColors.error
                : AppColors.success,
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

  String _buildReportText(api.TaskType taskType) {
    final parts = <String>[];
    if (taskType == api.TaskType.watering || taskType == api.TaskType.fertilizing) {
      if (_waterController.text.isNotEmpty) {
        parts.add('Nước: ${_waterController.text}ml');
      }
      if (_fertilizerController.text.isNotEmpty) {
        parts.add('Phân bón: ${_fertilizerController.text}g');
      }
    }
    if (_noteController.text.isNotEmpty) {
      parts.add(_noteController.text);
    }
    return parts.isEmpty ? 'Đã hoàn thành' : parts.join(' | ');
  }

  Map<String, String> _buildResultData(api.TaskType taskType) {
    final out = <String, String>{};
    final schema = kQuickFormSchema[taskType];
    if (schema != null) {
      for (final f in schema.fields) {
        final c = _fieldControllers[f.key];
        final v = c?.text.trim();
        if (v != null && v.isNotEmpty) out[f.key] = v;
      }
    }
    final note = _noteController.text.trim();
    if (note.isNotEmpty) out['additionalNotes'] = note;
    out['condition'] = _selectedHealth;
    return out;
  }
}