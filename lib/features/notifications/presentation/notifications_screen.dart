import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/models/notification_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final cat = NotificationCategory.values[_tabController.index];
        ref.read(notificationCategoryFilterProvider.notifier).state = cat;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: cs.surface,
        actions: [
          TextButton.icon(
            onPressed: unread == 0
                ? null
                : () => ref.read(markAllNotificationsReadProvider)(),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: Text(
              'Đọc hết',
              style: tt.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: cs.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: cs.onSurface.withAlpha(128),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              labelStyle:
                  tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Tất cả'),
                Tab(text: 'Task'),
                Tab(text: 'Cảnh báo'),
                Tab(text: 'Thực nghiệm'),
                Tab(text: 'Đo lường'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final notificationsAsync = ref.watch(notificationsListProvider);
          return notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              message: 'Không thể tải thông báo',
              onRetry: () => ref.invalidate(notificationsListProvider),
            ),
            data: (page) {
              if (page.items.isEmpty) {
                return _EmptyState(
                  icon: Icons.notifications_off_rounded,
                  message: 'Chưa có thông báo nào',
                );
              }
              final byCategory = <NotificationCategory, List<NotificationModel>>{
                NotificationCategory.all: page.items,
                NotificationCategory.task: [],
                NotificationCategory.alert: [],
                NotificationCategory.experiment: [],
                NotificationCategory.measurement: [],
              };
              for (final n in page.items) {
                switch (n.type.toLowerCase()) {
                  case 'task':
                    byCategory[NotificationCategory.task]!.add(n);
                    break;
                  case 'alert':
                    byCategory[NotificationCategory.alert]!.add(n);
                    break;
                  case 'experiment':
                    byCategory[NotificationCategory.experiment]!.add(n);
                    break;
                  case 'measurement':
                    byCategory[NotificationCategory.measurement]!.add(n);
                    break;
                }
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _NotificationList(items: byCategory[NotificationCategory.all]!),
                  _NotificationList(items: byCategory[NotificationCategory.task]!),
                  _NotificationList(items: byCategory[NotificationCategory.alert]!),
                  _NotificationList(items: byCategory[NotificationCategory.experiment]!),
                  _NotificationList(items: byCategory[NotificationCategory.measurement]!),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});
  final List<NotificationModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_rounded,
        message: 'Không có thông báo nào trong mục này',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notificationsListProvider);
        ref.invalidate(unreadNotificationsCountProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final n = items[i];
          return NotificationListCard(
            notification: n,
            onTap: () async {
              if (n.isUnread) {
                await ref.read(markNotificationReadProvider)(n.id);
              }
              if (!context.mounted) return;
              if (n.referenceTable != null && n.referenceId != null) {
                _navigateToReference(context, n);
              }
            },
          );
        },
      ),
    );
  }

  void _navigateToReference(BuildContext context, NotificationModel n) {
    final table = n.referenceTable!.toLowerCase();
    final id = n.referenceId!;
    switch (table) {
      case 'tasks':
        context.go('/student/tasks/$id');
        break;
      case 'experiments':
        context.go('/experiments/$id');
        break;
      case 'batches':
        context.go('/student/growth');
        break;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: cs.onSurface.withAlpha(80)),
          const SizedBox(height: AppSpacing.md),
          Text(message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(128))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(128))),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
