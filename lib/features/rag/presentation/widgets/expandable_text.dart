import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// ExpandableText — inline expand/collapse cho text dài.
///
/// Spec:
/// - Collapse: show tối đa [maxCollapsedLines] dòng + ellipsis.
/// - Expand: show full text + scroll đến cuối.
/// - Auto detect overflow: nếu text < [maxCollapsedLines] dòng → không hiện button.
///
/// Theme-aware: text + button dùng colorScheme.
class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.maxCollapsedLines = 2,
    this.expandLabel = 'Xem thêm',
    this.collapseLabel = 'Thu gọn',
  });

  final String text;
  final TextStyle? style;
  final int maxCollapsedLines;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final baseStyle = widget.style ?? tt.bodyMedium!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tính toán overflow thật.
        final span = TextSpan(text: widget.text, style: baseStyle);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxCollapsedLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topLeft,
              child: Text(
                widget.text,
                style: baseStyle,
                maxLines: _expanded ? null : widget.maxCollapsedLines,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (isOverflow) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? widget.collapseLabel : widget.expandLabel,
                      style: tt.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}