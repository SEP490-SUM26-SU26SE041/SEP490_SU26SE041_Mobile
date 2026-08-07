import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/models/experiment_model.dart';

class ExperimentCard extends StatefulWidget {
  const ExperimentCard({
    super.key,
    required this.title,
    required this.status,
    required this.startDate,
    required this.zone,
    required this.progress,
    this.studentCount = 0,
    this.onTap,
    this.experimentCode,
    this.groupCount,
  });

  final String title;
  final ExperimentStatus status;
  final DateTime startDate;
  final String zone;
  final double progress;
  final int studentCount;
  final VoidCallback? onTap;
  final String? experimentCode;
  final int? groupCount;

  Color get _statusColor => switch (status) {
    ExperimentStatus.active    => AppColors.experimentActive,
    ExperimentStatus.planning  => AppColors.experimentPlanning,
    ExperimentStatus.completed => AppColors.experimentCompleted,
    ExperimentStatus.paused    => AppColors.experimentPaused,
    ExperimentStatus.draft     => AppColors.textSecondaryLight,
    ExperimentStatus.pending   => AppColors.warning,
  };

  String get _statusLabel => switch (status) {
    ExperimentStatus.active    => 'Active',
    ExperimentStatus.planning  => 'Planning',
    ExperimentStatus.completed => 'Completed',
    ExperimentStatus.paused    => 'Paused',
    ExperimentStatus.draft     => 'Draft',
    ExperimentStatus.pending   => 'Pending',
  };

  @override
  State<ExperimentCard> createState() => _ExperimentCardState();
}

class _ExperimentCardState extends State<ExperimentCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = widget._statusColor;

    // Colored shadow toward status color
    final shadowColor = isDark
        ? statusColor.withAlpha(12)
        : statusColor.withAlpha(7);

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
          border: Border.all(
            color: _isPressed
                ? statusColor.withAlpha(80)
                : cs.outline.withAlpha(isDark ? 100 : 50),
            width: _isPressed ? 1.2 : 0.8,
          ),
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
            splashColor: statusColor.withAlpha(13),
            highlightColor: statusColor.withAlpha(8),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withAlpha(30),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.science_rounded,
                          size: 22,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.experimentCode != null)
                              Text(
                                widget.experimentCode!,
                                style: tt.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            Text(
                              widget.title,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusChip(label: widget._statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _MetaChip(
                        icon: Icons.eco_outlined,
                        label: widget.zone,
                        tt: tt,
                        cs: cs,
                      ),
                      _MetaChip(
                        icon: Icons.people_outline_rounded,
                        label: '${widget.studentCount} students',
                        tt: tt,
                        cs: cs,
                      ),
                      if (widget.groupCount != null)
                        _MetaChip(
                          icon: Icons.group_work_outlined,
                          label: '${widget.groupCount} groups',
                          tt: tt,
                          cs: cs,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: cs.onSurface.withAlpha(102),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(widget.startDate),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withAlpha(102),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(widget.progress * 100).toInt()}%',
                        style: tt.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: statusColor.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      minHeight: 6,
                    ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.tt, required this.cs});
  final IconData icon;
  final String label;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.outline.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(128)),
          const SizedBox(width: 4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
          ),
        ],
      ),
    );
  }
}
