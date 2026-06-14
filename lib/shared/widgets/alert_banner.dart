import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';

enum AlertLevel { info, warning, critical }

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    required this.level,
    this.onTap,
    this.onDismiss,
  });

  final String message;
  final AlertLevel level;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  Color get _color => switch (level) {
    AlertLevel.info     => AppColors.info,
    AlertLevel.warning  => AppColors.warning,
    AlertLevel.critical => AppColors.error,
  };

  Color get _bgColor => switch (level) {
    AlertLevel.info     => const Color(0xFFF0F7FF),
    AlertLevel.warning  => const Color(0xFFFFF8F0),
    AlertLevel.critical => const Color(0xFFFFF5F5),
  };

  Color get _darkBgColor => switch (level) {
    AlertLevel.info     => const Color(0xFF0D1B2A),
    AlertLevel.warning  => const Color(0xFF1A1200),
    AlertLevel.critical => const Color(0xFF1A0D0D),
  };

  IconData get _icon => switch (level) {
    AlertLevel.info     => Icons.info_rounded,
    AlertLevel.warning  => Icons.warning_amber_rounded,
    AlertLevel.critical => Icons.error_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _darkBgColor : _bgColor;
    final color = _color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.quick,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
            color: color.withAlpha(isDark ? 77 : 51),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 20 : 13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 38 : 30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon, color: color, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: tt.bodySmall?.copyWith(
                  color: isDark ? Colors.white.withAlpha(230) : color.withAlpha(230),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.close_rounded, color: color, size: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
