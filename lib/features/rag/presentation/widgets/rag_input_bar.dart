import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Input bar với hint text động theo role.
class RagInputBar extends StatefulWidget {
  const RagInputBar({
    super.key,
    required this.onSend,
    required this.isSending,
    required this.hintText,
  });

  final ValueChanged<String> onSend;
  final bool isSending;
  final String hintText;

  @override
  State<RagInputBar> createState() => _RagInputBarState();
}

class _RagInputBarState extends State<RagInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outline.withAlpha(77)),
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                enabled: !widget.isSending,
                style: tt.bodyMedium,
                maxLines: 4,
                minLines: 1,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withAlpha(77),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hasText && !widget.isSending
                  ? AppColors.primary
                  : cs.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              onPressed: _hasText && !widget.isSending ? _send : null,
              icon: widget.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
