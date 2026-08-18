import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/measurement_definition_model.dart';
import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/snms_card.dart';
import '../../../../shared/widgets/top_snackbar.dart';
import '../../../tasks/data/measurement_bridge.dart';
import '../../../tasks/data/task_report_submit_service.dart';
import '../../../tasks/presentation/widgets/task_image_picker.dart';
import '../../../tasks/presentation/widgets/task_visual.dart';
import '../../../tasks/providers/measurement_batch_providers.dart';
import '../../../tasks/providers/measurement_record_providers.dart';
import '../../../tasks/providers/my_tasks_provider.dart';
import '../../../tasks/providers/task_providers.dart';

/// Panel action chính cho Student task detail.
///
/// Sử dụng dynamic measurement definitions từ BE để render form động:
///   - **number** → TextField số với validation
///   - **select/multiSelect** → Chip selection
///   - **text** → Multiline text input
///
/// Sau khi submit, tạo TaskReport + MeasurementRecords + TaskImages.
class TaskReportActionPanel extends ConsumerStatefulWidget {
  const TaskReportActionPanel({
    super.key,
    required this.task,
    required this.onReportSubmitted,
  });

  final api.TaskModel task;

  /// Callback khi submit thành công.
  final VoidCallback onReportSubmitted;

  @override
  ConsumerState<TaskReportActionPanel> createState() =>
      _TaskReportActionPanelState();
}

