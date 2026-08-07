import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/models/task_report_model.dart' as report_model;
import '../../../../core/api/services/task_report_api_service.dart' as report_api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/growth_task_model.dart';
import '../../../../features/tasks/providers/task_providers.dart';
import '../../../../features/tasks/providers/task_report_providers.dart' as report_providers;

/// Hiển thị bottom sheet báo cáo nhanh cho một task.
/// Mỗi [TaskType] sẽ hiện form phù hợp (tưới nước, bón phân, trồng cây, kiểm tra, thu hoạch, quan sát).
Future<void> showQuickReportSheet(BuildContext context, TaskModel task) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickReportSheet(task: task),
  );
}

class _QuickReportSheet extends ConsumerStatefulWidget {
  const _QuickReportSheet({required this.task});
  final TaskModel task;

  @override
  ConsumerState<_QuickReportSheet> createState() => _QuickReportSheetState();
}

class _QuickReportSheetState extends ConsumerState<_QuickReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  // Watering / Fertilizing / Inspection
  final _amountController = TextEditingController();
  final _plantsController = TextEditingController();

  // Observation
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  String _selectedHealth = 'Tốt';
  String _selectedLeafColor = 'Xanh đậm';

  // Inspection
  final _inspectedDevicesController = TextEditingController();

  // Harvest
  final _harvestedController = TextEditingController();
  final _harvestWeightController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    _plantsController.dispose();
    _heightController.dispose();
    _leafCountController.dispose();
    _inspectedDevicesController.dispose();
    _harvestedController.dispose();
    _harvestWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Báo cáo nhanh', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(task.taskName, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildFieldsForTaskType(task.taskType, tt, cs),
                const SizedBox(height: AppSpacing.lg),
                Text('Ghi chú thêm', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú (nếu có)...',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withAlpha(128),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi báo cáo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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

  Widget _buildFieldsForTaskType(TaskType type, TextTheme tt, ColorScheme cs) {
    return switch (type) {
      TaskType.watering => _buildWateringFields(tt, cs),
      TaskType.fertilizing => _buildFertilizingFields(tt, cs),
      TaskType.planting => _buildPlantingFields(tt, cs),
      TaskType.observation => _buildObservationFields(tt, cs),
      TaskType.inspection => _buildInspectionFields(tt, cs),
      TaskType.other => _buildOtherFields(tt, cs),
    };
  }
  Widget _numField(TextEditingController c, String label, String hint, String suffix, {bool allowDecimal = false}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withAlpha(128),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập' : null,
        ),
      ],
    );
  }

  Widget _buildWateringFields(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _numField(_plantsController, 'Số cây đã tưới', 'VD: 50', 'cây')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _numField(_amountController, 'Lượng nước', 'VD: 500', 'ml')),
          ],
        ),
      ],
    );
  }

  Widget _buildFertilizingFields(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _numField(_plantsController, 'Số cây đã bón', 'VD: 50', 'cây')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _numField(_amountController, 'Lượng phân', 'VD: 100', 'g')),
          ],
        ),
      ],
    );
  }

  Widget _buildPlantingFields(TextTheme tt, ColorScheme cs) {
    return _numField(_plantsController, 'Số cây đã trồng', 'VD: 30', 'cây');
  }

  Widget _buildObservationFields(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _numField(_heightController, 'Chiều cao', 'VD: 25.5', 'cm', allowDecimal: true)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _numField(_leafCountController, 'Số lá', 'VD: 8', 'lá')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Tình trạng cây', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: ['Tốt', 'Trung bình', 'Yếu', 'Có dấu hiệu bệnh'].map((e) => _chip(e, _selectedHealth, (v) => setState(() => _selectedHealth = v))).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Màu sắc lá', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: ['Xanh đậm', 'Xanh nhạt', 'Vàng', 'Có đốm'].map((e) => _chip(e, _selectedLeafColor, (v) => setState(() => _selectedLeafColor = v))).toList(),
        ),
      ],
    );
  }

  Widget _buildInspectionFields(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thiết bị / vùng kiểm tra', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _inspectedDevicesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'VD: Cảm biến SHT-01, vùng A1...',
            filled: true,
            fillColor: cs.surfaceContainerHighest.withAlpha(128),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Tình trạng', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: ['Tốt', 'Cần bảo trì', 'Hỏng'].map((e) => _chip(e, _selectedHealth, (v) => setState(() => _selectedHealth = v))).toList(),
        ),
      ],
    );
  }

  Widget _buildHarvestFields(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _numField(_harvestedController, 'Sản phẩm thu hoạch', 'VD: 50', 'trái/kg')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _numField(_harvestWeightController, 'Khối lượng', 'VD: 12.5', 'kg', allowDecimal: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherFields(TextTheme tt, ColorScheme cs) {
    return const SizedBox.shrink();
  }

  Widget _chip(String label, String selected, ValueChanged<String> onTap) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSelected = label == selected;
    return InkWell(
      onTap: () => onTap(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.success.withAlpha(25) : cs.surfaceContainerHighest.withAlpha(128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.success : Colors.transparent, width: 1),
        ),
        child: Text(label, style: tt.labelMedium?.copyWith(color: isSelected ? AppColors.success : cs.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  String _buildReportText() {
    final task = widget.task;
    final note = _noteController.text.trim();
    return switch (task.taskType) {
      TaskType.watering => 'Đã tưới ${_plantsController.text} cây với ${_amountController.text}ml nước.${note.isNotEmpty ? ' $note' : ''}',
      TaskType.fertilizing => 'Đã bón phân cho ${_plantsController.text} cây với ${_amountController.text}g.${note.isNotEmpty ? ' $note' : ''}',
      TaskType.planting => 'Đã trồng ${_plantsController.text} cây.${note.isNotEmpty ? ' $note' : ''}',
      TaskType.observation => 'Chiều cao: ${_heightController.text}cm, số lá: ${_leafCountController.text}, màu sắc: $_selectedLeafColor, tình trạng: $_selectedHealth.${note.isNotEmpty ? ' $note' : ''}',
      TaskType.inspection => 'Đã kiểm tra ${_inspectedDevicesController.text}. Tình trạng: $_selectedHealth.${note.isNotEmpty ? ' $note' : ''}',
      TaskType.other => note.isEmpty ? 'Đã hoàn thành công việc.' : note,
    };
  }

  report_model.ReportResultData _buildResultData() {
    final task = widget.task;
    final note = _noteController.text.trim();
    return switch (task.taskType) {
      TaskType.watering => report_model.ReportResultData(
          plantsWatered: int.tryParse(_plantsController.text),
          waterAmount: '${_amountController.text}ml',
          condition: 'Tốt',
          additionalNotes: note,
        ),
      TaskType.fertilizing => report_model.ReportResultData(
          plantsWatered: int.tryParse(_plantsController.text),
          waterAmount: '${_amountController.text}g',
          condition: 'Đã bón xong',
          additionalNotes: note,
        ),
      TaskType.planting => report_model.ReportResultData(
          plantsWatered: int.tryParse(_plantsController.text),
          additionalNotes: note,
        ),
      TaskType.observation => report_model.ReportResultData(
          condition: _selectedHealth,
          additionalNotes: note.isNotEmpty ? note : 'Màu sắc lá: $_selectedLeafColor',
        ),
      TaskType.inspection => report_model.ReportResultData(
          action: 'Đã kiểm tra: ${_inspectedDevicesController.text}. Tình trạng: $_selectedHealth',
          additionalNotes: note,
        ),
      TaskType.other => report_model.ReportResultData(additionalNotes: note),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final dto = report_api.CreateTaskReportDto(
        taskId: widget.task.id,
        reportText: _buildReportText(),
        resultData: _buildResultData(),
      );
      await ref.read(report_providers.submitReportProvider(dto).future);
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(taskReportByTaskProvider(widget.task.id));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo đã được gửi!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = e.toString();
        final friendly = msg.contains('da co report') || msg.contains('đã có report')
            ? 'Task này đã có báo cáo rồi. Mỗi task chỉ được gửi 1 báo cáo.'
            : 'Gửi báo cáo thất bại: ${msg.length > 120 ? '${msg.substring(0, 120)}…' : msg}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendly),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}