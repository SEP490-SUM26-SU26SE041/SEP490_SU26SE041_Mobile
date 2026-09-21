import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/growth_task_model.dart';
import '../../../../shared/widgets/snms_card.dart';
import '../../../../shared/utils/report_field_labels.dart';
import '../../../tasks/data/metric_catalog.dart';
import '../../../tasks/presentation/widgets/ai_badge.dart';
import '../../../tasks/presentation/widgets/ai_result_modal.dart';
import '../../../tasks/providers/measurement_definition_provider.dart';
import '../../../tasks/providers/task_image_providers.dart';
import '../../../tasks/providers/task_providers.dart';

/// Bottom sheet hiển thị lịch sử báo cáo đã gửi (read-only).
/// BE trả về ARRAY các reports cho 1 task, mỗi report có ảnh và metadata.
/// User chọn 1 report từ list bên trái → chi tiết bên phải.
Future<void> showTaskReportViewSheet(BuildContext context, String taskId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskReportViewSheet(taskId: taskId),
  );
}

class _TaskReportViewSheet extends ConsumerStatefulWidget {
  const _TaskReportViewSheet({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_TaskReportViewSheet> createState() =>
      _TaskReportViewSheetState();
}

class _TaskReportViewSheetState extends ConsumerState<_TaskReportViewSheet> {
  String? _selectedReportId;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final reportAsync =
        ref.watch(taskReportByTaskProvider(widget.taskId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Báo cáo',
                      style: tt.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reportAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text('Không tải được báo cáo',
                            style: tt.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(e.toString(),
                            style: tt.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 48,
                                color: cs.onSurface.withAlpha(77)),
                            const SizedBox(height: AppSpacing.md),
                            Text('Task này chưa có báo cáo',
                                style: tt.titleMedium),
                          ],
                        ),
                      ),
                    );
                  }
                  // Sort newest first
                  final sorted = [...reports]
                    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
                  _selectedReportId ??= sorted.first.id;
                  final selected = sorted.firstWhere(
                    (r) => r.id == _selectedReportId,
                    orElse: () => sorted.first,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT: list các reports
                      SizedBox(
                        width: 110,
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.md),
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final r = sorted[i];
                            final isSelected = r.id == _selectedReportId;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedReportId = r.id),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.success.withAlpha(25)
                                      : cs.surfaceContainerHighest
                                          .withAlpha(77),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.success
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.history_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.success
                                          : cs.onSurface.withAlpha(128),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatDateShort(r.submittedAt),
                                      style: tt.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.success
                                            : cs.onSurface.withAlpha(179),
                                      ),
                                    ),
                                    Text(
                                      formatTime(r.submittedAt),
                                      style: tt.labelSmall?.copyWith(
                                        color:
                                            cs.onSurface.withAlpha(128),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        color: cs.outline.withAlpha(40),
                      ),
                      // RIGHT: chi tiết report được chọn
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
                              AppSpacing.xxl),
                          children: [
                            _Header(report: selected, tt: tt, cs: cs),
                            const SizedBox(height: AppSpacing.lg),
                            _ReportContent(
                                report: selected,
                                taskId: widget.taskId,
                                tt: tt,
                                cs: cs),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report, required this.tt, required this.cs});
  final TaskReportModel report;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    report.title.isNotEmpty
                        ? report.title
                        : 'Báo cáo công việc',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gửi bởi ${report.submittedBy ?? '—'} • ${formatDateTime(report.submittedAt)}',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurface.withAlpha(153)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends ConsumerWidget {
  const _ReportContent({
    required this.report,
    required this.taskId,
    required this.tt,
    required this.cs,
  });
  final TaskReportModel report;
  final String taskId;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rd = report.rawResultData;
    // Load measurement definitions nếu task thuộc experiment.
    // Lấy experimentId từ task detail (vì TaskReportModel không có sẵn).
    final taskAsync = ref.watch(taskDetailProvider(report.taskId));
    final experimentId = taskAsync.maybeWhen(
      data: (t) => t?.experimentId ?? '',
      orElse: () => '',
    );
    final defMap = experimentId.isEmpty
        ? null
        : ref
            .watch(measurementDefinitionsByExperimentProvider(experimentId))
            .maybeWhen(
              data: (m) => m,
              orElse: () => null,
            );

    // Ưu tiên images kèm AI analysis từ endpoint /task-images/task/{id}/detail.
    // Nếu đang loading/error → dùng report.images (không có AI).
    // Dùng DateTime.now().millisecondsSinceEpoch để force refresh mỗi lần build
    // để đảm bảo AsyncValue luôn update khi user mở sheet.
    final reportImagesAsync = ref.watch(
      taskImagesByReportWithAnalysisProvider(report.id),
    );

    // Helper build images từ report.images
    List<_ImageWithAi> buildImagesFromReport() {
      final baseImages = report.images.where((img) => img.imageUrl.isNotEmpty).toList();
      if (baseImages.isEmpty) return [];
      return baseImages
          .map((img) => _ImageWithAi(model: img, hasAi: false))
          .toList();
    }

    // Merge: ưu tiên images từ async (có AI), fallback về report.images (show ảnh trước)
    final List<_ImageWithAi> imagesWithAi = reportImagesAsync.when(
      data: (list) {
        if (list.isNotEmpty) {
          return list
              .where((img) => img.imageUrl.isNotEmpty)
              .map((img) => _ImageWithAi(
                    model: img,
                    hasAi: img.aiAnalysis != null,
                  ))
              .toList();
        }
        return buildImagesFromReport();
      },
      loading: buildImagesFromReport,
      error: (_, __) => buildImagesFromReport(),
    );

    // Check xem có AI results không (từ imagesWithAi đã merge)
    // (giữ lại để có thể dùng sau nếu cần)
    // ignore: unused_local_variable
    final hasAiResults = imagesWithAi.any((img) => img.model.aiAnalysis != null);

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Nội dung báo cáo',
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DescriptionSection(
            description: report.description,
            rawResultData: rd,
            defMap: defMap,
            tt: tt,
            cs: cs,
          ),
          if (imagesWithAi.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ImagesSection(
              imagesWithAi: imagesWithAi,
              taskReportId: report.id,
              tt: tt,
              cs: cs,
            ),
            // LUÔN hiển thị section "Kết quả AI chẩn đoán" (loading nếu chưa có data)
            const SizedBox(height: AppSpacing.lg),
            _AiResultsInline(
              imagesWithAi: imagesWithAi,
              asyncState: reportImagesAsync,
              tt: tt,
              cs: cs,
            ),
          ],
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.rawResultData,
    required this.defMap,
    required this.tt,
    required this.cs,
  });
  final String description;
  final Map<String, dynamic>? rawResultData;
  final Map<String, MeasurementDefinitionInfo>? defMap;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(),
        if (rawResultData != null && rawResultData!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Chi tiết kết quả',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          ..._buildResultRows(rawResultData!, defMap),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    final parsed = _parseKeyValueDescription(description);
    if (parsed != null && parsed.isNotEmpty) {
      final chips = <Widget>[];
      parsed.forEach((key, value) {
        if (value.isEmpty) return;
        final label = labelForReportKey(key);
        chips.add(_ResultChip(label: label, value: value, tt: tt, cs: cs));
        chips.add(const SizedBox(height: AppSpacing.xs));
      });
      // Nếu parse được nhưng không có chip nào (tất cả value rỗng) → plain text.
      if (chips.isEmpty) {
        return _plainDescription(description);
      }
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      );
    }
    return _plainDescription(description);
  }

  Widget _plainDescription(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: tt.bodyMedium),
    );
  }

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

  List<Widget> _buildResultRows(
    Map<String, dynamic> rd,
    Map<String, MeasurementDefinitionInfo>? defMap,
  ) {
    final rows = <Widget>[];
    String? v(String k) {
      final raw = rd[k];
      if (raw == null) return null;
      final s = raw.toString();
      return s.isEmpty ? null : s;
    }

    void add(String key) {
      final label = labelForReportKey(key);
      final value = v(key);
      if (value == null || value.isEmpty) return;
      rows.add(_ResultChip(label: label, value: value, tt: tt, cs: cs));
      rows.add(const SizedBox(height: AppSpacing.xs));
    }

    add('plantCount');
    add('plantsWatered');
    add('fertilizedPlantCount');
    add('waterAmount');
    add('fertilizerAmount');
    add('condition');
    add('healthStatus');
    add('plantsWilting');
    add('action');
    add('plantsHarvested');
    add('harvestWeight');
    add('plantHeight');
    add('chieuCaoCm');
    add('leafCount');
    add('soLaTrungBinh');
    add('leafColor');
    add('soilMoistureAfter');
    add('inspectedDevices');

    if (rd.isNotEmpty) {
      rd.forEach((k, val) {
        if (k.startsWith('def_') || k.startsWith('custom_')) {
          final s = val?.toString() ?? '';
          if (s.isEmpty) return;

          String label;
          if (k.startsWith('custom_')) {
            final fieldName = k.substring('custom_'.length);
            label = 'Tùy chỉnh: $fieldName';
          } else {
            final definitionId = k.substring('def_'.length);
            final info = defMap?[definitionId];
            if (info != null && info.metricName.isNotEmpty) {
              final unit = info.unit;
              final display = MetricCatalog.lookup(info.metricName);
              if (display != null) {
                label = unit != null && unit.isNotEmpty
                    ? '${display.label} ($unit)'
                    : display.label;
              } else {
                label = unit != null && unit.isNotEmpty
                    ? '${info.metricName} ($unit)'
                    : info.metricName;
              }
            } else {
              final guessed = _guessMetricFromValue(s);
              if (guessed != null) {
                label = guessed.label;
              } else {
                label = 'Chỉ số (${_shortId(definitionId)})';
              }
            }
          }
          rows.add(_ResultChip(label: label, value: s, tt: tt, cs: cs));
          rows.add(const SizedBox(height: AppSpacing.xs));
        }
      });
    }

    final notes = v('additionalNotes');
    if (notes != null) {
      rows.add(const SizedBox(height: AppSpacing.sm));
      rows.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withAlpha(40)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.note_rounded, size: 16, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(notes, style: tt.bodySmall)),
          ],
        ),
      ));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return rows;
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  MetricDisplay? _guessMetricFromValue(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (RegExp(r'\bcm\b|centimeter|xentimet').hasMatch(v)) {
      return MetricCatalog.lookup('height');
    }
    if (RegExp(r'\blá\b|\bla\b|\bleaf').hasMatch(v)) {
      return MetricCatalog.lookup('leafCount');
    }
    if (RegExp(r'%').hasMatch(v)) {
      return const MetricDisplay(label: 'Chỉ số (%)', unit: '%', icon: 'percent');
    }
    if (RegExp(r'\bkg\b|\btấn\b|\bton\b|\bg\b').hasMatch(v)) {
      return MetricCatalog.lookup('weight');
    }
    if (RegExp(r'\blít\b|\bliter\b|\bl\b').hasMatch(v)) {
      return MetricCatalog.lookup('waterAmount');
    }
    return null;
  }
}

