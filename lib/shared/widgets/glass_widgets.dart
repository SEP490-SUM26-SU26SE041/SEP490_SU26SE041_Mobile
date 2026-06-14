import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation = 2.0,
    this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (widget.onTap != null) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? AppRadius.medium;

    final surfaceColor = widget.backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final borderColor = isDark
        ? AppColors.borderDark.withAlpha(140)
        : AppColors.borderLight.withAlpha(160);

    final innerBorderColor = isDark
        ? Colors.white.withAlpha(18)
        : Colors.white.withAlpha(140);

    final shadowColor = isDark
        ? AppColors.primary.withAlpha(10)
        : AppColors.primary.withAlpha(7);

    final shimmerColor = isDark
        ? Colors.white.withAlpha(8)
        : Colors.white.withAlpha(60);

    Widget content = AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: widget.elevation * 6,
                offset: Offset(0, widget.elevation * 1.5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner highlight border (top edge) — simulates edge refraction
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      colors: [
                        innerBorderColor,
                        innerBorderColor.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner shadow (bottom edge) for depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        isDark
                            ? Colors.black.withAlpha(8)
                            : Colors.black.withAlpha(4),
                      ],
                    ),
                  ),
                ),
              ),
              // Shimmer sweep overlay
              if (_isPressed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          shimmerColor,
                          Colors.transparent,
                        ],
                        stops: [
                          (_shimmerCtrl.value - 0.3).clamp(0.0, 1.0),
                          _shimmerCtrl.value,
                          (_shimmerCtrl.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  ),
                ),
              // Content
              Positioned.fill(
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: AppDuration.quick,
          curve: AppCurve.standard,
          transform: Matrix4.translationValues(0.0, _isPressed ? 1.0 : 0.0, 0.0),
          child: content,
        ),
      );
    }
    return content;
  }
}

class GradientHeader extends StatefulWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;

  @override
  State<GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<GradientHeader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.lerp(
                        const Color(0xFF1F4D3D),
                        const Color(0xFF2D6650),
                        _pulseAnim.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF3D7A5D),
                        const Color(0xFF4A8A6A),
                        _pulseAnim.value,
                      )!,
                    ]
                  : [
                      const Color(0xFF1F4D3D),
                      const Color(0xFF3D7A5D),
                    ],
            ),
            borderRadius: AppRadius.cardRadius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F4D3D).withAlpha(60 + (_pulseAnim.value * 20).toInt()),
                blurRadius: 16.0 + _pulseAnim.value * 8,
                offset: Offset(0, 6.0 + _pulseAnim.value * 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                widget.onTrailingTap != null
                    ? GestureDetector(
                        onTap: widget.onTrailingTap,
                        child: widget.trailing!,
                      )
                    : widget.trailing!,
            ],
          ),
        );
      },
    );
  }
}