class _TaskReportActionPanelState
    extends ConsumerState<TaskReportActionPanel> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasStarted = false; // Nghiệp vụ: phải bắt đầu trước khi báo cáo
  List<File> _selectedImages = [];

  // Dynamic field controllers
  final Map<String, TextEditingController> _valueControllers = {};
  final Map<String, String?> _selectedValues = {};

  @override
  void dispose() {
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  List<MeasurementDefinitionModel> _watchEffectiveDefs() {
    if (widget.task.experimentId.isEmpty) {
      debugPrint('[DEBUG] Task has no experimentId, taskId=${widget.task.id}');
      return const [];
    }
    debugPrint('[DEBUG] Loading definitions for experimentId=${widget.task.experimentId}');
    
    // Watch batch info to get groupId for filtering
    final batchInfo = widget.task.batchId != null && widget.task.batchId!.isNotEmpty
        ? ref.watch(batchInfoProvider(widget.task.batchId!))
        : const AsyncValue<BatchGroupInfoWithCode?>.data(null);
    
    // Debug batch state
    if (batchInfo.isLoading) {
      debugPrint('[DEBUG] Batch info is loading...');
    } else if (batchInfo.hasError) {
      debugPrint('[DEBUG] Batch info error: ${batchInfo.error}');
    } else if (batchInfo.hasValue) {
      debugPrint('[DEBUG] Batch info: groupId=${batchInfo.value?.groupId}, groupName=${batchInfo.value?.groupName}');
    }
    
    final groupId = batchInfo.valueOrNull?.groupId;
    
    final raw = ref.watch(
        measurementDefinitionsProvider(widget.task.experimentId));
    
    // Log raw state
    debugPrint('[DEBUG] Definitions AsyncValue hasValue=${raw.hasValue}, hasError=${raw.hasError}');
    if (raw.hasValue) {
      debugPrint('[DEBUG] Got ${raw.value?.length ?? 0} definitions from API');
    }
    if (raw.hasError) {
      debugPrint('[DEBUG] Error loading definitions: ${raw.error}');
    }
    
    if (raw.value == null || raw.value!.isEmpty) {
      debugPrint('[DEBUG] No raw definitions, returning empty');
      return const [];
    }
    
    // Build TaskGroupContext với groupId từ batch
    final ctx = TaskGroupContext(
      experimentId: widget.task.experimentId,
      experimentStageId: null,
      batchId: widget.task.batchId,
      batchGroupId: groupId,
    );
    
    debugPrint('[DEBUG] Calling filterDefinitionsByTaskGroup with groupId=$groupId');
    debugPrint('[DEBUG] Raw definitions before filter: ${raw.value!.length}');
    for (final d in raw.value!) {
      debugPrint('[DEBUG]   RAW: ${d.id} (${d.metricName}, groupId=${d.groupId})');
    }
    
    final filtered = filterDefinitionsByTaskGroup(
      raw.value!,
      ctx,
      explicitGroupId: groupId,
    );
    
    debugPrint('[DEBUG] Filtered definitions count: ${filtered.length}');
    for (final d in filtered) {
      debugPrint('[DEBUG]   FILTERED: ${d.metricName} (groupId=${d.groupId}, target=${d.targetValue})');
    }
    
    return filtered;
  }

  void _initControllers(List<MeasurementDefinitionModel> defs) {
    for (final d in defs) {
      _valueControllers.putIfAbsent(d.id, () => TextEditingController());
      _selectedValues.putIfAbsent(d.id, () => null);
    }
  }

  Future<void> _submitDynamicForm(List<MeasurementDefinitionModel> defs) async {
    if (!_formKey.currentState!.validate()) return;

    // Nghiệp vụ: Phải bắt đầu trước khi báo cáo
    if (!_hasStarted) {
      showTopSnackBar(
        context,
        message: 'Vui lòng nhấn "Bắt đầu" trước khi ghi nhận chỉ số.',
        type: TopSnackType.warning,
      );
      return;
    }

    if (widget.task.batchId == null || widget.task.batchId!.isEmpty) {
      showTopSnackBar(
        context,
        message: 'Task chưa có batchId, không thể ghi nhận.',
        type: TopSnackType.error,
      );
      return;
    }

    // Validate all fields
    final unfilled = <String>[];
    final resultData = <String, String>{};

    for (final d in defs) {
      String value;
      if (d.isChoiceField) {
        value = _selectedValues[d.id] ?? '';
      } else {
        value = _valueControllers[d.id]?.text.trim() ?? '';
      }

      if (value.isEmpty) {
        unfilled.add(d.metricName);
        continue;
      }

      // Validate number fields với business rules
      if (d.fieldType == MeasurementFieldType.number) {
        final err = localValidateValue(d, value);
        if (err != null) {
          unfilled.add('${d.metricName}: $err');
          continue;
        }
      }

      resultData['def_${d.id}'] = value;
    }

    if (unfilled.isNotEmpty) {
      showTopSnackBar(
        context,
        message: 'Vui lòng nhập đầy đủ: ${unfilled.join(", ")}',
        type: TopSnackType.warning,
      );
      return;
    }

    if (resultData.isEmpty) {
      showTopSnackBar(
        context,
        message: 'Vui lòng nhập ít nhất 1 chỉ số',
        type: TopSnackType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final note = _noteController.text.trim();
      final taskCtx = TaskGroupContext(
        experimentId: widget.task.experimentId.isEmpty
            ? null
            : widget.task.experimentId,
        experimentStageId: widget.task.experimentStageId,
        batchId: widget.task.batchId,
        taskType: widget.task.taskType, // Lấy từ task thực tế
      );

      final bridge = buildBridgeOutput(
        task: taskCtx,
        resultData: resultData,
        effectiveDefinitions: defs,
        meta: BridgeExtraMeta(notes: note),
      );

      final reportText = note.isNotEmpty
          ? 'Đã ghi nhận ${bridge.bulk?.items.length ?? 0} chỉ số. $note'
          : 'Đã ghi nhận ${bridge.bulk?.items.length ?? 0} chỉ số.';

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
        effectiveDefinitions: defs,
        bridgeOutput: bridge,
        markComplete: true,
        hasNewContent: true,
      );

      final outcome = await ref
          .read(taskReportSubmitServiceProvider)
          .submitAndOptionallyComplete(params);

      _invalidateProviders();

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

  void _invalidateProviders() {
    ref.invalidate(taskDetailProvider(widget.task.id));
    ref.invalidate(taskReportByTaskProvider(widget.task.id));
    ref.invalidate(taskImagesByTaskProvider(widget.task.id));
    ref.invalidate(myTasksProvider);
    ref.invalidate(todayTasksApiProvider);
    ref.invalidate(upcomingTasksApiProvider);
    ref.invalidate(overdueTasksApiProvider);
    ref.invalidate(completedTasksApiProvider);
    ref.invalidate(reportedTaskIdsProvider);
    if (widget.task.batchId != null) {
      ref.invalidate(measurementRecordsByBatchProvider(widget.task.batchId!));
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
    final defs = _watchEffectiveDefs();

    // Initialize controllers when defs change
    _initControllers(defs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 18,
              color: cs.onSurface.withAlpha(153),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ghi nhận tăng trưởng',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nhập các chỉ số quan sát được. Ảnh và dữ liệu sẽ gửi kèm báo cáo.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Form
        SNMSCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic fields from measurement definitions
                if (defs.isEmpty)
                  _buildEmptyState(tt, cs)
                else
                  ...defs.map((d) => _buildDynamicField(d, tt, cs)),

                if (defs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildNotesField(tt, cs),
                  const SizedBox(height: AppSpacing.md),
                  TaskImagePicker(
                    images: _selectedImages,
                    onImagesChanged: (imgs) =>
                        setState(() => _selectedImages = imgs),
                    isUploading: _isSubmitting,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Action buttons
        _buildActionButtons(task, typeSpec, tt, cs, defs),
      ],
    );
  }

  Widget _buildEmptyState(TextTheme tt, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.science_outlined,
            size: 40,
            color: cs.onSurface.withAlpha(102),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Thí nghiệm chưa có chỉ số đo lường',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vui lòng thêm measurement definitions từ BE',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withAlpha(102),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNotesField(tt, cs),
        ],
      ),
    );
  }

  Widget _buildDynamicField(
      MeasurementDefinitionModel d, TextTheme tt, ColorScheme cs) {
    switch (d.fieldType) {
      case MeasurementFieldType.select:
        return _buildSelectField(d, tt, cs);
      case MeasurementFieldType.multiSelect:
        return _buildMultiSelectField(d, tt, cs);
      case MeasurementFieldType.text:
        return _buildTextField(d, tt, cs);
      case MeasurementFieldType.number:
        return _buildNumberField(d, tt, cs);
    }
  }

  Widget _buildNumberField(
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
              return TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                      color: isSelected ? Colors.white : cs.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
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
    final selectedSet =
        (_selectedValues[d.id] ?? '').split(',').where((e) => e.isNotEmpty).toSet();
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
                          color: isSelected ? Colors.white : cs.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ghi chú quan sát',
            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Điều kiện đo, thời tiết, ghi chú thêm...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withAlpha(128),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    api.TaskModel task,
    TaskVisualSpec typeSpec,
    TextTheme tt,
    ColorScheme cs,
    List<MeasurementDefinitionModel> defs,
  ) {
    final canStart = task.status == api.TaskStatus.pending ||
        task.status == api.TaskStatus.overdue;
    final hasDefinitions = defs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (hasDefinitions) {
                      _submitDynamicForm(defs);
                    } else {
                      _submitQuickNote();
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
                    hasDefinitions
                        ? Icons.send_rounded
                        : Icons.edit_note_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              hasDefinitions
                  ? (_isSubmitting ? 'Đang gửi…' : 'Ghi nhận & Hoàn thành')
                  : 'Gửi báo cáo',
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

  Future<void> _submitQuickNote() async {
    // Nghiệp vụ: Phải bắt đầu trước khi báo cáo
    if (!_hasStarted) {
      showTopSnackBar(
        context,
        message: 'Vui lòng nhấn "Bắt đầu" trước khi gửi báo cáo.',
        type: TopSnackType.warning,
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      showTopSnackBar(
        context,
        message: 'Vui lòng nhập nội dung báo cáo',
        type: TopSnackType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imageParams = _selectedImages
          .map((f) => TaskReportImageParam(
                file: f,
                uploadedAt: DateTime.now(),
              ))
          .toList();

      final params = SubmitParams(
        taskId: widget.task.id,
        reportText: note,
        resultData: const {},
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

      _invalidateProviders();

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

  Future<void> _startTask() async {
    final taskId = widget.task.id;
    try {
      await ref.read(startTaskProvider(taskId).future);
      ref.invalidate(taskDetailProvider(taskId));
      ref.invalidate(myTasksProvider);
      ref.invalidate(todayTasksApiProvider);
      ref.invalidate(upcomingTasksApiProvider);
      ref.invalidate(overdueTasksApiProvider);
      ref.invalidate(completedTasksApiProvider);
      ref.invalidate(filteredMyTasksProvider);
      ref.invalidate(todayTasksLocalProvider);
      ref.invalidate(overdueTasksLocalProvider);
      if (mounted) {
        setState(() => _hasStarted = true); // Đánh dấu đã bắt đầu
        showTopSnackBar(
          context,
          message: 'Đã bắt đầu công việc! Giờ có thể ghi nhận chỉ số.',
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