/// Chip hiển thị 1 cặp label=value với label tiếng Việt.
class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.value,
    required this.tt,
    required this.cs,
  });
  final String label;
  final String value;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              value,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiển thị grid ảnh đính kèm trong report view (read-only).
/// Bấm vào ảnh → mở AiResultModal xem chi tiết kết quả AI + retry.
class _ImagesSection extends ConsumerWidget {
  const _ImagesSection({
    required this.imagesWithAi,
    required this.taskReportId,
    required this.tt,
    required this.cs,
  });
  final List<_ImageWithAi> imagesWithAi;
  final String taskReportId;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 18, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text('Hình ảnh đính kèm',
                style:
                    tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${imagesWithAi.length}',
                  style: tt.labelSmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imagesWithAi.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => _ImageTile(
              img: imagesWithAi[i],
              taskReportId: taskReportId,
              tt: tt,
              cs: cs,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends ConsumerWidget {
  const _ImageTile({
    required this.img,
    required this.taskReportId,
    required this.tt,
    required this.cs,
  });
  final _ImageWithAi img;
  final String taskReportId;
  final TextTheme tt;
  final ColorScheme cs;

  TaskImageModel get image => img.model;

  void _openAiModal(BuildContext context) {
    if (image.aiProvider == null) {
      // Không có AI provider → mở full screen
      _openFullScreen(context);
      return;
    }
    showAiResultModal(
      context,
      image: image,
      taskReportId: taskReportId,
      onImageUpdated: (_) {
        // Refresh parent qua invalidation
        // ignore: unused_result
        // (consumer reloads via Riverpod)
      },
    );
  }

  void _openFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: SizedBox.expand(
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        ),
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white,
                      size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openAiModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Image.network(
              image.imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : Container(
                      width: 96,
                      height: 96,
                      color: cs.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
              errorBuilder: (_, _, _) => Container(
                width: 96,
                height: 96,
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.broken_image_rounded,
                    color: cs.onSurface.withAlpha(102), size: 28),
              ),
            ),
            // AI badge overlay (top-right)
            Positioned(
              top: 4,
              right: 4,
              child: AiBadge(image: img.model),
            ),
            if (img.model.caption != null && img.model.caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(160),
                      ],
                    ),
                  ),
                  child: Text(
                    img.model.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper chứa image model + flag có AI hay không.
class _ImageWithAi {
  const _ImageWithAi({required this.model, required this.hasAi});
  final TaskImageModel model;
  final bool hasAi;
}

/// Widget hiển thị AI results inline trong report view.
/// Hiện kết quả chẩn đoán AI (label, confidence, severity) ngay trong sheet.
/// LUÔN hiển thị section, kể cả khi API đang loading.
class _AiResultsInline extends StatelessWidget {
  const _AiResultsInline({
    required this.imagesWithAi,
    required this.asyncState,
    required this.tt,
    required this.cs,
  });

  final List<_ImageWithAi> imagesWithAi;
  final AsyncValue<List<TaskImageModel>> asyncState;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    // Lấy các ảnh có AI analysis (check trực tiếp từ model)
    final aiImages = imagesWithAi
        .where((img) => img.model.aiAnalysis != null)
        .toList();

    // Trạng thái loading
    final isLoading = asyncState.isLoading;
    final hasError = asyncState.hasError;

    // Tổng số ảnh trong report
    final totalImages = imagesWithAi.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Kết quả AI chẩn đoán',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.sm),
            // Loading indicator nhỏ bên cạnh title
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            // Badge số lượng AI results
            if (!isLoading && !hasError && aiImages.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${aiImages.length}/$totalImages',
                    style: tt.labelSmall?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Ưu tiên lấy AI images từ async data (có AI analysis đầy đủ)
        if (aiImages.isNotEmpty)
          ...aiImages.map((img) => _AiResultCard(
                imageWithAi: img,
                tt: tt,
                cs: cs,
              ))
        else if (isLoading && aiImages.isEmpty)
          // Đang load API → show skeleton/loading card
          _AiLoadingCard(tt: tt, cs: cs)
        else if (hasError && aiImages.isEmpty)
          // Lỗi API + không có data fallback
          _AiErrorCard(
            error: asyncState.error.toString(),
            tt: tt,
            cs: cs,
          )
        else
          // Không có ảnh nào có AI
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: cs.onSurface.withAlpha(153), size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Các ảnh này chưa được quét bằng AI.',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withAlpha(153)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Loading card khi đang đợi AI scan results.
class _AiLoadingCard extends StatelessWidget {
  const _AiLoadingCard({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang tải kết quả AI...',
                  style: tt.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vui lòng đợi trong giây lát',
                  style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(153)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error card khi load AI results thất bại.
class _AiErrorCard extends StatelessWidget {
  const _AiErrorCard({
    required this.error,
    required this.tt,
    required this.cs,
  });
  final String error;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Không thể tải kết quả AI',
                  style: tt.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error.length > 200 ? '${error.substring(0, 200)}...' : error,
                  style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(180)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiResultCard extends StatelessWidget {
  const _AiResultCard({
    required this.imageWithAi,
    required this.tt,
    required this.cs,
  });

  final _ImageWithAi imageWithAi;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final img = imageWithAi.model;
    final analysis = img.aiAnalysis;

    // Lấy thông tin từ model
    final label = img.aiPredictedLabel ?? analysis?.label;
    final confidence = img.aiConfidence ?? analysis?.confidence;
    final isHealthy = analysis?.isHealthy ?? false;
    final isGateRejection = analysis?.isGateRejection ?? false;
    final annotatedUrl = img.aiAnnotatedImageUrl ?? analysis?.annotatedImageUrl;
    final provider = img.aiProvider ?? analysis?.aiProvider;

    // Map label & finalStatus sang tiếng Việt có ý nghĩa
    final labelVi = _getVietnameseLabel(label);
    final statusLabel = _mapFinalStatus(analysis?.finalStatus);
    final severity = _getSeverityFromStatus(analysis?.finalStatus, label);

    // Xác định nhãn chính hiển thị trên header (ưu tiên label - tên bệnh cụ thể)
    final hasLabel = label != null && label.isNotEmpty && labelVi != label;
    final headerText = hasLabel
        ? labelVi
        : statusLabel; // fallback nếu label rỗng

    // Màu sắc theo trạng thái
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isGateRejection) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Bị từ chối bởi gate';
    } else if (isHealthy ||
        (analysis?.finalStatus?.toLowerCase().contains('healthy') ?? false) ||
        label?.toLowerCase().contains('healthy') == true ||
        label?.toLowerCase().contains('nopest') == true) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
      statusText = headerText; // "Cây khỏe mạnh" / "Không có sâu bệnh"
    } else if (hasLabel && !isHealthy) {
      // Có label bệnh cụ thể → dùng label làm header, màu theo severity
      statusColor = _getSeverityColor(severity);
      statusIcon = Icons.local_hospital_rounded;
      statusText = headerText;
    } else {
      statusColor = _getSeverityColor(severity);
      statusIcon = Icons.local_hospital_rounded;
      statusText = 'Phát hiện sâu bệnh';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với icon + status text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  statusText,
                  style: tt.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isHealthy && !isGateRejection)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    severity.label,
                    style: tt.labelSmall?.copyWith(
                      color: _getSeverityColor(severity),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Ảnh annotated (nếu có) full-width - thoáng, dễ nhìn
          if (annotatedUrl != null && annotatedUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                annotatedUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : Container(
                        width: double.infinity,
                        height: 180,
                        color: cs.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 180,
                  color: cs.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_rounded,
                          color: cs.onSurface.withAlpha(102), size: 32),
                      const SizedBox(height: 4),
                      Text('Không tải được ảnh',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withAlpha(153))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Thông tin chi tiết - layout cột để không bị bóp chữ
          _InfoBlock(
            entries: [
              if (hasLabel && statusText != labelVi)
                _InfoEntry('Nhãn bệnh', labelVi),
              if (analysis?.finalStatus != null && analysis!.finalStatus != label)
                _InfoEntry('Trạng thái', statusLabel),
              if (confidence != null)
                _InfoEntry('Độ tin cậy', '${(confidence * 100).toStringAsFixed(1)}%'),
              if (analysis?.detectionCount != null && analysis!.detectionCount! > 0)
                _InfoEntry('Số phát hiện', '${analysis.detectionCount}'),
              if (provider != null)
                _InfoEntry('Model AI',
                    _formatProviderName(provider)),
              if (analysis?.gateLabel != null &&
                  analysis!.gateLabel!.isNotEmpty &&
                  analysis.gateLabel != label)
                _InfoEntry('Gate', _formatGateLabel(analysis.gateLabel!)),
            ],
            tt: tt,
            cs: cs,
          ),
        ],
      ),
    );
  }

  /// Format provider name cho dễ đọc.
  /// "TomatoLeafDiseaseOnnx" → "Tomato Leaf Disease"
  String _formatProviderName(String p) {
    var result = p;
    // Xóa các suffix phổ biến
    for (final suffix in ['Onnx', 'V2', 'V1', 'Classifier', 'Detector']) {
      if (result.endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length);
      }
    }
    // Tách CamelCase → có space
    result = result.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return result;
  }

  /// Format gate label cho dễ đọc.
  /// "non_pest" → "non pest"
  /// "tomato_leaf" → "tomato leaf"
  String _formatGateLabel(String g) {
    return g.replaceAll('_', ' ');
  }
}

/// Một entry trong info block.
class _InfoEntry {
  const _InfoEntry(this.label, this.value);
  final String label;
  final String value;
}

/// Block hiển thị các thông tin AI dạng grid 2 cột (label | value).
class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.entries,
    required this.tt,
    required this.cs,
  });

