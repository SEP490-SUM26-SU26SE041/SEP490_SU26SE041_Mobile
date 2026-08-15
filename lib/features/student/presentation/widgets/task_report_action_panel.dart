import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/snms_card.dart';
import '../../../../shared/widgets/top_snackbar.dart';
import '../../../tasks/data/task_report_submit_service.dart';
import '../../../tasks/presentation/widgets/modern_quick_report_sheet.dart';
import '../../../tasks/presentation/widgets/task_image_picker.dart';
import '../../../tasks/presentation/widgets/task_visual.dart';
import '../../../tasks/providers/my_tasks_provider.dart';
import '../../../tasks/providers/task_providers.dart';

/// Panel action chính cho Student task detail.
///
/// Thiết kế 2 form độc lập theo `taskType`:
///   - **Observation** → "Ghi nhận tăng trưởng" (kèm TaskImagePicker).
///   - **Các loại khác** → "Báo cáo nhanh" (kèm TaskImagePicker).
///
/// Cả 2 form cùng dùng 1 [TaskReportSubmitService] → 1 lần submit duy nhất
/// (report + measurement + ảnh). Sau khi submit thành công, callback
/// [onReportSubmitted] được gọi để parent mở form xem lại báo cáo.
class TaskReportActionPanel extends ConsumerStatefulWidget {
  const TaskReportActionPanel({
    super.key,
    required this.task,
    required this.onReportSubmitted,
  });

  final api.TaskModel task;

  /// Callback khi submit thành công — parent dùng để mở form xem lại
  /// báo cáo và invalidate các provider liên quan.
  final VoidCallback onReportSubmitted;

  @override
  ConsumerState<TaskReportActionPanel> createState() =>
      _TaskReportActionPanelState();
}

