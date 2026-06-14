import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';

class SNMSCard extends StatefulWidget {
  const SNMSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation = 0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  State<SNMSCard> createState() => _SNMSCardState();
}

class _SNMSCardState extends State<SNMSCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = widget.borderColor ?? cs.outline;

    final shadowColor = isDark
        ? AppColors.primary.withAlpha(10)
        : AppColors.primary.withAlpha(6);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        child: Transform.translate(
          offset: Offset(0, _isPressed ? 1.5 : 0.0),
          child: AnimatedContainer(
            duration: AppDuration.quick,
            curve: AppCurve.standard,
            margin: widget.margin ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Theme.of(context).cardTheme.color,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: _isHovered
                    ? (widget.borderColor ?? AppColors.primary).withAlpha(180)
                    : border,
                width: _isHovered ? widget.borderWidth + 0.5 : widget.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 6 : 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.cardRadius,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: AppRadius.cardRadius,
                splashColor: AppColors.primary.withAlpha(13),
                highlightColor: AppColors.primary.withAlpha(8),
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
