import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animation.dart';

enum NotificationType { alert, taskUpdate, system }

enum AlertSeverity { low, medium, high, critical }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.severity,
    this.linkedRoute,
  });
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final AlertSeverity? severity;
  final String? linkedRoute;
}

class NotificationCard extends StatefulWidget {
  const NotificationCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final NotificationItem item;
  final VoidCallback? onTap;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _isPressed = false;

  Color get _typeColor => switch (widget.item.type) {
    NotificationType.alert => widget.item.severity == AlertSeverity.high || widget.item.severity == AlertSeverity.critical
        ? AppColors.error : AppColors.warning,
    NotificationType.taskUpdate => AppColors.info,
    NotificationType.system => AppColors.accent,
  };

  IconData get _icon => switch (widget.item.type) {
    NotificationType.alert      => Icons.warning_amber_rounded,
    NotificationType.taskUpdate => Icons.task_alt_rounded,
    NotificationType.system     => Icons.info_outline_rounded,
  };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor;

    final shadowColor = isDark
        ? typeColor.withAlpha(12)
        : typeColor.withAlpha(7);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppDuration.quick,
        curve: AppCurve.standard,
        transform: Matrix4.translationValues(0.0, _isPressed ? 1.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
            color: widget.item.isRead
                ? Colors.transparent
                : typeColor.withAlpha(77),
            width: widget.item.isRead ? 0.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.chipRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.chipRadius,
            splashColor: typeColor.withAlpha(13),
            highlightColor: typeColor.withAlpha(8),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(
                        color: typeColor.withAlpha(30),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(_icon, size: 18, color: typeColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.title,
                                style: tt.titleSmall?.copyWith(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                  fontWeight: widget.item.isRead ? FontWeight.w500 : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!widget.item.isRead)
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.item.message,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withAlpha(153),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatTime(widget.item.createdAt),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withAlpha(102),
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
      ),
    );
  }
}
