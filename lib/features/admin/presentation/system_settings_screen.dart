import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SystemSettingsScreen extends ConsumerWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('System Settings'), backgroundColor: cs.surface),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(title: 'IoT Integration', children: [
            _Tile(icon: Icons.sensors_rounded, title: 'Sensor Configuration', subtitle: 'Manage sensor types and thresholds'),
            _Tile(icon: Icons.wifi_tethering_rounded, title: 'MQTT Broker', subtitle: 'Configure MQTT server connection'),
            _Tile(icon: Icons.notifications_rounded, title: 'Alert Thresholds', subtitle: 'Set sensor alert levels'),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _Section(title: 'Notifications', children: [
            _Tile(icon: Icons.email_rounded, title: 'Email Settings', subtitle: 'SMTP configuration'),
            _Tile(icon: Icons.notifications_active_rounded, title: 'Push Notifications', subtitle: 'Enable/disable notification channels'),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _Section(title: 'Data Management', children: [
            _Tile(icon: Icons.backup_rounded, title: 'Backup & Restore', subtitle: 'Manage system backups'),
            _Tile(icon: Icons.delete_outline_rounded, title: 'Data Retention', subtitle: 'Configure data retention policies'),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
          child: Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        ...children.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: e.key < children.length - 1 ? AppSpacing.md : 0),
          child: e.value,
        )),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

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
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
