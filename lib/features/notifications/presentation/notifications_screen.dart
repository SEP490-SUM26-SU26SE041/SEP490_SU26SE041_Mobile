import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/notification_card.dart';
import '../../experiments/providers/experiment_provider.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: cs.surface,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
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
              labelStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Alerts'),
                Tab(text: 'Updates'),
              ],
            ),
          ),
        ),
      ),
      body: notifications.when(
        data: (items) {
          return TabBarView(
            controller: _tabController,
            children: [
              _NotificationList(items: items, filter: null),
              _NotificationList(
                items: items,
                filter: NotificationType.alert,
              ),
              _NotificationList(
                items: items,
                filter: NotificationType.taskUpdate,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items, required this.filter});
  final List<NotificationItem> items;
  final NotificationType? filter;

  @override
  Widget build(BuildContext context) {
    final filtered = filter == null
        ? items
        : items.where((n) => n.type == filter).toList();

    if (filtered.isEmpty) {
      return _EmptyState(filter: filter);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => NotificationCard(
        item: filtered[index],
        onTap: () {
          if (filtered[index].linkedRoute != null) {
            context.go(filtered[index].linkedRoute!);
          }
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final NotificationType? filter;

  String get _label => switch (filter) {
    NotificationType.alert      => 'No alerts',
    NotificationType.taskUpdate => 'No updates',
    NotificationType.system     => 'No system notifications',
    null                        => 'No notifications',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: cs.onSurface.withAlpha(51),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _label,
            style: tt.bodyLarge?.copyWith(color: cs.onSurface.withAlpha(128)),
          ),
        ],
      ),
    );
  }
}
