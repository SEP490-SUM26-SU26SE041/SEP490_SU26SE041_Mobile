import 'package:flutter/material.dart';
import '../../../../core/api/models/task_model.dart' as api;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'task_visual.dart';

/// Premium task card — gradient accent strip + avatar icon + deadline chip + progress bar.
///
/// Không phụ thuộc Riverpod (chỉ nhận domain model) → dùng lại được ở Student,
/// Technician, Experiment Detail Tab, AI Scan recommendation, …
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.hasReport = false,
    this.dense = false,
  });

  final api.TaskModel task;
  final VoidCallback onTap;

  /// Badge "Đã báo cáo" — gắn từ danh sách history.
  final bool hasReport;

  /// Compact mode cho embedded list (Experiment detail, dashboard…).
  final bool dense;

  bool get _hasBatch => (task.batchCode ?? '').isNotEmpty;
  bool get _hasExperiment => (task.experimentCode ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final spec = getTaskVisualSpec(task.taskType);
    final statusSpec = getStatusPillSpec(task.status);
    final deadline = computeDeadlineChip(task.dueDate, task.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(taskCardRadius),
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(taskCardRadius),
                border:
                    Border.all(color: cs.outline.withAlpha(60), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: taskCardHPadding,
                vertical: taskCardVPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AvatarBadge(spec: spec),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: tt.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: dense ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!dense) ...[
                              const SizedBox(height: 2),
                              Text(
                                spec.label,
                                style: tt.labelMedium?.copyWith(
                                  color: spec.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _StatusPill(spec: statusSpec),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_hasExperiment || _hasBatch)
                    Row(
                      children: [
                        if (_hasExperiment) ...[
                          _InfoChip(
                            icon: Icons.science_rounded,
                            label: task.experimentCode ?? '',
                            color: AppColors.info,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (_hasBatch)
                          _InfoChip(
                            icon: Icons.inventory_2_outlined,
                            label: task.batchCode ?? '',
                            color: AppColors.primary,
                          ),
                        const Spacer(),
                        if (hasReport)
                          const _ReportedBadge(),
                      ],
                    ),
                  if (!dense && (deadline != null || task.description.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (deadline != null) ...[
                            _DeadlineChip(spec: deadline),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (!dense)
                            Expanded(
                              child: _ProgressBar(
                                progress: computeDueProgress(
                                    dueDate: task.dueDate),
                                color: deadline?.isOverdue ?? false
                                    ? AppColors.error
                                    : spec.color,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Accent strip bên trái — định danh trực quan theo type.
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: spec.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(taskCardRadius),
                    bottomLeft: Radius.circular(taskCardRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.spec});
  final TaskVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: spec.accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: spec.color.withAlpha(38), width: 1),
      ),
      child: Icon(spec.icon, color: spec.color, size: 22),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.spec});
  final TaskStatusPillSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 12, color: spec.color),
          const SizedBox(width: 4),
          Text(
            spec.label,
            style: TextStyle(
                color: spec.color,
                fontWeight: FontWeight.w700,
                fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: tt.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.spec});
  final DeadlineChipData spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: spec.color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: spec.color.withAlpha(60)),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
            color: spec.color,
            fontWeight: FontWeight.w700,
            fontSize: 11),
      ),
    );
  }
}

class _ReportedBadge extends StatelessWidget {
  const _ReportedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_rounded, size: 12, color: AppColors.success),
          SizedBox(width: 3),
          Text(
            'Đã báo cáo',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: color.withAlpha(30),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
