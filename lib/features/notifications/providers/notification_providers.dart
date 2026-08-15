library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/notification_model.dart';
import '../../../core/api/services/notification_api_service.dart';

/// Notifications list — page 1, size 50.
final notificationsListProvider =
    FutureProvider.autoDispose<NotificationPage>((ref) async {
  final api = ref.read(notificationApiServiceProvider);
  return api.list(pageNumber: 1, pageSize: 50);
});

/// Unread badge count.
final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final api = ref.read(notificationApiServiceProvider);
  return api.unreadCount();
});

/// Convenience: derived "unread list" from page 1 — không thêm REST call.
final unreadNotificationsProvider =
    Provider.autoDispose<List<NotificationModel>>((ref) {
  final page = ref.watch(notificationsListProvider);
  return page.maybeWhen(
    data: (p) => p.items.where((n) => n.isUnread).toList(),
    orElse: () => const [],
  );
});

/// Filter notifications by category: All / Tasks / Alerts / Experiments / System.
enum NotificationCategory { all, task, alert, experiment, system, measurement }

final notificationCategoryFilterProvider =
    StateProvider<NotificationCategory>((ref) => NotificationCategory.all);

final filteredNotificationsProvider =
    Provider.autoDispose<List<NotificationModel>>((ref) {
  final page = ref.watch(notificationsListProvider);
  final cat = ref.watch(notificationCategoryFilterProvider);
  return page.maybeWhen(
    data: (p) {
      if (cat == NotificationCategory.all) return p.items;
      final key = switch (cat) {
        NotificationCategory.task => 'task',
        NotificationCategory.alert => 'alert',
        NotificationCategory.experiment => 'experiment',
        NotificationCategory.system => 'system',
        NotificationCategory.measurement => 'measurement',
        _ => '',
      };
      return p.items
          .where((n) => n.type.toLowerCase() == key)
          .toList(growable: false);
    },
    orElse: () => const [],
  );
});

/// Mark one notification as read; invalidate list + count providers.
final markNotificationReadProvider =
    Provider.autoDispose<Future<void> Function(String)>((ref) {
  return (String id) async {
    await ref.read(notificationApiServiceProvider).markRead(id);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  };
});

/// Mark all notifications as read.
final markAllNotificationsReadProvider =
    Provider.autoDispose<Future<void> Function()>((ref) {
  return () async {
    await ref.read(notificationApiServiceProvider).markAllRead();
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  };
});
