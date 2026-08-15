import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/models/measurement_definition_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/growth_task_model.dart';
import '../../../../features/tasks/data/measurement_bridge.dart';
import '../../../tasks/data/task_report_submit_service.dart';
import '../../../tasks/providers/measurement_batch_providers.dart';
import '../../../tasks/providers/measurement_record_providers.dart';

/// Bottom sheet ghi nhận chỉ số dùng [BridgeOutput] mới (bulk path).
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
  ConsumerState<_QuickMeasurementSheet> createState() =>
      _QuickMeasurementSheetState();
}

class _QuickMeasurementSheetState
    extends ConsumerState<_QuickMeasurementSheet> {
  final Map<String, TextEditingController> _valueControllers = {};
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _activeError;

  @override
  void dispose() {
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  List<MeasurementDefinitionModel> _watchEffectiveDefs() {
    final raw =
        ref.watch(measurementDefinitionsProvider(widget.task.experimentId));
    final effective = ref.watch(
      effectiveMeasurementDefinitionsProvider(
        EffectiveDefinitionsParam(
          definitions: raw.value ?? const [],
          experimentId: widget.task.experimentId,
          taskId: widget.task.id,
          batchId: widget.task.batchId,
        ),
      ),
    );
    return effective.value ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;

    if (task.experimentId.isEmpty) {
      return _wrap(cs, tt,
          const _ErrorContent(message: 'Task chưa có experimentId.'));
    }

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
                  width: 40, height: 4,
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
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.straighten_rounded,
                        color: AppColors.info, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ghi nhận chỉ số',
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(task.taskName,
                            style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Nhập giá trị đo được cho từng chỉ số của nhóm ${task.batchCode ?? ''}',
                        style: tt.bodySmall?.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Builder(builder: (context) {
                final defs = _watchEffectiveDefs();
                if (defs.isEmpty) {
                  return const _ErrorContent(
                    message:
                        'Thí nghiệm này chưa có chỉ số, hoặc không tìm thấy chỉ số cho nhóm batch của task.',
                  );
                }
                return _buildForm(defs, tt, cs);
              }),
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

  Widget _buildForm(
      List<MeasurementDefinitionModel> defs, TextTheme tt, ColorScheme cs) {
    for (final d in defs) {
      _valueControllers.putIfAbsent(d.id, () => TextEditingController());
    }

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...defs.map((d) => _buildField(d, tt, cs)),
          const SizedBox(height: AppSpacing.lg),
          Text('Ghi chú (tùy chọn)',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Điều kiện đo, thời tiết...',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_activeError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorBanner(message: _activeError!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Huỷ'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : () => _submit(defs),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                        )
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

  Widget _buildField(
      MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs) {
    final controller = _valueControllers[d.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.metricName,
                    style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              ),
              if (d.targetValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mục tiêu: ${d.targetValue} ${d.unit ?? ''}',
                    style: tt.labelSmall?.copyWith(color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final err = localValidateValue(d, value.text);
              final status = getValueStatus(d, value.text);
              return TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nhập giá trị...',
                  suffixText: d.unit ?? '',
                  errorText: err,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(128),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _statusIcon(status),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget? _statusIcon(ValueStatus status) {
    switch (status) {
      case ValueStatus.exceeded:
        return const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        );
      case ValueStatus.close:
        return const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
        );
      case ValueStatus.below:
        return const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
        );
      case ValueStatus.ok:
      case ValueStatus.unknown:
        return null;
    }
  }

  Future<void> _submit(List<MeasurementDefinitionModel> defs) async {
    final task = widget.task;
    if (task.batchId == null || task.batchId!.isEmpty || task.stageId == null) {
      setState(() {
        _activeError = 'Task chưa có batchId/stageId, không thể ghi nhận.';
        _isSubmitting = false;
      });
      return;
    }

    final resultData = <String, String>{};
    String? firstErr;
    for (final d in defs) {
      final c = _valueControllers[d.id];
      final v = c?.text.trim() ?? '';
      if (v.isEmpty) continue;
      final err = localValidateValue(d, v);
      if (err != null) {
        firstErr ??= err;
        continue;
      }
      resultData['def_${d.id}'] = v;
    }

    if (resultData.isEmpty) {
      setState(() {
        _activeError = firstErr ?? 'Vui lòng nhập ít nhất 1 chỉ số';
        _isSubmitting = false;
      });
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final note = _noteController.text.trim();
      final taskCtx = TaskGroupContext(
        experimentId: task.experimentId.isEmpty ? null : task.experimentId,
        experimentStageId: task.stageId,
        batchId: task.batchId,
        taskType: null,
      );
      final bridge = buildBridgeOutput(
        task: taskCtx,
        resultData: resultData,
        effectiveDefinitions: defs,
        meta: BridgeExtraMeta(notes: note),
      );

      final params = SubmitParams(
        taskId: task.id,
        reportText: note.isNotEmpty
            ? 'Đã ghi nhận ${bridge.bulk?.items.length ?? 0} chỉ số. $note'
            : 'Đã ghi nhận ${bridge.bulk?.items.length ?? 0} chỉ số.',
        resultData: resultData,
        images: const [],
        experimentId: task.experimentId.isEmpty ? null : task.experimentId,
        batchId: task.batchId,
        effectiveDefinitions: defs,
        bridgeOutput: bridge,
        markComplete: false,
        hasNewContent: true,
      );
      final outcome =
          await ref.read(taskReportSubmitServiceProvider).submitAndOptionallyComplete(params);

      ref.invalidate(measurementRecordsByBatchProvider(task.batchId ?? ''));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(outcome.toUserMessage()),
            backgroundColor: outcome.mode == SubmitMode.error
                ? AppColors.error
                : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _activeError = '$e';
        });
      }
    }
  }
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
          Text(message,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: tt.bodySmall?.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
