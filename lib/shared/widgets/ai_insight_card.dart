import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';

class AIInsightCard extends StatefulWidget {
  const AIInsightCard({super.key, required this.insight, this.onTap, this.insights});

  final String insight;
  final VoidCallback? onTap;
  final List<String>? insights;

  @override
  State<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<AIInsightCard>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _insightController;
  late Animation<double> _insightAnim;
  late AnimationController _iconController;
  late Animation<double> _iconAnim;
  late Animation<double> _iconRotateAnim;

  final List<String> _insights = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _insights.add(widget.insight);
    if (widget.insights != null) {
      _insights.addAll(widget.insights!);
    }

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.2, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: AppCurve.standard),
    );

    _insightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _insightAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _insightController, curve: AppCurve.standard),
    );
    _insightController.repeat();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _iconAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: AppCurve.standard),
    );
    _iconRotateAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.linear),
    );

    _insightController.addListener(() {
      if (_insightController.value >= 0.95 && _insights.length > 1) {
        _cycleInsight();
      }
    });
  }

  void _cycleInsight() {
    if (_insights.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _insights.length;
    });
    _insightController.forward(from: 0);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _insightController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  String get _currentInsight => _insights[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _insightAnim, _iconAnim]),
      builder: (context, child) {
        return AnimatedContainer(
          duration: AppDuration.quick,
          curve: AppCurve.standard,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Color.lerp(
                          AppColors.aiInsightBg,
                          AppColors.cardDark,
                          1 - _glowAnim.value,
                        )!,
                        AppColors.cardDark,
                      ]
                    : [
                        Color.lerp(
                          AppColors.aiInsightBg.withAlpha(40),
                          AppColors.cardLight,
                          1 - _glowAnim.value,
                        )!,
                        AppColors.cardLight,
                      ],
              ),
              borderRadius: AppRadius.heroRadius,
              border: Border.all(
                color: AppColors.aiInsight.withAlpha((_glowAnim.value * 60).toInt()),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aiInsight.withAlpha((_glowAnim.value * 25).toInt()),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.heroRadius,
              child: InkWell(
                onTap: widget.onTap ?? () => _cycleInsight(),
                borderRadius: AppRadius.heroRadius,
                splashColor: AppColors.aiInsight.withAlpha(13),
                highlightColor: AppColors.aiInsight.withAlpha(8),
                child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    _AnimatedAIIcon(
                      anim: _iconAnim,
                      rotate: _iconRotateAnim,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.aiInsight.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppColors.aiInsight,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI INSIGHT',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.aiInsight,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (_insights.length > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.aiInsight.withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (int i = 0; i < _insights.length; i++) ...[
                                        if (i > 0) const SizedBox(width: 4),
                                        AnimatedContainer(
                                          duration: AppDuration.normal,
                                          width: i == _currentIndex ? 8 : 4,
                                          height: i == _currentIndex ? 8 : 4,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: i == _currentIndex
                                                ? AppColors.aiInsight
                                                : AppColors.aiInsight.withAlpha(77),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AnimatedSwitcher(
                            duration: AppDuration.slow,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _currentInsight,
                              key: ValueKey(_currentIndex),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                height: 1.5,
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedAIIcon extends StatelessWidget {
  const _AnimatedAIIcon({required this.anim, required this.rotate});
  final Animation<double> anim;
  final Animation<double> rotate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.aiInsight.withAlpha((anim.value * 60 + 40).toInt()),
            AppColors.aiInsight.withAlpha((anim.value * 40 + 20).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.small),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiInsight.withAlpha((anim.value * 40).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotate.value * 0.05,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withAlpha((anim.value * 40 + 200).toInt()),
              size: 24,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Transform.rotate(
              angle: -rotate.value * 0.08,
              child: Opacity(
                opacity: anim.value * 0.8,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withAlpha(180),
                  size: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
