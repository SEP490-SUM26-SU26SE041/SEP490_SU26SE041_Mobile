import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/models/measurement_definition_model.dart';
import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tasks/data/measurement_bridge.dart';
import '../../../tasks/data/task_report_submit_service.dart';
import '../../providers/measurement_batch_providers.dart';
import '../../providers/measurement_record_providers.dart';

/// Bottom sheet ghi nhận đo lường — dùng [BridgeOutput] mới.
///
/// Flow:
///   1. Watch [effectiveMeasurementDefinitionsProvider] (đã filter theo groupId).
///   2. Render 1 field / definition; field có key `def_<uuid>` trong
///      [resultData] (Map<String,String>).
///   3. Validate local qua [localValidateValue], hiển thị status icon.
///   4. Submit = [TaskReportSubmitService.submitAndOptionallyComplete]:
///        • Tạo TaskReport với resultData (chứa def_<uuid> keys).
///        • Gọi POST /measurement-records/bulk qua bridge (BridgePath.bulk).
///        • PATCH /tasks/{id}/complete.
Future<void> showMeasurementRecordingSheet(
  BuildContext context,
  api.TaskModel task, {
  VoidCallback? onMeasurementComplete,
  VoidCallback? onSubmitted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MeasurementRecordingSheet(
      task: task,
      onMeasurementComplete: onMeasurementComplete,
      onSubmitted: onSubmitted,
    ),
  );
}

class _MeasurementRecordingSheet extends ConsumerStatefulWidget {
  const _MeasurementRecordingSheet({
    required this.task,
    this.onMeasurementComplete,
    this.onSubmitted,
  });
  final api.TaskModel task;
  final VoidCallback? onMeasurementComplete;
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<_MeasurementRecordingSheet> createState() =>
      _MeasurementRecordingSheetState();
}

