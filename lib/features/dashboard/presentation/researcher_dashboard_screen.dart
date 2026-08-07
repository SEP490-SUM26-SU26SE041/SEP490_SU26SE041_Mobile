import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/staggered_list_item.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/models/experiment_model.dart';
import '../../experiments/providers/experiment_provider.dart';
import '../providers/dashboard_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ResearcherDashboardScreen extends ConsumerWidget {
  const ResearcherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.dashboard,
        accentColor: AppColors.primary,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── 1. RESEARCHER HEADER ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                  ),
                  child: _ResearcherHeader(greeting: _greeting()),
                ),
              ),

              // ─── 2. CRITICAL ALERTS (from API overdue tasks) ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _CriticalAlertsSection(),
                ),
              ),

              // ─── 3. KPI GRID (from API) ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: const _KPIGridSection(),
                  ),
                ),
              ),

              // ─── 4. TASK OVERVIEW (from API) ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _TaskOverviewSection(),
                ),
              ),

              // ─── 7. PENDING TASKS (from API) ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _PendingTasksSection(),
                ),
              ),

              // ─── 8. ACTIVE EXPERIMENTS (from API) ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SectionHeader(
                          title: 'Active Experiments',
                          accentColor: AppColors.primary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/experiments'),
                        child: Text(
                          'View all',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildExperimentsSection(ref, context),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperimentsSection(WidgetRef ref, BuildContext context) {
    final experiments = ref.watch(experimentsProvider);

    return experiments.when(
      data: (exps) {
        final activeExps = exps
            .where((e) =>
                e.status == ExperimentStatus.active ||
                e.status == ExperimentStatus.planning)
            .toList();
        if (activeExps.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _EmptyState(
                icon: Icons.science_outlined,
                title: 'No active experiments',
                subtitle: 'No experiment data available',
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: activeExps.length.clamp(0, 3),
            separatorBuilder: (context, separator) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final exp = activeExps[index];
              return StaggeredListItem(
                index: index,
                child: _PremiumExperimentCard(
                  title: exp.title,
                  status: exp.status,
                  startDate: exp.startDate,
                  zone: exp.cropVariety,
                  progress: exp.progress,
                  studentCount: 2,
                  experimentCode: exp.experimentCode,
                  onTap: () => context.push('/experiments/${exp.id}'),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── RESEARCHER HEADER ──────────────────────────────────────────────────────

class _ResearcherHeader extends ConsumerWidget {
  const _ResearcherHeader({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final experiments = ref.watch(experimentsProvider);

    final experimentCount = experiments.whenOrNull(data: (e) => e.length) ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: tt.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.fullName ?? 'Researcher',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$experimentCount Experiments',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F4D3D), Color(0xFF3D7A5D)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user?.roleLabel ?? 'Researcher',
            style: tt.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Stack(
          children: [
            IconButton(
              onPressed: () => context.go('/notifications'),
              style: IconButton.styleFrom(
                backgroundColor:
                    (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                        .withAlpha(128),
              ),
              icon: Icon(Icons.notifications_outlined,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  size: 22),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        const ProfileButton(),
      ],
    );
  }
}

// ─── KPI GRID ────────────────────────────────────────────────────────────────

class _KPIGridSection extends ConsumerWidget {
  const _KPIGridSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final experiments = ref.watch(experimentsProvider);

    return stats.when(
      data: (s) {
        final activeExp = experiments.whenOrNull(data: (e) =>
                e.where((x) => x.status == ExperimentStatus.active).length) ??
            0;

        return _NewResearchKPIGrid(
          activeExperiments: activeExp,
          activeBatches: s.todayTasks > 0 ? s.todayTasks * 4 : 12, // approximate
          pendingTasks: s.pendingTasks,
          criticalAlerts: s.overdueTasks,
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _NewResearchKPIGrid(
        activeExperiments: 0,
        activeBatches: 0,
        pendingTasks: 0,
        criticalAlerts: 0,
      ),
    );
  }
}

class _NewResearchKPIGrid extends StatelessWidget {
  const _NewResearchKPIGrid({
    required this.activeExperiments,
    required this.activeBatches,
    required this.pendingTasks,
    required this.criticalAlerts,
  });

  final int activeExperiments;
  final int activeBatches;
  final int pendingTasks;
  final int criticalAlerts;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.08,
      children: [
        _ResearchKPICard(
          icon: Icons.science_outlined,
          iconBg: AppColors.primary.withAlpha(25),
          iconColor: AppColors.primary,
          value: '$activeExperiments',
          label: 'Active Experiments',
          onTap: () => context.go('/experiments'),
        ),
        _ResearchKPICard(
          icon: Icons.batch_prediction_rounded,
          iconBg: AppColors.success.withAlpha(25),
          iconColor: AppColors.success,
          value: '$activeBatches',
          label: 'Active Batches',
        ),
        _ResearchKPICard(
          icon: Icons.assignment_outlined,
          iconBg: AppColors.warning.withAlpha(25),
          iconColor: AppColors.warning,
          value: '$pendingTasks',
          label: 'Pending Tasks',
          onTap: () => context.go('/tasks'),
        ),
        _ResearchKPICard(
          icon: Icons.warning_rounded,
          iconBg: AppColors.error.withAlpha(25),
          iconColor: AppColors.error,
          value: '$criticalAlerts',
          label: 'Critical Alerts',
          onTap: () => context.go('/notifications'),
        ),
      ],
    );
  }
}

class _ResearchKPICard extends StatelessWidget {
  const _ResearchKPICard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final cardContent = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight)
              .withAlpha(100),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withAlpha(30), width: 0.8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: iconColor,
              height: 1.0,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }
    return cardContent;
  }
}

// ─── CRITICAL ALERTS ────────────────────────────────────────────────────────

class _CriticalAlertsSection extends ConsumerWidget {
  const _CriticalAlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alerts = ref.watch(criticalAlertsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
            const SizedBox(width: 6),
            Text(
              'Critical Alerts',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Spacer(),
            alerts.whenOrNull(
                  data: (a) => Text(
                    '${a.length} active',
                    style: tt.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ) ??
                const SizedBox(),
          ],
        ),
        const SizedBox(height: 8),
        alerts.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'No overdue tasks',
                      style: tt.bodySmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: items
                  .take(3)
                  .map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AlertCard(
                          icon: Icons.schedule_rounded,
                          title: alert.title,
                          subtitle: alert.subtitle,
                          onTap: () =>
                              context.push('/tasks/${alert.taskId}'),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}

// ─── TASK OVERVIEW ───────────────────────────────────────────────────────────

class _TaskOverviewSection extends ConsumerWidget {
  const _TaskOverviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(dashboardStatsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: stats.when(
        data: (s) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TaskCountChip(label: 'Pending', count: s.pendingTasks, color: AppColors.warning),
            Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            _TaskCountChip(label: 'In Progress', count: s.inProgressTasks, color: AppColors.info),
            Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            _TaskCountChip(label: 'Completed', count: s.completedTasks, color: AppColors.success),
            Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            _TaskCountChip(label: 'Overdue', count: s.overdueTasks, color: AppColors.error),
          ],
        ),
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (_) => _TaskCountChip(label: '--', count: 0, color: AppColors.textSecondaryLight)),
        ),
      ),
    );
  }
}

class _TaskCountChip extends StatelessWidget {
  const _TaskCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: tt.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── PENDING TASKS ───────────────────────────────────────────────────────────

class _PendingTasksSection extends ConsumerWidget {
  const _PendingTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(researcherPendingTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Pending Tasks',
          accentColor: AppColors.warning,
          badge: tasks.whenOrNull(data: (t) => '${t.length}') ?? '--',
        ),
        const SizedBox(height: AppSpacing.sm),
        tasks.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Center(
                  child: Text(
                    'No pending tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ),
              );
            }
            return Column(
              children: items
                  .take(5)
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PendingTaskItem(
                          title: t.title,
                          subtitle: '${t.batchCode ?? 'Batch'} • ${t.experimentStageName ?? 'Stage'}',
                          type: t.taskType.labelVi,
                          dueTime: _formatDue(t.dueDate),
                          status: t.status.value,
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    return '${dt.day}/${dt.month}';
  }
}

class _PendingTaskItem extends StatelessWidget {
  const _PendingTaskItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.dueTime,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String type;
  final String dueTime;
  final String status;

  Color get _accentColor => switch (status) {
        'Pending' => AppColors.warning,
        'InProgress' => AppColors.info,
        _ => AppColors.primary,
      };

  IconData get _icon => switch (type.toLowerCase()) {
        'tưới nước' => Icons.water_drop_rounded,
        'bón phân' => Icons.eco_rounded,
        'quan sát' => Icons.visibility_rounded,
        _ => Icons.task_alt_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 15 : 8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.heroRadius,
        child: InkWell(
          onTap: () {},
          borderRadius: AppRadius.heroRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, size: 20, color: _accentColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dueTime,
                        style: tt.labelSmall?.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)
                          .withAlpha(77),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ALERT CARD ─────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.error, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.accentColor,
    this.badge,
  });

  final String title;
  final Color accentColor;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge!,
              style: tt.labelMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── EXPERIMENT CARD ────────────────────────────────────────────────────────

class _PremiumExperimentCard extends StatelessWidget {
  const _PremiumExperimentCard({
    required this.title,
    required this.status,
    required this.startDate,
    required this.zone,
    required this.progress,
    required this.studentCount,
    required this.experimentCode,
    required this.onTap,
  });

  final String title;
  final ExperimentStatus status;
  final DateTime startDate;
  final String zone;
  final double progress;
  final int studentCount;
  final String experimentCode;
  final VoidCallback onTap;

  Color _statusColor(ExperimentStatus s) => switch (s) {
        ExperimentStatus.active => AppColors.experimentActive,
        ExperimentStatus.planning => AppColors.experimentPlanning,
        ExperimentStatus.completed => AppColors.experimentCompleted,
        ExperimentStatus.paused => AppColors.experimentPaused,
        ExperimentStatus.draft => AppColors.textSecondaryLight,
        ExperimentStatus.pending => AppColors.warning,
      };

  String _statusLabel(ExperimentStatus s) => switch (s) {
        ExperimentStatus.active => 'Active',
        ExperimentStatus.planning => 'Planning',
        ExperimentStatus.completed => 'Completed',
        ExperimentStatus.paused => 'Paused',
        ExperimentStatus.draft => 'Draft',
        ExperimentStatus.pending => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight)
              .withAlpha(128),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor.withAlpha(40),
                            statusColor.withAlpha(20),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(color: statusColor.withAlpha(51)),
                      ),
                      child: Icon(Icons.science_rounded,
                          size: 22, color: statusColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                  boxShadow: [
                                    BoxShadow(
                                        color: statusColor.withAlpha(102),
                                        blurRadius: 4),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        experimentCode,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MiniChip(icon: Icons.grass_rounded, label: zone, color: AppColors.success),
                    _MiniChip(
                        icon: Icons.people_outline_rounded,
                        label: '$studentCount students',
                        color: AppColors.info),
                    _MiniChip(
                        icon: Icons.calendar_today_rounded,
                        label: '${startDate.day}/${startDate.month}/${startDate.year}',
                        color: AppColors.textSecondaryLight),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ExpProgressBar(progress: progress, color: statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color:
            (isDark ? AppColors.surfaceDark : AppColors.backgroundLight).withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)
                      .withAlpha(153),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExpProgressBar extends StatelessWidget {
  const _ExpProgressBar({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                        .withAlpha(102),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.borderLight)
                .withAlpha(128),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [color, color.withAlpha(179)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: cs.onSurface.withAlpha(51)),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface.withAlpha(153),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(102)),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