  final List<_InfoEntry> entries;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(120),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          e.label,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withAlpha(180),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

enum _DiseaseSeverity {
  none('Không có'),
  low('Nhẹ'),
  medium('Trung bình'),
  high('Nghiêm trọng');

  const _DiseaseSeverity(this.label);
  final String label;
}

Color _getSeverityColor(_DiseaseSeverity severity) {
  return switch (severity) {
    _DiseaseSeverity.none => AppColors.success,
    _DiseaseSeverity.low => AppColors.info,
    _DiseaseSeverity.medium => AppColors.warning,
    _DiseaseSeverity.high => AppColors.error,
  };
}

/// Map finalStatus (từ API) sang tiếng Việt - dùng khi không có label cụ thể.
String _mapFinalStatus(String? status) {
  if (status == null) return 'Không xác định';
  final lower = status.toLowerCase();

  // ArgoPestOnnx statuses (phát hiện côn trùng/sâu)
  if (lower == 'nopest' || lower == 'healthy' || lower == 'no_pest') {
    return 'Không có sâu bệnh';
  }
  if (lower.contains('pest') || lower.contains('insect')) {
    return 'Có côn trùng gây hại';
  }

  // TomatoLeafDiseaseOnnx statuses (phân loại bệnh lá cà chua)
  if (lower == 'tomatoleafclassified') {
    return 'Lá cà chua - đã phân loại';
  }
  if (lower.contains('nottomato') || lower.contains('nottomtoleaf')) {
    return 'Không phải lá cà chua';
  }

  // Fallback: trả về nguyên gốc
  return status;
}

/// Lấy severity từ finalStatus + label (label là nguồn chính xác nhất).
_DiseaseSeverity _getSeverityFromStatus(String? status, String? label) {
  // Ưu tiên label - đây là tên bệnh cụ thể từ AI
  final source = (label ?? status ?? '').toLowerCase();

  // Healthy / no pest → không có bệnh
  if (source.contains('healthy') ||
      source == 'nopest' ||
      source == 'no_pest' ||
      source == 'healthyplant') {
    return _DiseaseSeverity.none;
  }

  // Bệnh nhẹ/trung bình
  if (source.contains('early_blight') ||
      source.contains('septoria') ||
      source.contains('spider_mites') ||
      source.contains('target_spot') ||
      source.contains('leaf_mold') ||
      source.contains('yellow') ||
      source.contains('leaf_minor')) {
    return _DiseaseSeverity.medium;
  }

  // Bệnh nặng/nguy hiểm
  if (source.contains('late_blight') ||
      source.contains('bacterial_spot') ||
      source.contains('mosaic_virus') ||
      source.contains('yellow_leaf_curl') ||
      source.contains('pest') ||
      source.contains('insect')) {
    return _DiseaseSeverity.high;
  }

  // Fallback: nếu có label mà không match rule nào → trung bình
  if (label != null && label.isNotEmpty) return _DiseaseSeverity.medium;
  return _DiseaseSeverity.low;
}

/// Map label (tên bệnh từ AI) sang tiếng Việt có ý nghĩa.
/// Đây là mapping CHÍNH - dùng để hiển thị tên bệnh cụ thể cho user.
String _getVietnameseLabel(String? label) {
  if (label == null || label.isEmpty) return '';
  final trimmed = label.trim();

  // Mapping đầy đủ cho Tomato diseases (theo PlantVillage dataset)
  final map = <String, String>{
    // ── Tomato Leaf Diseases ──
    'Tomato_Late_blight': 'Bệnh mốc muộn (Late blight)',
    'Tomato_Early_blight': 'Bệnh mốc sớm (Early blight)',
    'Tomato_Healthy': 'Lá cà chua khỏe mạnh',
    'Tomato_Septoria_leaf_spot': 'Bệnh đốm lá Septoria',
    'Tomato_Spider_mites': 'Bệnh nhện đỏ (Spider mites)',
    'Tomato_Bacterial_spot': 'Bệnh đốm vi khuẩn',
    'Tomato_Target_spot': 'Bệnh đốm đích (Target spot)',
    'Tomato_Leaf_Mold': 'Bệnh mốc lá (Leaf mold)',
    'Tomato_Mosaic_virus': 'Bệnh khảm virus (Mosaic virus)',
    'Tomato_Yellow_Leaf_Curl_Virus': 'Bệnh xoăn lá vàng (Yellow leaf curl)',
    'Tomato_Leaf_Minor': 'Bệnh bướu lá (Leaf minor)',
    'Tomato_Yellow': 'Lá vàng bất thường',
    // ── ArgoPestOnnx labels ──
    'NoPest': 'Không có sâu bệnh',
    'Pest': 'Có côn trùng gây hại',
    'Healthy': 'Cây khỏe mạnh',
    'nopest': 'Không có sâu bệnh',
    'pest': 'Có côn trùng gây hại',
    'healthy': 'Cây khỏe mạnh',
    'healthyplant': 'Cây khỏe mạnh',
    'non_pest': 'Không có sâu bệnh',
  };

  // Tra cứu chính xác trước
  if (map.containsKey(trimmed)) return map[trimmed]!;

  // Tra cứu không phân biệt hoa/thường
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == trimmed.toLowerCase()) {
      return entry.value;
    }
  }

  // Fallback: làm sạch chuỗi gốc
  var cleaned = trimmed;
  for (final prefix in ['Tomato_', 'ArgoPest_']) {
    if (cleaned.startsWith(prefix)) {
      cleaned = cleaned.substring(prefix.length);
    }
  }
  // Tách underscore → space, capitalize first letter
  final parts = cleaned.split('_');
  if (parts.length > 1) {
    cleaned = parts
        .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }
  return cleaned;
}

