import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/models/measurement_definition_model.dart';
import '../../../../core/api/services/measurement_record_api_service.dart' as measurement_api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/growth_task_model.dart';
import '../../../../features/tasks/providers/measurement_record_providers.dart';

/// Bottom sheet ghi nhận chỉ số tăng trưởng (measurement record).
/// Lấy measurement definitions từ experiment và cho phép nhập value.
Future<void> showQuickMeasurementSheet(BuildContext context, TaskModel task) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickMeasurementSheet(task: task),
  );
}

class _QuickMeasurementSheet extends ConsumerStatefulWidget {
  const _QuickMeasurementSheet({required this.task});
  final TaskModel task;

  @override
  ConsumerState<_QuickMeasurementSheet> createState() => _QuickMeasurementSheetState();
}

class _QuickMeasurementSheetState extends ConsumerState<_QuickMeasurementSheet> {
  final Map<String, TextEditingController> _valueControllers = {};
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;
    final experimentId = task.experimentId;

    if (experimentId.isEmpty) {
      return _wrap(cs, tt, const _ErrorContent(message: 'Task chưa có experimentId, không thể ghi nhận chỉ số.'));
    }

    final defsAsync = ref.watch(measurementDefinitionsProvider(experimentId));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
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
                      color: AppColors.info.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.straighten_rounded, color: AppColors.info, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ghi nhận chỉ số', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(task.taskName, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Nhập giá trị đo được cho từng chỉ số của thí nghiệm',
                        style: tt.bodySmall?.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              defsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorContent(message: 'Lỗi tải chỉ số: $e'),
                data: (defs) {
                  if (defs.isEmpty) {
                    return _ErrorContent(
                      message: 'Thí nghiệm này chưa có chỉ số đo lường. Vui lòng liên hệ Researcher để tạo.',
                    );
                  }
                  return _buildForm(defs, tt, cs);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrap(ColorScheme cs, TextTheme tt, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }

  Widget _buildForm(List<MeasurementDefinitionModel> defs, TextTheme tt, ColorScheme cs) {
    for (final d in defs) {
      _valueControllers.putIfAbsent(d.id, () => TextEditingController());
    }

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...defs.map((d) => _buildField(d, tt, cs)),
          const SizedBox(height: AppSpacing.lg),
          Text('Ghi chú (tùy chọn)', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú...',
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
                  onPressed: _isSubmitting ? null : () => _submit(defs),
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu chỉ số'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs) {
    final controller = _valueControllers[d.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.metricName, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              ),
              if (d.targetValue != null)
                Text(
                  'Mục tiêu: ${d.targetValue} ${d.unit ?? ''}',
                  style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Nhập giá trị...',
              suffixText: d.unit ?? '',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withAlpha(128),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập' : null,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(List<MeasurementDefinitionModel> defs) async {
    final task = widget.task;
    if (task.batchId == null || task.batchId!.isEmpty || task.stageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task chưa có batchId/stageId, không thể ghi nhận.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final entries = <_Entry>[];
    for (final d in defs) {
      final c = _valueControllers[d.id];
      final v = c?.text.trim() ?? '';
      if (v.isEmpty) continue;
      final num = double.tryParse(v.replaceAll(',', '.'));
      if (num == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${d.metricName}" không phải số hợp lệ'), backgroundColor: AppColors.error),
        );
        return;
      }
      entries.add(_Entry(def: d, value: num));
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ít nhất 1 chỉ số'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final note = _noteController.text.trim();
      for (final e in entries) {
        final dto = measurement_api.CreateMeasurementDto(
          experimentId: task.experimentId,
          experimentStageId: task.stageId!,
          batchId: task.batchId!,
          measurementDefinitionId: e.def.id,
          value: e.value,
          textValue: note.isNotEmpty ? note : null,
          measuredAt: DateTime.now(),
        );
        await ref.read(createMeasurementRecordProvider(dto).future);
      }
      ref.invalidate(measurementRecordsByBatchProvider(task.batchId!));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu ${entries.length} chỉ số thành công!'),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _Entry {
  final MeasurementDefinitionModel def;
  final double value;
  _Entry({required this.def, required this.value});
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: cs.onSurface.withAlpha(102)),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}