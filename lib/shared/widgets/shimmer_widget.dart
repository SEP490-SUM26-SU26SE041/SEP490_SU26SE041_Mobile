import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class SNMSShimmer extends StatefulWidget {
  const SNMSShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<SNMSShimmer> createState() => _SNMSShimmerState();
}

class _SNMSShimmerState extends State<SNMSShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEBEBEB),
                Color(0xFFF5F5F5),
                Color(0xFFEBEBEB),
              ],
              stops: [
                (_ctrl.value - 0.4).clamp(0.0, 1.0),
                _ctrl.value,
                (_ctrl.value + 0.4).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SNMSCardSkeleton extends StatelessWidget {
  const SNMSCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.surfaceDark
        : const Color(0xFFEEEEEE);
    final highlightColor = isDark
        ? AppColors.cardDark
        : const Color(0xFFF5F5F5);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(
                width: 44,
                height: 44,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                      width: 140,
                      height: 14,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 8),
                    _ShimmerBox(
                      width: 80,
                      height: 10,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                  ],
                ),
              ),
              _ShimmerBox(
                width: 60,
                height: 24,
                radius: 10,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _ShimmerBox(
                  width: 70,
                  height: 24,
                  radius: 8,
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShimmerBox(
            width: double.infinity,
            height: 6,
            radius: 6,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ],
      ),
    );
  }
}

class SNMSKPISkeleton extends StatelessWidget {
  const SNMSKPISkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.surfaceDark
        : const Color(0xFFEEEEEE);
    final highlightColor = isDark
        ? AppColors.cardDark
        : const Color(0xFFF5F5F5);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(
                width: 40,
                height: 40,
                radius: 10,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              _ShimmerBox(
                width: 40,
                height: 18,
                radius: 8,
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ShimmerBox(
            width: 60,
            height: 28,
            radius: 6,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ShimmerBox(
            width: 90,
            height: 10,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ],
      ),
    );
  }
}

class SNMSListSkeleton extends StatelessWidget {
  const SNMSListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: const SNMSCardSkeleton(),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    this.radius = 4,
  });

  final double width;
  final double height;
  final double radius;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
