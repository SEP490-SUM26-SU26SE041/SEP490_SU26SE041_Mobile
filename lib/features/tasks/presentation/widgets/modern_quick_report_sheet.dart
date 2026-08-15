import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/models/measurement_definition_model.dart';
import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/growth_task_model.dart' as internal;
import '../../../../shared/widgets/top_snackbar.dart';
import '../../../tasks/data/measurement_bridge.dart';
import '../../../tasks/data/task_report_constants.dart';
import '../../../tasks/data/task_report_submit_service.dart';
import '../../../tasks/presentation/widgets/task_image_picker.dart';
import '../../../tasks/presentation/widgets/task_visual.dart';
import '../../../tasks/providers/measurement_batch_providers.dart';
import '../../../tasks/providers/measurement_record_providers.dart';
import '../../../tasks/providers/my_tasks_provider.dart';
import '../../../tasks/providers/task_providers.dart';

/// Entry point cho Quick Report bottom sheet — dùng từ TaskCard / TaskDetail.
Future<void> showQuickReportSheet(BuildContext context, internal.TaskModel task) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => _QuickReportSheet(
      task: _ProxyTask(task),
    ),
  );
}

/// Public version dùng `api.TaskModel` cho các luồng cần API task thuần.
Future<void> showApiQuickReportSheet(
  BuildContext context,
  api.TaskModel task, {
  VoidCallback? onSuccess,
  List<File> preloadedImages = const [],
  void Function(List<File>)? onImagesChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _QuickReportSheet(
      task: _ApiTaskAdapter(task),
      onSuccess: onSuccess,
      preloadedImages: preloadedImages,
      onImagesChanged: onImagesChanged,
    ),
  );
}

/// Adapter chung — chấp nhận cả internal & api task.
abstract class _TaskAdapter {
  String get id;
  String get title;
  api.TaskType get taskType;
  String get experimentId;
  String get batchId;
  String? get batchCode;
  String? get experimentCode;
  String? get experimentStageName;
  String? get experimentTitle;
  DateTime? get dueDate;
  String? get description;
}

class _ProxyTask implements _TaskAdapter {
  _ProxyTask(this.task);
  final internal.TaskModel task;

  @override
  String get id => task.id;
  @override
  String get title => task.taskName;
  @override
  api.TaskType get taskType {
    return switch (task.taskType) {
      internal.TaskType.planting => api.TaskType.planting,
      internal.TaskType.watering => api.TaskType.watering,
      internal.TaskType.fertilizing => api.TaskType.fertilizing,
      internal.TaskType.observation => api.TaskType.observation,
      internal.TaskType.inspection => api.TaskType.inspection,
      internal.TaskType.other => api.TaskType.other,
    };
  }

  @override
  String get experimentId => task.experimentId;
  @override
  String get batchId => task.batchId ?? '';
  @override
  String? get batchCode => task.batchCode;
  @override
  String? get experimentCode => task.experimentCode;
  @override
  String? get experimentStageName => task.experimentStageName;
  @override
  String? get experimentTitle => task.experimentTitle;
  @override
  DateTime? get dueDate => task.dueDate;
  @override
  String? get description => task.description;
}

class _ApiTaskAdapter implements _TaskAdapter {
  _ApiTaskAdapter(this.task);
  final api.TaskModel task;

  @override
  String get id => task.id;
  @override
  String get title => task.title;
  @override
  api.TaskType get taskType => task.taskType;
  @override
  String get experimentId => task.experimentId;
  @override
  String get batchId => task.batchId ?? '';
  @override
  String? get batchCode => task.batchCode;
  @override
  String? get experimentCode => task.experimentCode;
  @override
  String? get experimentStageName => task.experimentStageName;
  @override
  String? get experimentTitle => task.experimentTitle;
  @override
  DateTime? get dueDate => task.dueDate;
  @override
  String? get description => task.description;
}

class _QuickReportSheet extends ConsumerStatefulWidget {
  const _QuickReportSheet({
    required this.task,
    this.onSuccess,
    this.preloadedImages = const [],
    this.onImagesChanged,
  });
  final _TaskAdapter task;
  final VoidCallback? onSuccess;
  final List<File> preloadedImages;
  final void Function(List<File>)? onImagesChanged;

  @override
  ConsumerState<_QuickReportSheet> createState() => _QuickReportSheetState();
}

