import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/models/notification_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../features/notifications/providers/notification_providers.dart';

/// Compact bell icon + unread badge used in AppBar / dashboard headers.
/// Tap → navigate to /notifications (full screen list).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.notifications_rounded,
                color: AppColors.primary, size: 20),
          ),
          if (unread > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Inline notification card with priority iconography + tap-to-read.
class NotificationListCard extends ConsumerWidget {
  const NotificationListCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;

  IconData get _icon => switch (notification.type.toLowerCase()) {
        'task' => Icons.assignment_rounded,
        'alert' => Icons.warning_amber_rounded,
        'experiment' => Icons.science_rounded,
        'measurement' => Icons.straighten_rounded,
        _ => Icons.notifications_rounded,
      };

  Color get _color {
    if (notification.isCritical) return AppColors.error;
    if (notification.isHigh) return AppColors.warning;
    return switch (notification.type.toLowerCase()) {
      'task' => AppColors.primary,
      'experiment' => AppColors.info,
      'measurement' => AppColors.success,
      'alert' => AppColors.warning,
      _ => AppColors.info,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ??
          () async {
            if (notification.isUnread) {
              await ref
                  .read(markNotificationReadProvider)(notification.id);
            }
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? _color.withAlpha(15)
              : cs.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: notification.isUnread
                  ? _color.withAlpha(60)
                  : cs.outline.withAlpha(40)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withAlpha(25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: notification.isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: cs.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text(formatTime(notification.createdAt),
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withAlpha(128))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(179),
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (notification.isUnread)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
