import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  final Map<String, String?> _selectedValues = {}; // For select/multiSelect
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _activeError;

  // Image capture
  final List<File> _capturedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

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
          // Image capture section
          _buildImageCaptureSection(tt, cs),
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

    switch (d.fieldType) {
      case MeasurementFieldType.select:
        return _buildSelectField(d, tt, cs);
      case MeasurementFieldType.multiSelect:
        return _buildMultiSelectField(d, tt, cs);
      case MeasurementFieldType.text:
        return _buildTextField(d, tt, cs);
      case MeasurementFieldType.number:
        return _buildNumberField(d, tt, cs, controller);
    }
  }

  Widget _buildNumberField(
      MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs, TextEditingController controller) {
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

  Widget _buildTextField(
      MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs) {
    final controller = _valueControllers[d.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.metricName,
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: d.description ?? 'Nhập thông tin...',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectField(
      MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs) {
    final selected = _selectedValues[d.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.metricName,
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          if (d.description != null) ...[
            const SizedBox(height: 2),
            Text(d.description!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withAlpha(128),
                )),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: d.options.map((opt) {
              final isSelected = selected == opt.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedValues[d.id] = opt.value;
                    _valueControllers[d.id]?.text = opt.label;
                  });
                },
                child: Semantics(
                  label: opt.label,
                  selected: isSelected,
                  button: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : cs.surfaceContainerHighest.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : cs.outline.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: tt.labelMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : cs.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectField(
      MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs) {
    final selectedSet = (_selectedValues[d.id] ?? '').split(',').where((e) => e.isNotEmpty).toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(d.metricName,
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '${selectedSet.length} đã chọn',
                style: tt.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          if (d.description != null) ...[
            const SizedBox(height: 2),
            Text(d.description!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withAlpha(128),
                )),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: d.options.map((opt) {
              final isSelected = selectedSet.contains(opt.value);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final newSet = Set<String>.from(selectedSet);
                    if (isSelected) {
                      newSet.remove(opt.value);
                    } else {
                      newSet.add(opt.value);
                    }
                    _selectedValues[d.id] = newSet.join(',');
                    _valueControllers[d.id]?.text = newSet.map((v) {
                      return d.options.firstWhere(
                        (o) => o.value == v,
                        orElse: () => MeasurementOption(value: v, label: v),
                      ).label;
                    }).join(', ');
                  });
                },
                child: Semantics(
                  label: opt.label,
                  selected: isSelected,
                  button: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : cs.surfaceContainerHighest.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : cs.outline.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          opt.label,
                          style: tt.labelMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : cs.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCaptureSection(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Hình ảnh',
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: AppSpacing.sm),
            Text('(tùy chọn)',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(128),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(60),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          color: AppColors.primary, size: 28),
                      const SizedBox(height: 4),
                      Text('Chụp ảnh',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ),
              ),
              // Captured images
              ..._capturedImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(idx),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _captureImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _capturedImages.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chụp ảnh: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
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
      String v;

      // Handle different field types
      if (d.isChoiceField) {
        // For select/multiSelect: use the raw value from _selectedValues
        v = _selectedValues[d.id] ?? '';
      } else {
        // For number/text: use the text controller
        v = _valueControllers[d.id]?.text.trim() ?? '';
      }

      if (v.isEmpty) continue;

      // Validate number fields only
      if (d.fieldType == MeasurementFieldType.number) {
        final err = localValidateValue(d, v);
        if (err != null) {
          firstErr ??= err;
          continue;
        }
      }

      resultData['def_${d.id}'] = v;
    }

    // Build image params from captured files
    final imageParams = _capturedImages.map((f) => TaskReportImageParam(
      file: f,
      uploadedAt: DateTime.now(),
    )).toList();

    // Validate: check if all required fields are filled
    final unfilledRequired = defs.where((d) {
      String value;
      if (d.isChoiceField) {
        value = _selectedValues[d.id] ?? '';
      } else {
        value = _valueControllers[d.id]?.text.trim() ?? '';
      }
      return value.isEmpty; // Required field is empty
    }).toList();

    if (unfilledRequired.isNotEmpty) {
      final names = unfilledRequired.map((d) => d.metricName).join(', ');
      setState(() {
        _activeError = 'Vui lòng nhập đầy đủ: $names';
        _isSubmitting = false;
      });
      return;
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
        images: imageParams,
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