class _QuickReportSheetState extends ConsumerState<_QuickReportSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  final Map<String, TextEditingController> _defControllers = {};
  final Map<String, TextEditingController> _customControllers = {};

  bool _isSubmitting = false;
  int _filledCount = 0;

  /// Ảnh đính kèm từ parent (đã chọn sẵn trước khi mở sheet).
  late List<File> _selectedImages;

  late final List<_CustomField> _customFields;

  @override
  void initState() {
    super.initState();
    _selectedImages = List<File>.from(widget.preloadedImages);
    _customFields = [
      _CustomField(key: 'custom_1', label: 'Ghi chú thêm', value: ''),
    ];
    _noteController.addListener(_recomputeFilled);
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final c in _defControllers.values) {
      c.dispose();
    }
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _recomputeFilled() {
    int n = 0;
    for (final c in _defControllers.values) {
      if (c.text.trim().isNotEmpty) n++;
    }
    for (final c in _customControllers.values) {
      if (c.text.trim().isNotEmpty) n++;
    }
    if (_noteController.text.trim().isNotEmpty) n++;
    if (n != _filledCount) setState(() => _filledCount = n);
  }

  QuickFormSchema? get _schema => kQuickFormSchema[widget.task.taskType];
  bool get _isDynamic => _schema?.isDynamic ?? false;

  /// Dynamic definitions for Measurement/Observation tasks (filtered by batch group).
  /// Trả về:
  /// - `null` khi đang tải (loading)
  /// - list (rỗng) khi đã có dữ liệu
  List<MeasurementDefinitionModel>? _readEffectiveDefs() {
    if (widget.task.experimentId.isEmpty) return const [];
    final raw = ref.watch(
        measurementDefinitionsProvider(widget.task.experimentId));
    if (raw.isLoading) return null;
    final effective = ref.watch(
      effectiveMeasurementDefinitionsProvider(
        EffectiveDefinitionsParam(
          definitions: raw.value ?? const [],
          experimentId: widget.task.experimentId,
          taskId: widget.task.id,
          batchId: widget.task.batchId.isEmpty ? null : widget.task.batchId,
        ),
      ),
    );
    return effective.value;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final resultData = <String, String>{};
    String notes = _noteController.text.trim();

    List<MeasurementDefinitionModel> effectiveDefs = const [];
    BridgeOutput? bridgeOutput;

    if (_isDynamic) {
      final defs = _readEffectiveDefs() ?? const [];
      effectiveDefs = defs;
      for (final def in defs) {
        final key = 'def_${def.id}';
        final c = _defControllers[key];
        final raw = c?.text.trim() ?? '';
        if (raw.isEmpty) continue;
        resultData[key] = raw;
      }

      if (defs.isNotEmpty) {
        final taskCtx = TaskGroupContext(
          experimentId: widget.task.experimentId.isEmpty
              ? null
              : widget.task.experimentId,
          experimentStageId: null,
          batchId: widget.task.batchId.isEmpty ? null : widget.task.batchId,
          batchGroupId: null,
          taskType: widget.task.taskType,
        );
        bridgeOutput = buildBridgeOutput(
          task: taskCtx,
          resultData: resultData.map((k, v) => MapEntry(k, v as dynamic)),
          effectiveDefinitions: defs,
          meta: BridgeExtraMeta(
            measuredAt: DateTime.now(),
            notes: notes.isNotEmpty ? notes : null,
          ),
        );
      }
    } else {
      final schema = _schema;
      if (schema != null) {
        for (final f in schema.fields) {
          final c = _defControllers[f.key];
          if (c == null) continue;
          final v = c.text.trim();
          if (v.isEmpty) continue;
          resultData[f.key] = f.type == QuickFieldType.number
              ? '${double.tryParse(v.replaceAll(',', '.')) ?? v}'
              : v;
        }
      }
    }

    // Custom fields.
    for (final cf in _customFields) {
      final c = _customControllers[cf.key];
      final v = c?.text.trim() ?? '';
      if (v.isEmpty) continue;
      resultData[cf.key] = v;
    }

    if (notes.isNotEmpty) {
      resultData['additionalNotes'] = notes;
    }

    final params = SubmitParams(
      taskId: widget.task.id,
      reportText: _composeReportText(resultData),
      resultData: resultData,
      images: _selectedImages
          .map((f) => TaskReportImageParam(
                file: f,
                uploadedAt: DateTime.now(),
              ))
          .toList(),
      experimentId: widget.task.experimentId.isEmpty
          ? null
          : widget.task.experimentId,
      batchId: widget.task.batchId.isEmpty ? null : widget.task.batchId,
      effectiveDefinitions:
          effectiveDefs.isEmpty ? null : effectiveDefs,
      bridgeOutput: bridgeOutput,
      markComplete: false,
      hasNewContent: true,
    );

    try {
      final outcome = await ref
          .read(taskReportSubmitServiceProvider)
          .submitAndOptionallyComplete(params);
      if (!mounted) return;
      // Invalidate providers liên quan ngay khi sheet đóng.
      ref.invalidate(taskDetailProvider(widget.task.id));
      ref.invalidate(taskReportByTaskProvider(widget.task.id));
      ref.invalidate(taskImagesByTaskProvider(widget.task.id));
      ref.invalidate(myTasksProvider);
      ref.invalidate(myTodayTasksProvider);
      ref.invalidate(filteredMyTasksProvider);
      ref.invalidate(todayTasksLocalProvider);
      ref.invalidate(overdueTasksLocalProvider);
      // Sync state images về parent.
      widget.onImagesChanged?.call(List<File>.from(_selectedImages));

      Navigator.of(context).pop();
      _showOutcomeSnack(outcome);

      if (outcome.mode != SubmitMode.error) {
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showOutcomeSnack(SubmitOutcome(
          mode: SubmitMode.error,
          reportId: null,
          measurementCount: 0,
          imageCount: 0,
          errors: ['Gửi báo cáo thất bại: $e'],
        ));
      }
    }
  }

  void _showOutcomeSnack(SubmitOutcome outcome) {
    if (!mounted) return;
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

  String _composeReportText(Map<String, String> resultData) {
    final parts = <String>[];
    resultData.forEach((k, v) {
      if (k == 'additionalNotes') return;
      if (k.startsWith('def_')) {
        parts.add('${k.substring(4)}=$v');
      } else {
        parts.add('$k=$v');
      }
    });
    final note = resultData['additionalNotes'];
    final base = parts.isEmpty ? 'Đã hoàn thành' : parts.join(', ');
    return note == null ? base : '$base | $note';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final spec = getTaskVisualSpec(widget.task.taskType);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              _buildHandleBar(cs),
              _buildHero(spec, tt, cs),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressHeader(tt, cs),
                        const SizedBox(height: AppSpacing.lg),
                        if (_isDynamic)
                          _buildDynamicForm(tt, cs)
                        else
                          _buildHardcodedForm(tt, cs),
                        const SizedBox(height: AppSpacing.lg),
                        _buildCustomFields(tt, cs),
                        const SizedBox(height: AppSpacing.lg),
                        _buildNotesField(tt, cs),
                        const SizedBox(height: AppSpacing.lg),
                        _buildImagePickerSection(tt, cs),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSubmitButton(spec, cs),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────── UI pieces ──────────────────────────

  Widget _buildHandleBar(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withAlpha(60),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(TaskVisualSpec spec, TextTheme tt, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            spec.color.withAlpha(220),
            spec.color,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Báo cáo nhanh',
                        style: tt.labelSmall?.copyWith(
                            color: Colors.white.withAlpha(220),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    Text(widget.task.title,
                        style: tt.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (widget.task.experimentCode?.isNotEmpty == true) ...[
                _HeroMetaPill(
                  icon: Icons.science_rounded,
                  label: widget.task.experimentCode!,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (widget.task.batchCode?.isNotEmpty == true)
                _HeroMetaPill(
                  icon: Icons.inventory_2_outlined,
                  label: widget.task.batchCode!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(TextTheme tt, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text('Chỉ số báo cáo',
            style: tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: AppSpacing.sm),
        if (_filledCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$_filledCount đã nhập',
                style: tt.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
      ],
    );
  }

  Widget _buildDynamicForm(TextTheme tt, ColorScheme cs) {
    final defs = _readEffectiveDefs();
    if (defs == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (defs.isEmpty) {
      return _buildEmptyDynamicBanner(cs, tt);
    }
    return Column(
      children: [
        for (int i = 0; i < defs.length; i++) ...[
          _MeasurementFieldCard(
            definition: defs[i],
            controller: _defControllers.putIfAbsent(
                'def_${defs[i].id}', () => TextEditingController()),
            onChanged: (_) => _recomputeFilled(),
            tt: tt,
            cs: cs,
          ),
          if (i != defs.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildEmptyDynamicBanner(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Experiment này chưa có MeasurementDefinition. Liên hệ Researcher để tạo trước.',
              style: tt.bodySmall?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardcodedForm(TextTheme tt, ColorScheme cs) {
    final schema = _schema;
    if (schema == null || schema.fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Loại tác vụ này không có form cố định. Hãy nhập ghi chú bên dưới.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153)),
        ),
      );
    }
    final grouped = <String, List<QuickFormFieldSpec>>{};
    for (final f in schema.fields) {
      grouped.putIfAbsent(f.group ?? '', () => []).add(f);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final fields = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.key.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(entry.key,
                  style: tt.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (int i = 0; i < fields.length; i++) ...[
              _SchemaFieldCard(
                field: fields[i],
                controller: _defControllers.putIfAbsent(
                    fields[i].key, () => TextEditingController()),
                onChanged: (_) => _recomputeFilled(),
                tt: tt,
                cs: cs,
              ),
              if (i != fields.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCustomFields(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_chart_rounded,
                color: cs.primary.withAlpha(204), size: 18),
            const SizedBox(width: 4),
            Text('Tùy chỉnh thêm',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  final idx = _customFields.length + 1;
                  _customFields.add(
                    _CustomField(
                      key: 'custom_$idx',
                      label: 'Trường $idx',
                      value: '',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Thêm'),
            ),
          ],
        ),
        for (int i = 0; i < _customFields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customControllers.putIfAbsent(
                        _customFields[i].key,
                        () => TextEditingController()..addListener(_recomputeFilled)),
                    decoration: InputDecoration(
                      hintText: _customFields[i].label,
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    ),
                  ),
                ),
                if (_customFields.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.error, size: 18),
                    onPressed: () {
                      setState(() => _customFields.removeAt(i));
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotesField(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_rounded,
                color: cs.primary.withAlpha(204), size: 18),
            const SizedBox(width: 4),
            Text('Ghi chú', style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Mô tả chi tiết về tác vụ, sự cố (nếu có)…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                color: cs.primary.withAlpha(204), size: 18),
            const SizedBox(width: 4),
            Text('Ảnh minh chứng',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TaskImagePicker(
          images: _selectedImages,
          onImagesChanged: (imgs) {
            setState(() => _selectedImages = imgs);
          },
          isUploading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(TaskVisualSpec spec, ColorScheme cs) {
    final canSubmit = _filledCount > 0 && !_isSubmitting;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: canSubmit ? _submit : null,
        style: FilledButton.styleFrom(
          backgroundColor: spec.color,
          disabledBackgroundColor: cs.surfaceContainerHighest.withAlpha(150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(
          _isSubmitting
              ? 'Đang gửi…'
              : canSubmit
                  ? 'Gửi báo cáo ($_filledCount chỉ số)'
                  : 'Nhập ít nhất 1 chỉ số',
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _CustomField {
  _CustomField({required this.key, required this.label, required this.value});
  final String key;
  final String label;
  final String value;
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _MeasurementFieldCard extends StatelessWidget {
  const _MeasurementFieldCard({
    required this.definition,
    required this.controller,
    required this.onChanged,
    required this.tt,
    required this.cs,
  });

  final MeasurementDefinitionModel definition;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final unit = definition.unit ?? '';
    final targetText = definition.targetValue != null
        ? 'Mục tiêu: ${definition.targetValue} $unit'
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.straighten_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  definition.metricName.isNotEmpty
                      ? definition.metricName
                      : definition.id,
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (unit.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(unit,
                      style: tt.labelSmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                          fontSize: 10)),
                ),
            ],
          ),
          if (targetText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(targetText,
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(153),
                      fontSize: 11)),
            ),
          if (definition.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(definition.description!,
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(128),
                      fontSize: 11)),
              ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText:
                  'Nhập giá trị ${unit.isNotEmpty ? "(đơn vị $unit)" : ""}',
              prefixIcon: const Icon(Icons.edit_rounded, size: 18),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : const Icon(Icons.check_rounded,
                      color: AppColors.success, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemaFieldCard extends StatelessWidget {
  const _SchemaFieldCard({
    required this.field,
    required this.controller,
    required this.onChanged,
    required this.tt,
    required this.cs,
  });
  final QuickFormFieldSpec field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextTheme tt;
  final ColorScheme cs;

  IconData get _icon => switch (field.type) {
        QuickFieldType.number => Icons.numbers_rounded,
        QuickFieldType.text => Icons.short_text_rounded,
        QuickFieldType.select => Icons.list_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(field.label,
                    style: tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (field.required)
                Text('*',
                    style: tt.titleSmall
                        ?.copyWith(color: AppColors.error)),
            ],
          ),
          if (field.description != null && field.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(field.description!,
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(128), fontSize: 11)),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (field.type == QuickFieldType.select && field.options != null)
            DropdownButtonFormField<String>(
              initialValue: null,
              items: field.options!
                  .map((o) => DropdownMenuItem(
                      value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                controller.text = v ?? '';
                onChanged(v ?? '');
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
              ),
            )
          else
            TextFormField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.next,
              keyboardType: field.type == QuickFieldType.number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              maxLines: field.type == QuickFieldType.text ? 3 : 1,
              decoration: InputDecoration(
                hintText: field.placeholder ?? 'Nhập giá trị…',
                prefixIcon: Icon(_icon, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: field.type == QuickFieldType.text
                    ? const EdgeInsets.all(AppSpacing.md)
                    : const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.md),
              ),
            ),
        ],
      ),
    );
  }
}
