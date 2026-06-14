import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/kpi_tile.dart';
import '../../../shared/widgets/profile_button.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.compact,
        accentColor: AppColors.error,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Panel', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Hệ thống quản lý vườn ươm thông minh', style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
                          ],
                        ),
                      ),
                      const ProfileButton(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    children: [
                      KPITile(label: 'Total Users', value: '6', unit: 'users', icon: Icons.people_rounded),
                      KPITile(label: 'Active Experiments', value: '1', unit: 'exp', icon: Icons.science_rounded),
                      KPITile(label: 'Sensors Online', value: '5', unit: 'sensors', icon: Icons.sensors_rounded),
                      KPITile(label: 'Pending Requests', value: '2', unit: 'req', icon: Icons.pending_actions_rounded),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                  child: Text('Quick Actions', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    _ActionCard(icon: Icons.person_add_rounded, title: 'User Management', subtitle: 'Add, edit, and manage user accounts and roles', color: AppColors.primary, onTap: () {}),
                    const SizedBox(height: AppSpacing.md),
                    _ActionCard(icon: Icons.settings_rounded, title: 'System Settings', subtitle: 'Configure IoT integrations, notifications, and more', color: AppColors.info, onTap: () {}),
                    const SizedBox(height: AppSpacing.md),
                    _ActionCard(icon: Icons.analytics_rounded, title: 'Reports & Analytics', subtitle: 'View system-wide statistics and reports', color: AppColors.success, onTap: () {}),
                    const SizedBox(height: AppSpacing.md),
                    _ActionCard(icon: Icons.security_rounded, title: 'Security & Access', subtitle: 'Manage permissions and access control', color: AppColors.warning, onTap: () {}),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
          ],
        ),
      ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, size: 26, color: color),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withAlpha(102)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
