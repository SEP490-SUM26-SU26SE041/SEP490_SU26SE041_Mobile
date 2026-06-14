import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';

class KPITile extends StatefulWidget {
  const KPITile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.trend,
    this.isAlert = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String? trend;
  final bool isAlert;
  final VoidCallback? onTap;

  @override
  State<KPITile> createState() => _KPITileState();
}

class _KPITileState extends State<KPITile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendPositive = widget.trend?.startsWith('+') ?? false;
    final accentColor = widget.isAlert ? AppColors.warning : AppColors.primary;

    // Colored shadow toward accent
    final shadowColor = isDark
        ? accentColor.withAlpha(15)
        : accentColor.withAlpha(8);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: AppDuration.quick,
          curve: AppCurve.standard,
          transform: Matrix4.translationValues(0.0, _isPressed ? 1.0 : 0.0, 0.0),
          decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: AppRadius.cardRadius,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.cardRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.cardRadius,
            splashColor: accentColor.withAlpha(13),
            highlightColor: accentColor.withAlpha(8),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withAlpha(30),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(widget.icon, size: 20, color: accentColor),
                      ),
                      if (widget.trend != null)
                        _TrendBadge(trend: widget.trend!, positive: trendPositive),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.value,
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.unit,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withAlpha(128),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.label,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(153),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend, required this.positive});
  final String trend;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            trend,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
