import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/widgets/staggered_list_item.dart';
import '../../experiments/providers/experiment_provider.dart';

class ExperimentDetailScreen extends ConsumerStatefulWidget {
  const ExperimentDetailScreen({super.key, required this.id, this.analyticsTab = false});

  final String id;
  final bool analyticsTab;

  @override
  ConsumerState<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends ConsumerState<ExperimentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.analyticsTab) {
      _tabController.index = 3; // Results tab (0-indexed)
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experiment = ref.watch(experimentDetailProvider(widget.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return experiment.when(
      data: (exp) {
        if (exp == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Experiment not found')),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _PremiumSliverAppBar(
                experiment: exp,
                tabController: _tabController,
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(experiment: exp),
                _DesignTab(experiment: exp),
                _GroupsTab(experiment: exp),
                _ResultsTab(experiment: exp),
                _TasksTab(experiment: exp),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── PREMIUM APP BAR ────────────────────────────────────────────────────────

class _PremiumSliverAppBar extends StatelessWidget {
  const _PremiumSliverAppBar({required this.experiment, required this.tabController});
  final ExperimentModel experiment;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = experiment.progress;
    final statusColor = _statusColor(experiment.status);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      leading: IconButton(
        onPressed: () => context.pop(),
        style: IconButton.styleFrom(
          backgroundColor: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withAlpha(204),
        ),
        icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
      ),
      actions: [
        const SizedBox(width: 52),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F1A12), const Color(0xFF18201B)]
                      : [const Color(0xFFEAF6FF), const Color(0xFFF7FAF5)],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            // Scientific grid overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _ScientificGridPainter(isDark: isDark),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: status + progress ring
                    Row(
                      children: [
                        _StatusBadge(status: experiment.status),
                        const Spacer(),
                        _ProgressRing(progress: progress, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Title
                    Text(
                      experiment.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Info chips row
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _InfoChipData(
                          icon: Icons.code_rounded,
                          label: experiment.experimentCode,
                          color: AppColors.primary,
                        ),
                        _InfoChipData(
                          icon: Icons.eco_rounded,
                          label: experiment.cropVariety,
                          color: AppColors.success,
                        ),
                        _InfoChipData(
                          icon: Icons.calendar_today_rounded,
                          label: '${_fmtDate(experiment.startDate)} - ${_fmtDate(experiment.endDate)}',
                          color: AppColors.info,
                        ),
                        _InfoChipData(
                          icon: Icons.timeline_rounded,
                          label: _duration(experiment),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Design'),
              Tab(text: 'Groups'),
              Tab(text: 'Results'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
      ),
    );
  }

  String _duration(ExperimentModel exp) {
    final days = exp.endDate.difference(exp.startDate).inDays;
    return '$days days';
  }

  String _fmtDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  Color _statusColor(ExperimentStatus s) => switch (s) {
    ExperimentStatus.active    => AppColors.experimentActive,
    ExperimentStatus.planning  => AppColors.experimentPlanning,
    ExperimentStatus.completed => AppColors.experimentCompleted,
    ExperimentStatus.paused    => AppColors.experimentPaused,
    ExperimentStatus.draft     => AppColors.textSecondaryLight,
    ExperimentStatus.pending   => AppColors.warning,
  };
}

class _ScientificGridPainter extends CustomPainter {
  _ScientificGridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? AppColors.accent : AppColors.primary).withAlpha(4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dotPaint = Paint()
      ..color = (isDark ? AppColors.accent : AppColors.primary).withAlpha(8)
      ..style = PaintingStyle.fill;
    for (double x = spacing / 2; x < size.width; x += spacing * 2) {
      for (double y = spacing / 2; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ScientificGridPainter old) => false;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ExperimentStatus status;

  Color get _color => switch (status) {
    ExperimentStatus.active    => AppColors.experimentActive,
    ExperimentStatus.planning  => AppColors.experimentPlanning,
    ExperimentStatus.completed => AppColors.experimentCompleted,
    ExperimentStatus.paused    => AppColors.experimentPaused,
    ExperimentStatus.draft     => AppColors.textSecondaryLight,
    ExperimentStatus.pending   => AppColors.warning,
  };

  String get _label => switch (status) {
    ExperimentStatus.active    => 'Active',
    ExperimentStatus.planning  => 'Planning',
    ExperimentStatus.completed => 'Completed',
    ExperimentStatus.paused    => 'Paused',
    ExperimentStatus.draft     => 'Draft',
    ExperimentStatus.pending   => 'Pending',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: _color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _color.withAlpha(102), blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.5,
              backgroundColor: color.withAlpha(25),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChipData extends StatelessWidget {
  const _InfoChipData({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.cardDark : AppColors.surfaceLight).withAlpha(180),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 1: OVERVIEW ────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Research Goal
          StaggeredListItem(
            index: 0,
            child: _ResearchGoalCard(experiment: experiment),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Design KPIs 2x2
          StaggeredListItem(
            index: 1,
            child: _DesignKPIGrid(experiment: experiment),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Analysis Summary
          StaggeredListItem(
            index: 2,
            child: _AnalysisSummaryCard(experiment: experiment),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Groups Preview
          StaggeredListItem(
            index: 3,
            child: _QuickGroupsPreview(experiment: experiment),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _ResearchGoalCard extends StatelessWidget {
  const _ResearchGoalCard({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient(context),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Research Goal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Primary Objective',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            experiment.objective,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              height: 1.6,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DesignKPIGrid extends StatelessWidget {
  const _DesignKPIGrid({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Experiment Design',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            _DesignKPICard(
              index: 0,
              icon: Icons.grid_view_rounded,
              label: 'Design Type',
              value: experiment.design.designTypeLabel,
              color: AppColors.primary,
            ),
            _DesignKPICard(
              index: 1,
              icon: Icons.grass_rounded,
              label: 'Sample Size',
              value: '${experiment.design.sampleSize}',
              unit: 'plants',
              color: AppColors.success,
            ),
            _DesignKPICard(
              index: 2,
              icon: Icons.copy_rounded,
              label: 'Replications',
              value: '${experiment.design.replicationCount}',
              color: AppColors.info,
            ),
            _DesignKPICard(
              index: 3,
              icon: Icons.group_work_rounded,
              label: 'Treatment Groups',
              value: '${experiment.design.treatmentCount}',
              color: AppColors.accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _DesignKPICard extends StatefulWidget {
  const _DesignKPICard({
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    required this.color,
  });

  final int index;
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  State<_DesignKPICard> createState() => _DesignKPICardState();
}

class _DesignKPICardState extends State<_DesignKPICard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Icon(widget.icon, size: 18, color: widget.color),
                      ),
                      if (widget.unit != null)
                        Text(
                          widget.unit!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  const _AnalysisSummaryCard({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAnalysis = experiment.design.analysisPlan != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(
          color: AppColors.aiInsight.withAlpha(51),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiInsight.withAlpha(isDark ? 10 : 8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.aiInsight.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.aiInsight, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Plan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAnalysis ? experiment.design.analysisPlan! : 'ANOVA + Tukey HSD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                if (experiment.design.evaluationCriteria != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    experiment.design.evaluationCriteria!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.aiInsight.withAlpha(179),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.aiInsight.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(
              'Details',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.aiInsight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickGroupsPreview extends StatelessWidget {
  const _QuickGroupsPreview({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Experiment Groups',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${experiment.groups.length} groups',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...experiment.groups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: StaggeredListItem(
              index: 4 + index,
              child: _ResearchGroupCard(group: group),
            ),
          );
        }),
      ],
    );
  }
}

class _ResearchGroupCard extends StatelessWidget {
  const _ResearchGroupCard({required this.group});
  final ExperimentGroup group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isControl = group.groupType == GroupType.control;
    final groupColor = isControl ? AppColors.info : AppColors.primary;
    final progress = (group.sampleSize > 0) ? 0.75 : 0.5;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: groupColor.withAlpha(51),
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
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: groupColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: groupColor.withAlpha(102), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.groupName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: groupColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  isControl ? 'Control' : 'Treatment',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: groupColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _GroupMiniStat(
                icon: Icons.science_outlined,
                value: '${group.sampleSize}',
                label: 'samples',
                color: groupColor,
              ),
              const SizedBox(width: AppSpacing.lg),
              _GroupMiniStat(
                icon: Icons.water_drop_outlined,
                value: '${group.cultivationMethod.wateringRule.amount}ml',
                label: 'water/day',
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.lg),
              _GroupMiniStat(
                icon: Icons.eco_rounded,
                value: group.cultivationMethod.fertilizingRule.fertilizerName,
                label: 'fertilizer',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: groupColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: groupColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: groupColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupMiniStat extends StatelessWidget {
  const _GroupMiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── TAB 2: DESIGN ───────────────────────────────────────────────────────────

class _DesignTab extends StatelessWidget {
  const _DesignTab({required this.experiment});
  final ExperimentModel experiment;

  bool get _isDesignReady => switch (experiment.status) {
    ExperimentStatus.active    => true,
    ExperimentStatus.completed => true,
    ExperimentStatus.paused   => true,
    ExperimentStatus.draft    => false,
    ExperimentStatus.planning => false,
    ExperimentStatus.pending  => false,
  };

  @override
  Widget build(BuildContext context) {
    if (!_isDesignReady) {
      return _PendingDesignPlaceholder(experiment: experiment);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Approval Banner (if status = pending, design ready but awaiting FM approval)
          if (experiment.status == ExperimentStatus.pending)
            StaggeredListItem(
              index: 0,
              child: _ApprovalPendingBanner(),
            ),

          // Full design details as premium list
          StaggeredListItem(
            index: experiment.status == ExperimentStatus.pending ? 1 : 0,
            child: _DesignDetailSection(experiment: experiment),
          ),
          const SizedBox(height: AppSpacing.md),

          // Create Design Button (for active experiments without full design)
          if (experiment.status == ExperimentStatus.active || experiment.status == ExperimentStatus.pending)
            StaggeredListItem(
              index: experiment.status == ExperimentStatus.pending ? 2 : 1,
              child: _CreateDesignButton(experiment: experiment),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Evaluation
          if (experiment.design.evaluationCriteria != null)
            StaggeredListItem(
              index: experiment.status == ExperimentStatus.pending ? 2 : 1,
              child: _EvaluationCard(criteria: experiment.design.evaluationCriteria!),
            ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _ApprovalPendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: AppRadius.heroRadius,
        border: Border.all(color: AppColors.warning.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Thiết kế đã hoàn tất — đang chờ Farm Manager phê duyệt để bắt đầu thí nghiệm.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDesignPlaceholder extends StatelessWidget {
  const _PendingDesignPlaceholder({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLabel = switch (experiment.status) {
      ExperimentStatus.draft    => 'Bản nháp',
      ExperimentStatus.planning => 'Đang lập kế hoạch',
      ExperimentStatus.pending  => 'Chờ phê duyệt',
      _                        => 'Chưa được duyệt',
    };
    final statusIcon = switch (experiment.status) {
      ExperimentStatus.draft    => Icons.edit_note_rounded,
      ExperimentStatus.planning => Icons.design_services_rounded,
      ExperimentStatus.pending  => Icons.pending_actions_rounded,
      _                        => Icons.hourglass_empty_rounded,
    };
    final statusColor = switch (experiment.status) {
      ExperimentStatus.draft    => AppColors.neutral,
      ExperimentStatus.planning => AppColors.info,
      ExperimentStatus.pending  => AppColors.warning,
      _                        => AppColors.neutral,
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withAlpha(77), width: 2),
              ),
              child: Icon(statusIcon, color: statusColor, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Thiết kế thực nghiệm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: statusColor.withAlpha(77)),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: AppRadius.heroRadius,
                border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128)),
              ),
              child: Column(
                children: [
                  _PlaceholderRow(
                    icon: Icons.grid_view_rounded,
                    label: 'Thiết kế thực nghiệm',
                    hint: 'CRD / RCBD / Factorial',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _PlaceholderRow(
                    icon: Icons.grass_rounded,
                    label: 'Cỡ mẫu',
                    hint: 'Số cây trong mỗi nhóm',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _PlaceholderRow(
                    icon: Icons.copy_rounded,
                    label: 'Số lần lặp lại',
                    hint: 'Replication count',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _PlaceholderRow(
                    icon: Icons.group_work_rounded,
                    label: 'Nhóm xử lý',
                    hint: 'Control vs Treatment',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _PlaceholderRow(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Kế hoạch phân tích',
                    hint: 'ANOVA, Tukey HSD...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Thiết kế chi tiết sẽ được hiển thị sau khi Farm Manager phê duyệt yêu cầu thí nghiệm.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({required this.icon, required this.label, required this.hint});
  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral.withAlpha(153)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesignDetailSection extends StatelessWidget {
  const _DesignDetailSection({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient(context),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Icons.design_services_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Design Specification',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _DetailRow(label: 'Design Type', value: experiment.design.designTypeLabel, icon: Icons.grid_view_rounded),
          _DetailDivider(),
          _DetailRow(label: 'Sample Size', value: '${experiment.design.sampleSize} plants', icon: Icons.grass_rounded),
          _DetailDivider(),
          _DetailRow(label: 'Replications', value: '${experiment.design.replicationCount}', icon: Icons.copy_rounded),
          _DetailDivider(),
          _DetailRow(label: 'Treatment Groups', value: '${experiment.design.treatmentCount}', icon: Icons.group_work_rounded),
          if (experiment.design.observationFrequencyDays != null) ...[
            _DetailDivider(),
            _DetailRow(label: 'Observation Frequency', value: 'Every ${experiment.design.observationFrequencyDays} days', icon: Icons.visibility_rounded),
          ],
          if (experiment.design.measurementFrequencyDays != null) ...[
            _DetailDivider(),
            _DetailRow(label: 'Measurement Frequency', value: 'Every ${experiment.design.measurementFrequencyDays} days', icon: Icons.straighten_rounded),
          ],
          if (experiment.requiredArea != null) ...[
            _DetailDivider(),
            _DetailRow(label: 'Required Area', value: '${experiment.requiredArea} m²', icon: Icons.square_foot_rounded),
          ],
          if (experiment.plantQuantity != null) ...[
            _DetailDivider(),
            _DetailRow(label: 'Total Plants', value: '${experiment.plantQuantity} plants', icon: Icons.eco_rounded),
          ],
          if (experiment.design.analysisPlan != null) ...[
            _DetailDivider(),
            _DetailRow(label: 'Analysis Plan', value: experiment.design.analysisPlan!, icon: Icons.auto_awesome_rounded),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withAlpha(179)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.criteria});
  final String criteria;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(color: AppColors.warning.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(Icons.checklist_rounded, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluation Criteria',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  criteria,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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

// ─── TAB 3: GROUPS ───────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      itemCount: experiment.groups.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final group = experiment.groups[index];
        return StaggeredListItem(
          index: index,
          child: _FullGroupCard(group: group),
        );
      },
    );
  }
}

class _FullGroupCard extends StatelessWidget {
  const _FullGroupCard({required this.group});
  final ExperimentGroup group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isControl = group.groupType == GroupType.control;
    final groupColor = isControl ? AppColors.info : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(color: groupColor.withAlpha(77), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.heroRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: groupColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      border: Border.all(color: groupColor.withAlpha(51)),
                    ),
                    child: Icon(
                      isControl ? Icons.control_point_rounded : Icons.science_rounded,
                      color: groupColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (group.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            group.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: groupColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      isControl ? 'Control' : 'Treatment',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: groupColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _TreatmentMetric(
                      icon: Icons.water_drop_rounded,
                      label: 'Watering',
                      value: '${group.cultivationMethod.wateringRule.amount}ml × ${group.cultivationMethod.wateringRule.frequencyDays}x/day',
                      color: AppColors.info,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  ),
                  Expanded(
                    child: _TreatmentMetric(
                      icon: Icons.eco_rounded,
                      label: 'Fertilizing',
                      value: '${group.cultivationMethod.fertilizingRule.fertilizerName}\n${group.cultivationMethod.fertilizingRule.amount}g / ${group.cultivationMethod.fertilizingRule.frequencyDays}days',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.backgroundLight).withAlpha(128),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 14, color: groupColor),
                    const SizedBox(width: 6),
                    Text(
                      '${group.sampleSize} samples',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: groupColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: groupColor.withAlpha(102), blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: groupColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreatmentMetric extends StatelessWidget {
  const _TreatmentMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── TAB 4: RESULTS ─────────────────────────────────────────────────────────

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredListItem(
            index: 0,
            child: _ResultsIntro(),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredListItem(
            index: 1,
            child: _ComparisonMetricRow(
              label: 'Chiều cao trung bình',
              controlValue: '18.4 cm',
              treatmentValue: '21.2 cm',
              icon: Icons.straighten_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredListItem(
            index: 2,
            child: _ComparisonMetricRow(
              label: 'Số lá trung bình',
              controlValue: '6.2',
              treatmentValue: '7.8',
              icon: Icons.eco_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredListItem(
            index: 3,
            child: _ComparisonMetricRow(
              label: 'Tỷ lệ sống',
              controlValue: '82%',
              treatmentValue: '94%',
              icon: Icons.favorite_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredListItem(
            index: 4,
            child: _GrowthChartCard(),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredListItem(
            index: 5,
            child: _GroupsComparisonRow(experiment: experiment),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _ResultsIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(isDark ? 30 : 20),
            AppColors.primary.withAlpha(isDark ? 10 : 8),
          ],
        ),
        borderRadius: AppRadius.heroRadius,
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Groups Comparison',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'So sánh hiệu quả giữa Nhóm Đối Chứng và Nhóm Thực Nghiệm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
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

class _ComparisonMetricRow extends StatelessWidget {
  const _ComparisonMetricRow({
    required this.label,
    required this.controlValue,
    required this.treatmentValue,
    required this.icon,
    required this.color,
  });

  final String label;
  final String controlValue;
  final String treatmentValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ResultValueBox(
                  label: 'Control',
                  value: controlValue,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ResultValueBox(
                  label: 'Treatment',
                  value: treatmentValue,
                  color: color,
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultValueBox extends StatelessWidget {
  const _ResultValueBox({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight
            ? color.withAlpha(15)
            : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight).withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: highlight ? color.withAlpha(51) : (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Growth Curve',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _ChartLegend(label: 'Control', color: AppColors.info),
              const SizedBox(width: AppSpacing.md),
              _ChartLegend(label: 'Treatment', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: _PremiumLineChart(tt: Theme.of(context).textTheme, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 2.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PremiumLineChart extends StatelessWidget {
  const _PremiumLineChart({required this.tt, required this.isDark});
  final TextTheme tt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 5,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(102)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 7,
              getTitlesWidget: (value, meta) => Text(
                'D${value.toInt()}',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(102)),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 4), FlSpot(5, 8), FlSpot(10, 11), FlSpot(15, 14),
              FlSpot(20, 16), FlSpot(25, 17.5), FlSpot(30, 18.4),
            ],
            isCurved: true,
            color: AppColors.info,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.info.withAlpha(40),
                  AppColors.info.withAlpha(0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: const [
              FlSpot(0, 4), FlSpot(5, 9), FlSpot(10, 13), FlSpot(15, 16),
              FlSpot(20, 18.5), FlSpot(25, 20), FlSpot(30, 21.2),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withAlpha(40),
                  AppColors.primary.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) => LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} cm',
                TextStyle(
                  color: spot.bar.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              )).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _GroupsComparisonRow extends StatelessWidget {
  const _GroupsComparisonRow({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context) {
    if (experiment.groups.isEmpty) return const SizedBox.shrink();
    final control = experiment.groups.first;
    final treatment = experiment.groups.length > 1 ? experiment.groups.last : control;

    return Row(
      children: [
        Expanded(
          child: _CompactGroupResult(
            groupName: control.groupName,
            type: 'Control',
            water: '${control.cultivationMethod.wateringRule.amount}ml',
            fertilizer: control.cultivationMethod.fertilizingRule.fertilizerName,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CompactGroupResult(
            groupName: treatment.groupName,
            type: 'Treatment',
            water: '${treatment.cultivationMethod.wateringRule.amount}ml',
            fertilizer: treatment.cultivationMethod.fertilizingRule.fertilizerName,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _CompactGroupResult extends StatelessWidget {
  const _CompactGroupResult({
    required this.groupName,
    required this.type,
    required this.water,
    required this.fertilizer,
    required this.color,
  });

  final String groupName;
  final String type;
  final String water;
  final String fertilizer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  groupName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            type,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$water water',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
          ),
          Text(
            fertilizer,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 5: TASKS ─────────────────────────────────────────────────────────────

class _TasksTab extends ConsumerWidget {
  const _TasksTab({required this.experiment});
  final ExperimentModel experiment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/experiments/${experiment.id}/create-task'),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.when(
            data: (taskList) {
              final filtered = taskList.where((t) => t.experimentId == experiment.id).toList();
              if (filtered.isEmpty) {
                return _TasksEmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  return StaggeredListItem(
                    index: index,
                    child: _ExpTaskCard(task: filtered[index]),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _TasksEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bgCard = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_outlined, size: 56,
                color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có task nào',
              style: tt.titleMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tạo task để theo dõi tiến độ thực nghiệm',
              style: tt.bodySmall?.copyWith(
                color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpTaskCard extends StatelessWidget {
  const _ExpTaskCard({required this.task});
  final TaskModel task;

  Color get _statusColor => switch (task.status) {
    TaskStatus.pending    => AppColors.warning,
    TaskStatus.inProgress => AppColors.info,
    TaskStatus.completed => AppColors.success,
    TaskStatus.overdue   => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    TaskType.planting     => Icons.grass_rounded,
    TaskType.watering    => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.eco_rounded,
    TaskType.observation => Icons.visibility_rounded,
    TaskType.inspection  => Icons.search_rounded,
  };

  String get _statusLabel => switch (task.status) {
    TaskStatus.pending    => 'Chờ xử lý',
    TaskStatus.inProgress => 'Đang thực hiện',
    TaskStatus.completed => 'Hoàn thành',
    TaskStatus.overdue   => 'Quá hạn',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bgCard = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isOverdue = task.status == TaskStatus.overdue ||
        (task.status != TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? AppColors.error.withAlpha(60) : borderColor.withAlpha(80),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 22 : 10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showExpTaskDetail(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor.withAlpha(30), width: 0.8),
                      ),
                      child: Icon(_typeIcon, size: 22, color: _statusColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskName,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task.description != null && task.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.description!,
                              style: tt.bodySmall?.copyWith(
                                color: textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _statusColor.withAlpha(35), width: 0.8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: tt.labelSmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Meta row
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 8,
                  children: [
                    if (task.assignedTo != null && task.assignedTo!.isNotEmpty)
                      _ExpMetaChip(
                        icon: Icons.person_outline_rounded,
                        label: task.assignedTo!,
                        color: AppColors.primary,
                      ),
                    _ExpMetaChip(
                      icon: isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
                      label: 'Hạn: ${_formatDate(task.dueDate)}',
                      color: isOverdue ? AppColors.error : textSecondary,
                    ),
                    if (task.stageId != null && task.stageId!.isNotEmpty)
                      _ExpMetaChip(
                        icon: Icons.layers_outlined,
                        label: task.stageId!,
                        color: AppColors.info,
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

  void _showExpTaskDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ExpTaskDetailSheet(task: task),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ExpMetaChip extends StatelessWidget {
  const _ExpMetaChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withAlpha(180)),
        const SizedBox(width: 4),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: color.withAlpha(180),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ExpTaskDetailSheet extends StatelessWidget {
  const _ExpTaskDetailSheet({required this.task});
  final TaskModel task;

  Color get _statusColor => switch (task.status) {
    TaskStatus.pending    => AppColors.warning,
    TaskStatus.inProgress => AppColors.info,
    TaskStatus.completed => AppColors.success,
    TaskStatus.overdue   => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    TaskType.planting     => Icons.grass_rounded,
    TaskType.watering    => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.eco_rounded,
    TaskType.observation => Icons.visibility_rounded,
    TaskType.inspection  => Icons.search_rounded,
  };

  String get _statusLabel => switch (task.status) {
    TaskStatus.pending    => 'Chờ xử lý',
    TaskStatus.inProgress => 'Đang thực hiện',
    TaskStatus.completed => 'Hoàn thành',
    TaskStatus.overdue   => 'Quá hạn',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final isOverdue = task.status == TaskStatus.overdue ||
        (task.status != TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _statusColor.withAlpha(35)),
                ),
                child: Icon(_typeIcon, size: 26, color: _statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.taskName, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Mô tả', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: textSecondary)),
            const SizedBox(height: 6),
            Text(task.description!, style: tt.bodyMedium?.copyWith(color: textPrimary, height: 1.4)),
          ],
          const SizedBox(height: 20),
          _ExpDetailRow(icon: Icons.person_outline_rounded, label: 'Người được giao', value: task.assignedTo ?? 'Chưa giao', isDark: isDark),
          const SizedBox(height: 12),
          _ExpDetailRow(
            icon: isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
            label: 'Thời hạn',
            value: _formatDate(task.dueDate),
            valueColor: isOverdue ? AppColors.error : null,
            isDark: isDark,
          ),
          if (task.batchId != null && task.batchId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ExpDetailRow(icon: Icons.batch_prediction_rounded, label: 'Batch', value: task.batchId!, isDark: isDark),
          ],
          if (task.stageId != null && task.stageId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ExpDetailRow(icon: Icons.layers_outlined, label: 'Giai đoạn', value: task.stageId!, isDark: isDark),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ExpDetailRow extends StatelessWidget {
  const _ExpDetailRow({required this.icon, required this.label, required this.value, this.valueColor, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary.withAlpha(153)),
        const SizedBox(width: 10),
        Text('$label: ', style: tt.bodyMedium?.copyWith(color: textSecondary)),
        Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? textPrimary)),
      ],
    );
  }
}

// ─── CREATE DESIGN BUTTON ─────────────────────────────────────────────────────

class _CreateDesignButton extends StatelessWidget {
  const _CreateDesignButton({required this.experiment});
  final ExperimentModel experiment;

  void _showCreateDesignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateDesignSheet(experiment: experiment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCreateDesignSheet(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(13),
          borderRadius: AppRadius.heroRadius,
          border: Border.all(color: AppColors.primary.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(Icons.design_services_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo / Cập nhật thiết kế chi tiết',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thêm thiết kế thực nghiệm: loại thiết kế, cỡ mẫu, nhóm xử lý...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CREATE DESIGN SHEET ────────────────────────────────────────────────────

class _CreateDesignSheet extends StatefulWidget {
  const _CreateDesignSheet({required this.experiment});
  final ExperimentModel experiment;

  @override
  State<_CreateDesignSheet> createState() => _CreateDesignSheetState();
}

class _CreateDesignSheetState extends State<_CreateDesignSheet> {
  final _formKey = GlobalKey<FormState>();

  DesignType _selectedDesignType = DesignType.completelyRandomized;
  final _sampleSizeController = TextEditingController();
  final _replicationController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _observationFreqController = TextEditingController();
  final _measurementFreqController = TextEditingController();
  final _evaluationController = TextEditingController();
  final _analysisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sampleSizeController.text = widget.experiment.design.sampleSize.toString();
    _replicationController.text = widget.experiment.design.replicationCount.toString();
    _treatmentController.text = widget.experiment.design.treatmentCount.toString();
    _observationFreqController.text =
        widget.experiment.design.observationFrequencyDays?.toString() ?? '';
    _measurementFreqController.text =
        widget.experiment.design.measurementFrequencyDays?.toString() ?? '';
    _evaluationController.text =
        widget.experiment.design.evaluationCriteria ?? '';
    _analysisController.text =
        widget.experiment.design.analysisPlan ?? '';
  }

  @override
  void dispose() {
    _sampleSizeController.dispose();
    _replicationController.dispose();
    _treatmentController.dispose();
    _observationFreqController.dispose();
    _measurementFreqController.dispose();
    _evaluationController.dispose();
    _analysisController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thiết kế thực nghiệm đã được lưu thành công.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
    );
  }

  String _designTypeLabel(DesignType type) => switch (type) {
    DesignType.completelyRandomized => 'CRD – Completely Randomized Design',
    DesignType.randomizedBlock       => 'RCBD – Randomized Complete Block Design',
    DesignType.factorial            => 'Factorial Design',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient(context),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: const Icon(Icons.design_services_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo thiết kế thực nghiệm',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.experiment.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withAlpha(128)),
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại thiết kế',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...DesignType.values.map((type) => RadioListTile<DesignType>(
                      value: type,
                      groupValue: _selectedDesignType,
                      onChanged: (v) => setState(() => _selectedDesignType = v!),
                      title: Text(_designTypeLabel(type), style: const TextStyle(fontSize: 13)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: _SheetTextField(
                          controller: _sampleSizeController,
                          label: 'Cỡ mẫu (plants)',
                          hint: '60',
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                        )),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _SheetTextField(
                          controller: _replicationController,
                          label: 'Số lần lặp',
                          hint: '3',
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                        )),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SheetTextField(
                      controller: _treatmentController,
                      label: 'Số nhóm xử lý',
                      hint: '2',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: _SheetTextField(
                          controller: _observationFreqController,
                          label: 'Tần suất quan sát (ngày)',
                          hint: '2',
                          keyboardType: TextInputType.number,
                        )),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _SheetTextField(
                          controller: _measurementFreqController,
                          label: 'Tần suất đo lường (ngày)',
                          hint: '7',
                          keyboardType: TextInputType.number,
                        )),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SheetTextField(
                      controller: _evaluationController,
                      label: 'Tiêu chí đánh giá',
                      hint: 'Chiều cao, số lá, tỷ lệ sống...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SheetTextField(
                      controller: _analysisController,
                      label: 'Kế hoạch phân tích',
                      hint: 'ANOVA, Tukey HSD, p < 0.05',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                          ),
                        ),
                        child: Text(
                          'Lưu thiết kế',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
