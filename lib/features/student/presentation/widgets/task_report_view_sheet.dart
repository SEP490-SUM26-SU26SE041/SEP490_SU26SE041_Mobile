import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/models/growth_task_model.dart';
import '../../../../shared/widgets/snms_card.dart';
import '../../../tasks/data/metric_catalog.dart';
import '../../../tasks/providers/measurement_definition_provider.dart';
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
                  Text('Lịch sử báo cáo',
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

    // Load task images để hiển thị trong report view.
    final imagesAsync = ref.watch(taskImagesByTaskProvider(taskId));
    final reportImages = imagesAsync.maybeWhen(
      data: (list) => list
          .where((img) => img.reportId == report.id && img.imageUrl.isNotEmpty)
          .toList(),
      orElse: () => <TaskImageModel>[],
    );

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(77),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(report.description, style: tt.bodyMedium),
          ),
          if (rd != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Chi tiết kết quả',
                style: tt.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ..._buildResultRows(rd, defMap, tt, cs),
          ],
          if (reportImages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ImagesSection(images: reportImages, tt: tt, cs: cs),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildResultRows(
    Map<String, dynamic> rd,
    Map<String, MeasurementDefinitionInfo>? defMap,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    String? v(String k) {
      final raw = rd[k];
      if (raw == null) return null;
      final s = raw.toString();
      return s.isEmpty ? null : s;
    }

    void add(String label, String? value) {
      if (value == null || value.isEmpty) return;
      rows.add(_Row(label: label, value: value, tt: tt, cs: cs));
      rows.add(const SizedBox(height: AppSpacing.xs));
    }

    add('Số cây đã xử lý',
        v('plantsWatered') ?? v('fertilizedPlantCount') ?? v('plantCount'));
    add('Lượng nước / phân bón', v('waterAmount') ?? v('fertilizerAmount'));
    add('Tình trạng', v('condition') ?? v('healthStatus'));
    add('Số cây héo', v('plantsWilting'));
    add('Hành động', v('action'));
    add('Sản lượng thu hoạch', v('plantsHarvested'));
    add('Khối lượng thu hoạch', v('harvestWeight'));
    add('Chiều cao cây', v('plantHeight') ?? v('chieuCaoCm'));
    add('Số lá', v('leafCount') ?? v('soLaTrungBinh'));
    add('Màu sắc lá', v('leafColor'));
    add('Độ ẩm đất', v('soilMoistureAfter'));
    add('Thiết bị kiểm tra', v('inspectedDevices'));

    // Map metric name + unit cho các keys dạng `def_<uuid>` / `custom_<name>`.
    if (rd.isNotEmpty) {
      rd.forEach((k, val) {
        if (k.startsWith('def_') || k.startsWith('custom_')) {
          final s = val?.toString() ?? '';
          if (s.isEmpty) return;

          String label;
          if (k.startsWith('custom_')) {
            // custom_<fieldName> → dùng trực tiếp fieldName
            final fieldName = k.substring('custom_'.length);
            label = 'Tùy chỉnh: $fieldName';
          } else {
            // def_<uuid> → tìm trong definition map
            final definitionId = k.substring('def_'.length);
            final info = defMap?[definitionId];
            if (info != null && info.metricName.isNotEmpty) {
              final unit = info.unit;
              // Map sang label VN qua catalog; fallback dùng metricName thô.
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
              // Không resolve được từ API: detect theo value để gợi ý.
              final guessed = _guessMetricFromValue(s);
              if (guessed != null) {
                label = guessed.label;
              } else {
                // Fallback cuối: UUID ngắn gọn (8 ký tự đầu).
                label = 'Chỉ số (${_shortId(definitionId)})';
              }
            }
          }
          add(label, s);
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

  /// Rút gọn UUID cho dễ đọc: `def_73a1c433-...` → `73a1c433`.
  static String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  /// Gợi ý metric dựa trên giá trị đo (khi không có definition trong cache).
  /// Quy tắc:
  /// - Có "cm" trong value → Chiều cao
  /// - Có "lá"/"la"/"leaf" → Số lá
  /// - Có "%" → Phần trăm (tỷ lệ sống / đậu quả / độ ẩm)
  /// - Có "kg"/"g" → Khối lượng
  /// - Có "L"/"lít" → Lượng nước
  static MetricDisplay? _guessMetricFromValue(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;
    // Số kèm đơn vị → so sánh exact unit.
    if (RegExp(r'\bcm\b|centimeter|xentimet').hasMatch(v)) {
      return MetricCatalog.lookup('height');
    }
    if (RegExp(r'\blá\b|\bla\b|\bleaf').hasMatch(v)) {
      return MetricCatalog.lookup('leafCount');
    }
    if (RegExp(r'%').hasMatch(v)) {
      // Có thể là tỷ lệ sống / đậu quả / độ ẩm đất. Trả chung "Chỉ số (%)".
      return const MetricDisplay(
          label: 'Chỉ số (%)', unit: '%', icon: 'percent');
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

/// Hiển thị grid ảnh đính kèm trong report view (read-only).
class _ImagesSection extends StatelessWidget {
  const _ImagesSection({
    required this.images,
    required this.tt,
    required this.cs,
  });
  final List<TaskImageModel> images;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
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
              child: Text('${images.length}',
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
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => _ImageTile(
              image: images[i],
              tt: tt,
              cs: cs,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile(
      {required this.image, required this.tt, required this.cs});
  final TaskImageModel image;
  final TextTheme tt;
  final ColorScheme cs;

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
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
            if (image.description != null && image.description!.isNotEmpty)
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
                    image.description!,
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

class _Row extends StatelessWidget {
  const _Row(
      {required this.label,
      required this.value,
      required this.tt,
      required this.cs});
  final String label;
  final String value;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withAlpha(153))),
        ),
        Expanded(
          child: Text(value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
