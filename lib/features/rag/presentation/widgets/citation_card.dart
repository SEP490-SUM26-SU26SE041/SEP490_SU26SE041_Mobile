import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/rag_models.dart';
import 'expandable_text.dart';

/// Citation Card (spec mục 4.3):
///   📄 file_name
///   📑 Chương X
///   📍 Trang Y · Mục Z · knowledge_group
///   ─────
///   "Text nguyên văn..."  (ExpandableText: Xem thêm / Thu gọn)
///   [Sao chép citation]
class CitationCard extends StatelessWidget {
  const CitationCard({super.key, required this.source, this.index});

  final RagSource source;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (index != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$index',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  '📄 ${source.fileName}',
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (source.title != null && source.title!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📑 ${source.title}',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(179)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (source.pageNumber != null ||
              (source.section != null && source.section!.isNotEmpty) ||
              source.knowledgeGroup != null) ...[
            const SizedBox(height: 4),
            Text(
              '📍 ${[
                if (source.pageNumber != null) 'Trang ${source.pageNumber}',
                if (source.section != null && source.section!.isNotEmpty)
                  'Mục ${source.section}',
                if (source.knowledgeGroup != null)
                  '${KnowledgeGroup.fromValue(source.knowledgeGroup).emoji} '
                      '${KnowledgeGroup.fromValue(source.knowledgeGroup).label}',
              ].join(' · ')}',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Quote box với ExpandableText (Xem thêm / Thu gọn nếu > 2 dòng)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: ExpandableText(
              text: '"${source.text}"',
              maxCollapsedLines: 2,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withAlpha(204),
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Action row: copy + view full
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _copyCitation(context),
                icon: const Icon(Icons.content_copy_rounded, size: 14),
                label: const Text('Sao chép citation'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openDetail(context, tt, cs),
                icon: const Icon(Icons.open_in_full_rounded, size: 14),
                label: const Text('Xem chi tiết'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyCitation(BuildContext context) {
    final text = source.citationLabel;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép citation'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Modal full-screen với toàn bộ nội dung citation.
  void _openDetail(BuildContext context, TextTheme tt, ColorScheme cs) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.outline.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (index != null)
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$index',
                            style: tt.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          '📄 ${source.fileName}',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (source.title != null && source.title!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '📑 ${source.title}',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (source.pageNumber != null)
                        _Chip(
                          icon: Icons.book_rounded,
                          text: 'Trang ${source.pageNumber}',
                          tt: tt,
                          cs: cs,
                        ),
                      if (source.section != null && source.section!.isNotEmpty)
                        _Chip(
                          icon: Icons.list_alt_rounded,
                          text: 'Mục ${source.section}',
                          tt: tt,
                          cs: cs,
                        ),
                      if (source.knowledgeGroup != null)
                        _Chip(
                          icon: Icons.category_rounded,
                          text:
                              '${KnowledgeGroup.fromValue(source.knowledgeGroup).emoji} ${KnowledgeGroup.fromValue(source.knowledgeGroup).label}',
                          tt: tt,
                          cs: cs,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nội dung trích nguyên văn',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurface.withAlpha(153),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withAlpha(80),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          source.text,
                          style: tt.bodyMedium?.copyWith(
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${source.text.length} ký tự · ${source.text.split(RegExp(r"\s+")).length} từ',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(128),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Đóng'),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: source.citationLabel),
                            );
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép citation'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.content_copy_rounded,
                              size: 16),
                          label: const Text('Sao chép citation'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.tt,
    required this.cs,
  });

  final IconData icon;
  final String text;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(160),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(153)),
          const SizedBox(width: 4),
          Text(
            text,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withAlpha(179),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
