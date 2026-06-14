import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../mock/mock_users.dart';
import '../../../shared/models/user_model.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('User Management'), backgroundColor: cs.surface, actions: [
        IconButton(icon: const Icon(Icons.person_add_rounded), onPressed: () => _showAddUserDialog(context)),
      ]),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: mockUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _UserListTile(user: mockUsers[index]),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User'),
        content: const Text('User management feature coming soon.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.user});
  final UserModel user;

  Color get _roleColor => switch (user.role) {
    UserRole.admin        => AppColors.error,
    UserRole.researcher   => AppColors.primary,
    UserRole.farmManager => AppColors.info,
    UserRole.technician  => AppColors.warning,
    UserRole.student     => AppColors.accent,
  };

  String get _roleLabel => switch (user.role) {
    UserRole.admin        => 'Admin',
    UserRole.researcher   => 'Researcher',
    UserRole.farmManager => 'Farm Manager',
    UserRole.technician  => 'Technician',
    UserRole.student     => 'Student',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: cs.outline.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: _roleColor.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(user.initials, style: tt.titleMedium?.copyWith(color: _roleColor, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(user.email, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _roleColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: Text(_roleLabel, style: tt.labelSmall?.copyWith(color: _roleColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