class _MeasurementRecordingSheetState
    extends ConsumerState<_MeasurementRecordingSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _measurementControllers = {};
  final _noteController = TextEditingController();
  final _reportController = TextEditingController();
  bool _isSubmitting = false;
  String? _activeError;

  bool get _showReportTab =>
      widget.task.experimentId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _showReportTab ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    _noteController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;

    if (task.experimentId.isEmpty) {
      return _wrap(cs, _buildError(cs, 'Task chưa có experimentId.'));
    }

    final rawDefs =
        ref.watch(measurementDefinitionsProvider(task.experimentId));
    final effectiveDefs = ref.watch(
      effectiveMeasurementDefinitionsProvider(
        EffectiveDefinitionsParam(
          definitions: rawDefs.value ?? const [],
          experimentId: task.experimentId,
          taskId: task.id,
          batchId: task.batchId,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: rawDefs.when(
        loading: () => _wrap(cs, _buildLoading(cs)),
        error: (e, _) => _wrap(cs, _buildError(cs, 'Lỗi tải chỉ số: $e')),
        data: (_) {
          final defs = effectiveDefs.value ?? const [];
          final hasMetrics = defs.isNotEmpty;
          if (!hasMetrics || widget.onMeasurementComplete == null) {
            return _wrap(cs,
                _buildReportOnly(task, tt, cs, defs: defs));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(task, tt, cs),
              _buildTabBar(cs),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReportTab(task, tt, cs),
                    _buildMeasurementTab(task, defs, tt, cs),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _wrap(ColorScheme cs, Widget child, {double bottomPadding = AppSpacing.lg}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + bottomPadding,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: child,
    );
  }

  Widget _buildLoading(ColorScheme cs) {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(ColorScheme cs, String message) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.straighten_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ghi nhận đo lường',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(task.title,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withAlpha(153),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Báo cáo'),
            Tab(text: 'Đo lường'),
          ],
        ),
      ),
    );
  }

  // ─── Report Tab ───────────────────────────────────────────────────────────

  Widget _buildReportTab(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoChip(task, tt, cs),
          const SizedBox(height: AppSpacing.lg),
          Text('Nội dung báo cáo',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _reportController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Mô tả tiến độ thực hiện công việc...',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSubmitButton(cs, tt, submitType: _SubmitType.reportOnly),
        ],
      ),
    );
  }

  Widget _buildInfoChip(api.TaskModel task, TextTheme tt, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 4,
              children: [
                if (task.batchCode != null) _chip('Batch: ${task.batchCode}', cs),
                if (task.experimentStageName != null)
                  _chip('Giai đoạn: ${task.experimentStageName}', cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.info)),
    );
  }

  // ─── Measurement Tab ────────────────────────────────────────────────────

  Widget _buildMeasurementTab(
    api.TaskModel task,
    List<MeasurementDefinitionModel> defs,
    TextTheme tt,
    ColorScheme cs,
  ) {
    for (final d in defs) {
      _measurementControllers.putIfAbsent(d.id, () => TextEditingController());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.info, size: 16),
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
          ...defs.map((d) => _buildDynamicField(d, tt, cs)),
          const SizedBox(height: AppSpacing.lg),
          Text('Ghi chú (tùy chọn)',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Điều kiện đo, thời tiết...',
              filled: true,
              fillColor: cs.surfaceContainerHighest.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          // Custom columns
          const SizedBox(height: AppSpacing.lg),
          Text('Cột tùy chỉnh',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          ..._customKeys.map((k) => _buildCustomRow(k, tt, cs)),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('+ Thêm cột'),
            onPressed: () => setState(() {
              final keys = _customKeys.toSet()..add(nextCustomKey(_customKeys.toSet()));
              _customKeys
                ..clear()
                ..addAll(keys);
            }),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_activeError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorBanner(message: _activeError!),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildSubmitButton(cs, tt, submitType: _SubmitType.measurementComplete),
        ],
      ),
    );
  }

  final List<String> _customKeys = [];

  Widget _buildDynamicField(
    MeasurementDefinitionModel d,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final controller = _measurementControllers[d.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.metricName,
                    style: tt.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (d.targetValue != null)
                _targetBadge(d, tt),
            ],
          ),
          if (d.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(d.description!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(120))),
            ),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final errorText = localValidateValue(d, value.text);
              final status = getValueStatus(d, value.text);
              return TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nhập giá trị...',
                  suffixText: d.unit ?? '',
                  errorText: errorText,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withAlpha(128),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  suffixIcon: _statusIcon(status, cs),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _targetBadge(MeasurementDefinitionModel d, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Mục tiêu: ${d.targetValue} ${d.unit ?? ''}',
        style: tt.labelSmall?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget? _statusIcon(ValueStatus status, ColorScheme cs) {
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

  Widget _buildCustomRow(String key, TextTheme tt, ColorScheme cs) {
    final controller = _customControllers.putIfAbsent(key, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(key,
                style: tt.labelMedium?.copyWith(
                    color: cs.onSurface.withAlpha(153), fontFamily: 'monospace')),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surfaceContainerHighest.withAlpha(128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.sm),
                hintText: 'Giá trị tự do',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: () => setState(() {
              _customKeys.remove(key);
              controller.dispose();
              _customControllers.remove(key);
            }),
          ),
        ],
      ),
    );
  }

  final Map<String, TextEditingController> _customControllers = {};

  // ─── Report-only ─────────────────────────────────────────────────────────

  Widget _buildReportOnly(
    api.TaskModel task,
    TextTheme tt,
    ColorScheme cs, {
    required List<MeasurementDefinitionModel> defs,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(task, tt, cs),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoChip(task, tt, cs),
                const SizedBox(height: AppSpacing.lg),
                Text('Nội dung báo cáo',
                    style: tt.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _reportController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Mô tả tiến độ...',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withAlpha(128),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildSubmitButton(cs, tt,
                    submitType: _SubmitType.reportOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton(
    ColorScheme cs,
    TextTheme tt, {
    required _SubmitType submitType,
  }) {
    final label = switch (submitType) {
      _SubmitType.reportOnly => 'Gửi báo cáo',
      _SubmitType.measurementComplete => 'Hoàn thành đo lường',
    };
    final icon = switch (submitType) {
      _SubmitType.reportOnly => Icons.send_rounded,
      _SubmitType.measurementComplete => Icons.check_circle_rounded,
    };
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Huỷ'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(submitType),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 18),
            label: Text(_isSubmitting ? 'Đang xử lý...' : label),
            style: FilledButton.styleFrom(
              backgroundColor: submitType == _SubmitType.measurementComplete
                  ? AppColors.success
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(_SubmitType submitType) async {
    setState(() {
      _isSubmitting = true;
      _activeError = null;
    });
    try {
      final task = widget.task;
      if (submitType == _SubmitType.measurementComplete) {
        await _submitMeasurementComplete(task);
      } else {
        await _submitReportOnly(task);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeError = 'Lỗi: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitReportOnly(api.TaskModel task) async {
    final reportText = _reportController.text.trim().isNotEmpty
        ? _reportController.text.trim()
        : 'Đã ghi nhận tiến độ công việc.';
    try {
      final params = SubmitParams(
        taskId: task.id,
        reportText: reportText,
        resultData: const {},
        images: const [],
        experimentId: task.experimentId.isEmpty ? null : task.experimentId,
        batchId: task.batchId,
        markComplete: false,
        hasNewContent: true,
      );
      final outcome =
          await ref.read(taskReportSubmitServiceProvider).submitAndOptionallyComplete(params);

      widget.onSubmitted?.call();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(outcome.toUserMessage()),
            backgroundColor:
                outcome.mode == SubmitMode.error ? AppColors.error : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeError = 'Lỗi gửi báo cáo: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitMeasurementComplete(api.TaskModel task) async {
    // Build resultData với def_<uuid> keys + custom.
    final resultData = <String, String>{};
    final rawDefs = ref.read(measurementDefinitionsProvider(task.experimentId)).value ?? const [];
    final effective =
        ref.read(effectiveMeasurementDefinitionsProvider(
      EffectiveDefinitionsParam(
        definitions: rawDefs,
        experimentId: task.experimentId,
        taskId: task.id,
        batchId: task.batchId,
      ),
    )).value ?? const [];

    if (effective.isEmpty) {
      setState(() {
        _activeError = 'Không tìm thấy chỉ số cho nhóm "${task.batchCode}".';
        _isSubmitting = false;
      });
      return;
    }

    String? firstError;
    for (final d in effective) {
      final c = _measurementControllers[d.id];
      final v = c?.text.trim() ?? '';
      if (v.isEmpty) continue;
      final err = localValidateValue(d, v);
      if (err != null) {
        firstError ??= err;
        continue;
      }
      resultData['def_${d.id}'] = v;
    }
    // Custom columns
    for (final key in _customKeys) {
      final c = _customControllers[key];
      final v = c?.text.trim() ?? '';
      if (v.isEmpty) continue;
      resultData[key] = v;
    }

    if (resultData.isEmpty) {
      setState(() {
        _activeError = firstError ?? 'Vui lòng nhập ít nhất 1 chỉ số';
        _isSubmitting = false;
      });
      return;
    }

    final note = _noteController.text.trim();

    // Build bridge output.
    final taskCtx = TaskGroupContext(
      experimentId: task.experimentId.isEmpty ? null : task.experimentId,
      experimentStageId: task.experimentStageId,
      batchId: task.batchId,
      taskType: task.taskType,
    );
    final bridge = buildBridgeOutput(
      task: taskCtx,
      resultData: resultData,
      effectiveDefinitions: effective,
      meta: BridgeExtraMeta(notes: note),
    );

    final outcome = await ref.read(taskReportSubmitServiceProvider).submitAndOptionallyComplete(
          SubmitParams(
            taskId: task.id,
            reportText: note.isNotEmpty
                ? 'Đã hoàn thành phép đo lường. ${effective.length} chỉ số đã được ghi nhận.'
                : 'Đã hoàn thành phép đo lường. ${effective.length} chỉ số đã được ghi nhận.',
            resultData: resultData,
            images: const [],
            experimentId: task.experimentId.isEmpty ? null : task.experimentId,
            batchId: task.batchId,
            effectiveDefinitions: effective,
            bridgeOutput: bridge,
            markComplete: true,
            hasNewContent: true,
          ),
        );

    // Refetch records list for batch.
    if (task.batchId != null) {
      ref.invalidate(measurementRecordsByBatchProvider(task.batchId!));
    }

    widget.onMeasurementComplete?.call();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.toUserMessage()),
          backgroundColor:
              outcome.mode == SubmitMode.error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
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

enum _SubmitType {
  reportOnly,
  measurementComplete,
}
