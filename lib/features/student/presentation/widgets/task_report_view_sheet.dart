import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/models/task_report_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/snms_card.dart';
import '../../../tasks/providers/task_report_providers.dart';

/// Bottom sheet hiển thị báo cáo đã gửi (read-only).
/// Dùng khi user bấm vào task đã có report.
Future<void> showTaskReportViewSheet(BuildContext context, String taskId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskReportViewSheet(taskId: taskId),
  );
}

class _TaskReportViewSheet extends ConsumerWidget {
  const _TaskReportViewSheet({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final reportAsync = ref.watch(taskReportByTaskProvider(taskId));

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
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
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
                  Text('Báo cáo đã gửi', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text('Không tải được báo cáo', style: tt.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(e.toString(), style: tt.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                data: (report) {
                  if (report == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined, size: 48, color: cs.onSurface.withAlpha(77)),
                            const SizedBox(height: AppSpacing.md),
                            Text('Task này chưa có báo cáo', style: tt.titleMedium),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                    children: [
                      _Header(report: report, tt: tt, cs: cs),
                      const SizedBox(height: AppSpacing.lg),
                      _ReportContent(report: report, tt: tt, cs: cs),
                      if (report.images != null && report.images!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ImagesSection(images: report.images!, tt: tt, cs: cs),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _ReadOnlyBanner(tt: tt, cs: cs),
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
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.taskTitle ?? 'Báo cáo công việc',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gửi bởi ${report.reporterName ?? '—'} • ${formatDateTime(report.reportedAt)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report, required this.tt, required this.cs});
  final TaskReportModel report;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final rd = report.resultData;
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Nội dung báo cáo', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
            child: Text(report.reportText, style: tt.bodyMedium),
          ),
          if (rd != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Chi tiết kết quả', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ..._buildResultRows(rd, tt, cs),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildResultRows(ReportResultData rd, TextTheme tt, ColorScheme cs) {
    final rows = <Widget>[];
    void add(String label, String? value) {
      if (value == null || value.isEmpty) return;
      rows.add(_Row(label: label, value: value, tt: tt, cs: cs));
      rows.add(const SizedBox(height: AppSpacing.xs));
    }

    add('Số cây đã xử lý', rd.plantsWatered?.toString());
    add('Lượng nước / phân bón', rd.waterAmount);
    add('Tình trạng', rd.condition);
    add('Số cây héo', rd.plantsWilting?.toString());
    add('Hành động', rd.action);
    add('Sản lượng thu hoạch', rd.plantsHarvested?.toString());
    add('Khối lượng thu hoạch', rd.harvestWeight);
    if (rd.additionalNotes != null && rd.additionalNotes!.isNotEmpty) {
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
            Expanded(child: Text(rd.additionalNotes!, style: tt.bodySmall)),
          ],
        ),
      ));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return rows;
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.tt, required this.cs});
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
          child: Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
        ),
        Expanded(
          child: Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _ImagesSection extends StatelessWidget {
  const _ImagesSection({required this.images, required this.tt, required this.cs});
  final List<dynamic> images;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Hình ảnh đính kèm (${images.length})', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_rounded, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.onSurface.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: cs.onSurface.withAlpha(128)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mỗi task chỉ được gửi 1 báo cáo. Báo cáo này đã được ghi nhận.',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
            ),
          ),
        ],
      ),
    );
  }
}