import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class AgritechKPITile extends StatefulWidget {
  const AgritechKPITile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.trend,
    this.isAlert = false,
    this.subtitle,
    this.onTap,
    this.index = 0,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String? trend;
  final bool isAlert;
  final String? subtitle;
  final VoidCallback? onTap;
  final int index;

  @override
  State<AgritechKPITile> createState() => _AgritechKPITileState();
}

class _AgritechKPITileState extends State<AgritechKPITile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _countAnim;
  late Animation<double> _fadeSlideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800 + widget.index * 100),
    );
    _countAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeSlideAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _targetValue => int.tryParse(widget.value) ?? 0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.isAlert ? AppColors.warning : AppColors.primary;
    final trendPositive = widget.trend?.startsWith('+') ?? false;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final displayValue = (_countAnim.value * _targetValue).round();
        final slideOffset = (1 - _fadeSlideAnim.value) * 20;

        return Transform.translate(
          offset: Offset(0, slideOffset),
          child: Opacity(
            opacity: _fadeSlideAnim.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: AppRadius.heroRadius,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.outline.withAlpha(isDark ? 20 : 8),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: AppRadius.heroRadius,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: AppRadius.heroRadius,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PremiumIcon(icon: widget.icon, color: accentColor),
                          if (widget.trend != null)
                            _TrendBadge(trend: widget.trend!, positive: trendPositive),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              '$displayValue',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                height: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.unit.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              widget.unit,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withAlpha(102),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.label,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withAlpha(153),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          widget.subtitle!,
                          style: tt.labelSmall?.copyWith(
                            color: accentColor.withAlpha(179),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumIcon extends StatefulWidget {
  const _PremiumIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_PremiumIcon> createState() => _PremiumIconState();
}

class _PremiumIconState extends State<_PremiumIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.color.withAlpha((_pulseAnim.value * 38).toInt()),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: widget.color.withAlpha((_pulseAnim.value * 77).toInt()),
              width: 0.5,
            ),
          ),
          child: Icon(widget.icon, size: 22, color: widget.color),
        );
      },
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
        borderRadius: BorderRadius.circular(AppRadius.xs),
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
