import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/rag_models.dart';
import 'citation_card.dart';
import 'expandable_text.dart';

/// Message bubble cho assistant (có citations + retrieval-only mode).
class RagAssistantBubble extends StatelessWidget {
  const RagAssistantBubble({
    super.key,
    required this.message,
    required this.isRetrievalOnly,
  });

  final RagStoredMessage message;
  final bool isRetrievalOnly;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final hasCitations = message.sources.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.outline.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRetrievalOnly && hasCitations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 14, color: AppColors.info),
                          const SizedBox(width: 4),
                          Text(
                            'Trích từ tài liệu',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ExpandableText(
                    text: message.content,
                    maxCollapsedLines: 6,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      height: 1.5,
                    ),
                  ),
                  if (hasCitations) ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < message.sources.length; i++)
                      CitationCard(
                        source: message.sources[i],
                        index: i + 1,
                      ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  // Footer: timestamp + view full detail
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.ts),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withAlpha(128),
                          fontSize: 10,
                        ),
                      ),
                      if (hasCitations || message.content.length > 400)
                        TextButton.icon(
                          onPressed: () => _openDetail(context, tt, cs),
                          icon: const Icon(Icons.open_in_full_rounded, size: 12),
                          label: const Text('Xem chi tiết'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Modal full-screen với toàn bộ nội dung answer + citations.
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
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.98,
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Chi tiết câu trả lời',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${message.content.length} ký tự · ${message.content.split(RegExp(r"\s+")).length} từ · ${message.sources.length} nguồn',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(128),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            message.content,
                            style: tt.bodyMedium?.copyWith(height: 1.6),
                          ),
                          if (message.sources.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              '📚 Nguồn trích dẫn (${message.sources.length})',
                              style: tt.labelMedium?.copyWith(
                                color: cs.onSurface.withAlpha(153),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (var i = 0; i < message.sources.length; i++)
                              CitationCard(
                                source: message.sources[i],
                                index: i + 1,
                              ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
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
                            final buffer = StringBuffer()
                              ..writeln(message.content)
                              ..writeln()
                              ..writeln('--- Citations ---');
                            for (var i = 0;
                                i < message.sources.length;
                                i++) {
                              final s = message.sources[i];
                              buffer
                                ..writeln('[${i + 1}] ${s.citationLabel}')
                                ..writeln('"${s.text}"')
                                ..writeln();
                            }
                            Clipboard.setData(
                              ClipboardData(text: buffer.toString()),
                            );
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '📋 Đã copy toàn bộ nội dung + citations'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.content_copy_rounded,
                              size: 16),
                          label: const Text('Copy tất cả'),
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

/// Message bubble cho user.
class RagUserBubble extends StatelessWidget {
  const RagUserBubble({super.key, required this.message});

  final RagStoredMessage message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: tt.bodyMedium?.copyWith(
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.ts.hour.toString().padLeft(2, '0')}:${message.ts.minute.toString().padLeft(2, '0')}',
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white.withAlpha(153),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
