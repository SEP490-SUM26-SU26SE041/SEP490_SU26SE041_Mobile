import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/staggered_list_item.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../../shared/widgets/plant_photo_gallery.dart';
import '../../../shared/models/experiment_model.dart';
import '../../experiments/providers/experiment_provider.dart';

class ResearcherDashboardScreen extends ConsumerWidget {
  const ResearcherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final experiments = ref.watch(experimentsProvider);

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

              // ─── 2. CRITICAL ALERTS BANNER ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: _CriticalAlertsSection(alerts: const [
                    _AlertData(
                      icon: Icons.thermostat_rounded,
                      title: 'Nhiệt độ Zone B-03 vượt ngưỡng',
                      subtitle: '34.5°C — max cho phép 32°C',
                      severity: AlertSeverity.critical,
                      isUnread: true,
                    ),
                    _AlertData(
                      icon: Icons.sensors_off_rounded,
                      title: 'Cảm biến TEMP-Z01-B02 offline',
                      subtitle: 'Hơn 2 giờ — cần kiểm tra',
                      severity: AlertSeverity.high,
                      isUnread: true,
                    ),
                  ]),
                ),
              ),

              // ─── 3. KPI GRID ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: experiments.when(
                      data: (exps) {
                        final active = exps.where((e) => e.status == ExperimentStatus.active).length;
                        return _NewResearchKPIGrid(
                          activeExperiments: active,
                          activeBatches: 48,
                          pendingTasks: 15,
                          criticalAlerts: 3,
                        );
                      },
                      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Error: $e')),
                    ),
                  ),
                ),
              ),

              // ─── 4. EXPERIMENT COMPARISON ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _ExperimentComparisonSection(),
                ),
              ),

              // ─── 5. QUICK ACTIONS ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _ResearchQuickActions(),
                ),
              ),

              // ─── 6. TASK OVERVIEW ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _TaskOverviewSection(),
                ),
              ),

              // ─── 7. AI RECOMMENDATION ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _AIRecommendationCard(),
                ),
              ),

              // ─── 8. TEAM ACTIVITY ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const _TeamActivitySection(),
                ),
              ),

              // ─── 9. PLANT PHOTOS ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: const GradientHeader(
                    title: 'Hình ảnh cây gần đây',
                    subtitle: 'Cập nhật từ Student & Technician',
                    leading: Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                  ),
                  child: const PlantPhotoGallery(maxPhotos: 5),
                ),
              ),

              // ─── 10. PENDING TASKS ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: _SectionHeader(
                    title: 'Công việc cần xử lý',
                    accentColor: AppColors.warning,
                    badge: '3',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Column(
                    children: [
                      _ResearcherPendingTaskCard(
                        title: 'Phê duyệt yêu cầu thực nghiệm',
                        subtitle: 'Nhóm 3 - Cà chua Cherry',
                        type: 'request',
                        dueTime: 'Trong ngày',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ResearcherPendingTaskCard(
                        title: 'Xem xét kết quả quan sát',
                        subtitle: 'Tuần 4 - 18/24 ghi nhận',
                        type: 'review',
                        dueTime: 'Ngày mai',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ResearcherPendingTaskCard(
                        title: 'Cập nhật chỉ số tăng trưởng',
                        subtitle: 'EXP-2024-001 - Đối chứng',
                        type: 'update',
                        dueTime: '24/06',
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 11. ACTIVE EXPERIMENTS ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SectionHeader(title: 'Active Experiments', accentColor: AppColors.primary),
                      ),
                      TextButton(
                        onPressed: () => context.go('/experiments'),
                        child: Text('View all', style: tt.labelMedium?.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),

              experiments.when(
                data: (exps) {
                  final activeExps = exps.where((e) =>
                      e.status == ExperimentStatus.active ||
                      e.status == ExperimentStatus.planning).toList();
                  if (activeExps.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _EmptyState(
                          icon: Icons.science_outlined,
                          title: 'No active experiments',
                          subtitle: 'Create your first experiment to get started',
                          actionLabel: 'Create Experiment',
                          onAction: () => context.push('/experiments/create'),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverList.separated(
                      itemCount: activeExps.length.clamp(0, 3),
                      separatorBuilder: (context, separator) => const SizedBox(height: AppSpacing.md),
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
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
            ],
          ),
        ),
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
// NEW WIDGETS FOR RESEARCHER DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

// ─── NEW KPI GRID (2×2) ──────────────────────────────────────────────────────

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

    final bgSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final cardContent = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(100),
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
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }
    return cardContent;
  }
}

// ─── EXPERIMENT COMPARISON SECTION ──────────────────────────────────────────

class _ExperimentComparisonSection extends StatelessWidget {
  const _ExperimentComparisonSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = 35.0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'So sánh nhóm',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+28%',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ComparisonBar(
            label: 'Đối Chứng',
            value: 22.4,
            maxValue: maxVal,
            color: AppColors.textSecondaryLight,
            unit: 'cm',
          ),
          const SizedBox(height: AppSpacing.md),
          _ComparisonBar(
            label: 'Thực Nghiệm',
            value: 28.7,
            maxValue: maxVal,
            color: AppColors.primary,
            unit: 'cm',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Nhóm Thực Nghiệm cao hơn 28% so với Đối Chứng sau 4 tuần',
                    style: tt.bodySmall?.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.unit,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value$unit',
              style: tt.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.borderLight).withAlpha(128),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── RESEARCH QUICK ACTIONS ─────────────────────────────────────────────────

class _ResearchQuickActions extends StatelessWidget {
  const _ResearchQuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_outline_rounded,
            label: 'New Experiment',
            color: AppColors.primary,
            onTap: () => context.push('/experiments/create'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Assign Task',
            color: AppColors.info,
            onTap: () => context.go('/tasks'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.compare_arrows_rounded,
            label: 'Compare Groups',
            color: AppColors.warning,
            onTap: () => context.push('/experiments/analytics'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            icon: Icons.smart_toy_rounded,
            label: 'AI Analysis',
            color: AppColors.success,
            onTap: () => context.push('/chatbot'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TASK OVERVIEW SECTION ──────────────────────────────────────────────────

class _TaskOverviewSection extends StatelessWidget {
  const _TaskOverviewSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TaskCountChip(
            label: 'Pending',
            count: 5,
            color: AppColors.warning,
          ),
          Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          _TaskCountChip(
            label: 'In Progress',
            count: 8,
            color: AppColors.info,
          ),
          Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          _TaskCountChip(
            label: 'Completed',
            count: 21,
            color: AppColors.success,
          ),
          Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          _TaskCountChip(
            label: 'Overdue',
            count: 2,
            color: AppColors.error,
          ),
        ],
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
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── AI RECOMMENDATION CARD ─────────────────────────────────────────────────

class _AIRecommendationCard extends StatelessWidget {
  const _AIRecommendationCard();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(15),
            AppColors.success.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recommendation',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+28%',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Batch T-03',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withAlpha(77),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nhóm Thực Nghiệm (T-03) cao hơn nhóm Đối Chứng 28%. Cân nhắc điều chỉnh dinh dưỡng cho các batch tiếp theo.',
              style: tt.bodySmall?.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 14),
              const SizedBox(width: 6),
              Text(
                'Possible causes:',
                style: tt.labelSmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _CauseItem(text: '• Tăng光照强度 15% trong tuần 3-4'),
          _CauseItem(text: '• Bổ sung phân bón NPK cân bằng'),
          _CauseItem(text: '• Điều kiện nhiệt độ ổn định 26-28°C'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withAlpha(30)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Khuyến nghị: Áp dụng phương pháp này cho batch tiếp theo',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CauseItem extends StatelessWidget {
  const _CauseItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: tt.bodySmall?.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── TEAM ACTIVITY SECTION ──────────────────────────────────────────────────

class _TeamActivitySection extends StatelessWidget {
  const _TeamActivitySection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Container(
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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school_rounded, color: AppColors.info, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Students',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '12',
                        style: tt.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'active',
                      style: tt.bodySmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '3',
                        style: tt.titleMedium?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'pending reports',
                      style: tt.bodySmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.engineering_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Technicians',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '8',
                        style: tt.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'active',
                      style: tt.bodySmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '1',
                        style: tt.titleMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'overdue task',
                      style: tt.bodySmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 1: RESEARCHER HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _ResearcherHeader extends StatelessWidget {
  const _ResearcherHeader({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TS. Nguyễn Minh Khoa',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Role badge
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
            'Researcher',
            style: tt.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Notification bell with unread badge
        Stack(
          children: [
            IconButton(
              onPressed: () => context.go('/notifications'),
              style: IconButton.styleFrom(
                backgroundColor: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withAlpha(128),
              ),
              icon: Icon(Icons.notifications_outlined,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                size: 22),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        // Avatar with profile menu
        const ProfileButton(),
      ],
    );
  }
}

// ─── EXISTING: CRITICAL ALERTS ────────────────────────────────────────────────

enum AlertSeverity { critical, high, medium }

class _AlertData {
  final IconData icon;
  final String title;
  final String subtitle;
  final AlertSeverity severity;
  final bool isUnread;

  const _AlertData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.isUnread,
  });
}

class _CriticalAlertsSection extends StatelessWidget {
  const _CriticalAlertsSection({required this.alerts});
  final List<_AlertData> alerts;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 6),
              Text(
                'Critical Alerts',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '${alerts.length} active',
                style: tt.labelSmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...alerts.map((alert) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _AlertCard(
            icon: alert.icon,
            title: alert.title,
            subtitle: alert.subtitle,
            severity: alert.severity,
            isUnread: alert.isUnread,
            onTap: () => context.go('/notifications'),
          ),
        )),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.isUnread,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AlertSeverity severity;
  final bool isUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = switch (severity) {
      AlertSeverity.critical => AppColors.error,
      AlertSeverity.high     => AppColors.warning,
      AlertSeverity.medium   => AppColors.info,
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: severityColor.withAlpha(51),
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
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: severityColor, size: 18),
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
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isUnread ? severityColor : Colors.transparent,
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

// ─── EXISTING: PENDING TASKS ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.accentColor, this.badge});

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
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
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

class _ResearcherPendingTaskCard extends StatelessWidget {
  const _ResearcherPendingTaskCard({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.dueTime,
  });

  final String title;
  final String subtitle;
  final String type;
  final String dueTime;

  Color get _accentColor => switch (type) {
    'request' => AppColors.primary,
    'review'  => AppColors.info,
    'update'  => AppColors.warning,
    _         => AppColors.primary,
  };

  IconData get _icon => switch (type) {
    'request' => Icons.assignment_ind_rounded,
    'review'  => Icons.rate_review_outlined,
    'update'  => Icons.update_rounded,
    _         => Icons.task_alt_rounded,
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
                    color: _accentColor.withOpacity(0.15),
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
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                        color: _accentColor.withOpacity(0.15),
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
                      color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77),
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

// ─── ACTIVE EXPERIMENTS ──────────────────────────────────────────────────────

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
    ExperimentStatus.active    => AppColors.experimentActive,
    ExperimentStatus.planning  => AppColors.experimentPlanning,
    ExperimentStatus.completed => AppColors.experimentCompleted,
    ExperimentStatus.paused    => AppColors.experimentPaused,
    ExperimentStatus.draft     => AppColors.textSecondaryLight,
    ExperimentStatus.pending   => AppColors.warning,
  };

  String _statusLabel(ExperimentStatus s) => switch (s) {
    ExperimentStatus.active    => 'Active',
    ExperimentStatus.planning  => 'Planning',
    ExperimentStatus.completed => 'Completed',
    ExperimentStatus.paused   => 'Paused',
    ExperimentStatus.draft     => 'Draft',
    ExperimentStatus.pending   => 'Pending',
  };

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

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
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
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
                      child: Icon(Icons.science_rounded, size: 22, color: statusColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                                    BoxShadow(color: statusColor.withAlpha(102), blurRadius: 4),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                    _MiniChip(icon: Icons.people_outline_rounded, label: '$studentCount students', color: AppColors.info),
                    _MiniChip(icon: Icons.calendar_today_rounded, label: _formatDate(startDate), color: AppColors.textSecondaryLight),
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
  const _MiniChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.backgroundLight).withAlpha(128),
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
              color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153),
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
                color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(102),
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
            color: (isDark ? AppColors.surfaceDark : AppColors.borderLight).withAlpha(128),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withAlpha(179)]),
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
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

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
          const SizedBox(height: AppSpacing.lg),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