class _TaskReportActionPanelState extends ConsumerState<TaskReportActionPanel> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLeafColor = 'Xanh đậm';
  String _selectedHealth = 'Khỏe mạnh';
  bool _isSubmitting = false;
  List<File> _selectedImages = [];

  final List<String> _leafColors = [
    'Xanh đậm',
    'Xanh',
    'Vàng nhạt',
    'Xanh bóng',
    'Khác',
  ];
  final List<String> _healthStatuses = [
    'Khỏe mạnh',
    'Bình thường',
    'Yếu',
    'Rất tốt',
  ];

  bool get _isObservation => widget.task.taskType == api.TaskType.observation;

  @override
  void dispose() {
    _heightController.dispose();
    _leafCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openQuickReportSheet() async {
    // Mở Quick Report sheet — sheet tự invalidate providers khi submit xong.
    // Sau khi sheet đóng, callback onReportSubmitted sẽ được gọi.
    showApiQuickReportSheet(
      context,
      widget.task,
      onSuccess: widget.onReportSubmitted,
      preloadedImages: _selectedImages,
      onImagesChanged: (imgs) {
        if (mounted) setState(() => _selectedImages = imgs);
      },
    );
  }

  Future<void> _submitObservationForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final resultData = <String, String>{
        'condition': _selectedHealth,
        'plantHeight': _heightController.text.trim(),
        'leafCount': _leafCountController.text.trim(),
        'leafColor': _selectedLeafColor,
        if (_noteController.text.isNotEmpty)
          'additionalNotes': _noteController.text,
      };

      final reportText = _noteController.text.isNotEmpty
          ? _noteController.text
          : 'Chiều cao: ${_heightController.text}cm, Số lá: ${_leafCountController.text}, '
              'Màu: $_selectedLeafColor, Tình trạng: $_selectedHealth';

      final imageParams = _selectedImages
          .map((f) => TaskReportImageParam(
                file: f,
                uploadedAt: DateTime.now(),
              ))
          .toList();

      final params = SubmitParams(
        taskId: widget.task.id,
        reportText: reportText,
        resultData: resultData,
        images: imageParams,
        experimentId: widget.task.experimentId.isEmpty
            ? null
            : widget.task.experimentId,
        batchId: widget.task.batchId,
        markComplete: true,
        hasNewContent: true,
      );

      final outcome = await ref
          .read(taskReportSubmitServiceProvider)
          .submitAndOptionallyComplete(params);

      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(taskReportByTaskProvider(widget.task.id));
      ref.invalidate(taskImagesByTaskProvider(widget.task.id));
      ref.invalidate(myTasksProvider);
      ref.invalidate(myTodayTasksProvider);

      if (!mounted) return;
      _showOutcomeSnack(outcome);

      if (outcome.mode != SubmitMode.error) {
        widget.onReportSubmitted();
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          context,
          message: 'Lỗi gửi báo cáo: $e',
          type: TopSnackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showOutcomeSnack(SubmitOutcome outcome) {
    final type = switch (outcome.mode) {
      SubmitMode.success => TopSnackType.success,
      SubmitMode.partial => TopSnackType.warning,
      SubmitMode.error => TopSnackType.error,
    };
    showTopSnackBar(
      context,
      message: outcome.toUserMessage(),
      type: type,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;
    final typeSpec = getTaskVisualSpec(task.taskType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header cho form
        Row(
          children: [
            Icon(
              _isObservation
                  ? Icons.trending_up_rounded
                  : Icons.edit_note_rounded,
              size: 18,
              color: cs.onSurface.withAlpha(153),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _isObservation
                  ? 'Ghi nhận tăng trưởng'
                  : 'Báo cáo nhanh',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isObservation
              ? 'Nhập các chỉ số quan sát được trên cây. Ảnh và dữ liệu sẽ gửi kèm báo cáo.'
              : 'Điền nhanh các chỉ số cho công việc. Ảnh minh chứng có thể đính kèm.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ─── Form ─────────────────────────────────────────────────────────
        SNMSCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isObservation) ...[
                  _heightField(tt),
                  const SizedBox(height: AppSpacing.md),
                  _leafCountField(tt),
                  const SizedBox(height: AppSpacing.md),
                  _leafColorDropdown(tt),
                  const SizedBox(height: AppSpacing.md),
                  _healthDropdown(tt),
                  const SizedBox(height: AppSpacing.md),
                  _notesField(tt, label: 'Ghi chú quan sát'),
                ],
                if (!_isObservation) ...[
                  // Quick report thường: chỉ cần note + ảnh (form ngắn gọn).
                  _notesField(
                    tt,
                    label: 'Nội dung báo cáo',
                    hint:
                        'VD: Đã tưới 200ml/gốc, cây phát triển tốt, không có sâu bệnh...',
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TaskImagePicker(
                  images: _selectedImages,
                  onImagesChanged: (imgs) =>
                      setState(() => _selectedImages = imgs),
                  isUploading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Action buttons ──────────────────────────────────────────────
        _buildActionButtons(task, typeSpec, tt, cs),
      ],
    );
  }

  Widget _heightField(TextTheme tt) => _buildNumberField(
        controller: _heightController,
        label: 'Chiều cao (cm)',
        hint: 'VD: 25.5',
        suffix: 'cm',
        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
      );

  Widget _leafCountField(TextTheme tt) => _buildNumberField(
        controller: _leafCountController,
        label: 'Số lá',
        hint: 'VD: 8',
        suffix: 'lá',
        isInteger: true,
        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
      );

  Widget _leafColorDropdown(TextTheme tt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Màu lá',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedLeafColor,
            decoration: const InputDecoration(),
            items: _leafColors
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedLeafColor = v ?? _selectedLeafColor),
          ),
        ],
      );

  Widget _healthDropdown(TextTheme tt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tình trạng cây',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedHealth,
            decoration: const InputDecoration(),
            items: _healthStatuses
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedHealth = v ?? _selectedHealth),
          ),
        ],
      );

  Widget _notesField(
    TextTheme tt, {
    required String label,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required String? Function(String?) validator,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint, suffixText: suffix),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    api.TaskModel task,
    TaskVisualSpec typeSpec,
    TextTheme tt,
    ColorScheme cs,
  ) {
    // Status cho phép bắt đầu: pending hoặc overdue (chưa làm hoặc quá hạn).
    final canStart = task.status == api.TaskStatus.pending ||
        task.status == api.TaskStatus.overdue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA — observation ghi nhanh và submit, các task khác mở sheet.
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_isObservation) {
                      _submitObservationForm();
                    } else {
                      _openQuickReportSheet();
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: typeSpec.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isObservation
                        ? Icons.send_rounded
                        : Icons.flash_on_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              _isObservation
                  ? (_isSubmitting ? 'Đang gửi…' : 'Ghi nhận & Hoàn thành')
                  : 'Báo cáo nhanh · ${typeSpec.label}',
              style: tt.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (canStart) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _startTask,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Bắt đầu'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
        if (task.batchId != null && task.batchId!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _startTask() async {
    final taskId = widget.task.id;
    try {
      await ref.read(startTaskProvider(taskId).future);
      ref.invalidate(taskDetailProvider(taskId));
      ref.invalidate(myTasksProvider);
      ref.invalidate(myTodayTasksProvider);
      ref.invalidate(filteredMyTasksProvider);
      ref.invalidate(todayTasksLocalProvider);
      ref.invalidate(overdueTasksLocalProvider);
      if (mounted) {
        showTopSnackBar(
          context,
          message: 'Đã bắt đầu công việc!',
          type: TopSnackType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          context,
          message: 'Lỗi: $e',
          type: TopSnackType.error,
        );
      }
    }
  }
}
