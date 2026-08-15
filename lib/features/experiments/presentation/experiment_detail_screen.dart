import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/models/growth_task_model.dart' as internal;
import '../../../shared/widgets/staggered_list_item.dart';
import '../../experiments/providers/experiment_provider.dart';
import '../../tasks/providers/task_providers.dart';

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
    _tabController.addListener(_onTabChanged);
    // Pre-load all experiment data to trigger API calls immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(experimentDetailProvider(widget.id));
      ref.read(experimentStagesProvider(widget.id));
      ref.read(experimentGroupsProvider(widget.id));
      ref.read(experimentDesignProvider(widget.id));
      ref.read(experimentTasksProvider(widget.id));
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    // Pre-load data for the selected tab
    if (index == 1) {
      // Design tab
      ref.read(experimentDesignProvider(widget.id));
    } else if (index == 2) {
      // Groups tab
      ref.read(experimentGroupsProvider(widget.id));
    } else if (index == 4) {
      // Tasks tab
      ref.read(experimentTasksProvider(widget.id));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
                _OverviewTab(experimentId: widget.id),
                _DesignTab(experimentId: widget.id),
                _GroupsTab(experimentId: widget.id),
                _ResultsTab(experimentId: widget.id),
                _TasksTab(experimentId: widget.id),
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

  String _fmtDate(DateTime dt) => formatDate(dt);

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

  double get safeProgress {
    if (progress.isNaN || progress.isInfinite) return 0.0;
    return progress.clamp(0.0, 1.0);
  }

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
              value: safeProgress,
              strokeWidth: 3.5,
              backgroundColor: color.withAlpha(25),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '${(safeProgress * 100).round()}%',
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

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.experimentId});
  final String experimentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(experimentStagesProvider(experimentId));
    final groups = ref.watch(experimentGroupsProvider(experimentId));
    final design = ref.watch(experimentDesignProvider(experimentId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Research Goal
          StaggeredListItem(
            index: 0,
            child: _ResearchGoalCard(experimentId: experimentId),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Design KPIs 2x2 - from separate API
          StaggeredListItem(
            index: 1,
            child: _DesignKPIGrid(experimentId: experimentId, design: design),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stages Progress - from separate API
          StaggeredListItem(
            index: 2,
            child: _StagesProgressCard(stages: stages),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Groups Preview - from separate API
          StaggeredListItem(
            index: 3,
            child: _QuickGroupsPreview(experimentId: experimentId, groups: groups),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _ResearchGoalCard extends ConsumerWidget {
  const _ResearchGoalCard({required this.experimentId});
  final String experimentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiment = ref.watch(experimentDetailProvider(experimentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return experiment.when(
      data: (exp) {
        if (exp == null) {
          return const SizedBox.shrink();
        }
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
                          'Mục tiêu nghiên cứu',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exp.title,
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
                exp.objective,
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
      },
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppRadius.heroRadius,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DesignKPIGrid extends StatelessWidget {
  const _DesignKPIGrid({required this.experimentId, required this.design});
  final String experimentId;
  final AsyncValue<ExperimentDesign?> design;

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
              'Thiết kế thực nghiệm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        design.when(
          data: (d) => GridView.count(
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
                label: 'Loại thiết kế',
                value: d?.designTypeLabel ?? '-',
                color: AppColors.primary,
              ),
              _DesignKPICard(
                index: 1,
                icon: Icons.grass_rounded,
                label: 'Cây/lô',
                value: '${d?.designParameters?.plantsPerPlot ?? '-'}',
                unit: 'cây',
                color: AppColors.success,
              ),
              _DesignKPICard(
                index: 2,
                icon: Icons.copy_rounded,
                label: 'Số lần lặp',
                value: '${d?.replicationCount ?? '-'}',
                color: AppColors.info,
              ),
              _DesignKPICard(
                index: 3,
                icon: Icons.group_work_rounded,
                label: 'Nhóm xử lý',
                value: '${d?.designParameters?.treatments ?? '-'}',
                color: AppColors.accent,
              ),
            ],
          ),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(height: 200),
        ),
      ],
    );
  }
}

class _StagesProgressCard extends StatelessWidget {
  const _StagesProgressCard({required this.stages});
  final AsyncValue<List<ExperimentStage>> stages;

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
                color: AppColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Tiến độ giai đoạn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        stages.when(
          data: (stageList) {
            if (stageList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Center(child: Text('Chưa có giai đoạn')),
              );
            }
            return Column(
              children: stageList.asMap().entries.map((entry) {
                final index = entry.key;
                final stage = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _StageProgressItem(stage: stage, index: index),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(height: 100),
        ),
      ],
    );
  }
}

class _StageProgressItem extends StatelessWidget {
  const _StageProgressItem({required this.stage, required this.index});
  final ExperimentStage stage;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = stage.status == StageStatus.completed
        ? AppColors.success
        : stage.status == StageStatus.active
            ? AppColors.primary
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: statusColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              stage.status == StageStatus.completed
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.stageName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stage.stageTypeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(
              stage.status == StageStatus.completed
                  ? 'Hoàn thành'
                  : stage.status == StageStatus.active
                      ? 'Đang thực hiện'
                      : 'Sắp tới',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

class _QuickGroupsPreview extends StatelessWidget {
  const _QuickGroupsPreview({required this.experimentId, required this.groups});
  final String experimentId;
  final AsyncValue<List<ExperimentGroup>> groups;

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
              'Nhóm thí nghiệm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        groups.when(
          data: (groupList) {
            if (groupList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Center(
                  child: Text('Chưa có nhóm thí nghiệm'),
                ),
              );
            }
            return Column(
              children: groupList.asMap().entries.map((entry) {
                final index = entry.key;
                final group = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: StaggeredListItem(
                    index: 4 + index,
                    child: _ResearchGroupCard(group: group),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(height: 100),
        ),
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

class _DesignTab extends ConsumerWidget {
  const _DesignTab({required this.experimentId});
  final String experimentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designAsync = ref.watch(experimentDesignProvider(experimentId));

    return designAsync.when(
      data: (design) {
        if (design == null) {
          return const _PendingDesignPlaceholder();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full design details from API
              StaggeredListItem(
                index: 0,
                child: _DesignDetailSection(design: design),
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: AppSpacing.md),
              Text('Không thể tải thiết kế: $e',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(experimentDesignProvider(experimentId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDesignPlaceholder extends StatelessWidget {
  const _PendingDesignPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warning.withAlpha(77), width: 2),
              ),
              child: const Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có thiết kế',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Thiết kế chi tiết của thực nghiệm chưa được tạo. Vui lòng tạo thiết kế trên web hoặc liên hệ Farm Manager.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignDetailSection extends StatelessWidget {
  const _DesignDetailSection({required this.design});
  final ExperimentDesign design;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final params = design.designParameters;
    
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
                'Thông số thiết kế',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _DetailRow(label: 'Loại thiết kế', value: design.designType, icon: Icons.grid_view_rounded),
          _DetailDivider(),
          _DetailRow(label: 'Phương pháp', value: design.randomizationMethod, icon: Icons.shuffle_rounded),
          _DetailDivider(),
          _DetailRow(label: 'Số lần lặp', value: '${design.replicationCount}', icon: Icons.copy_rounded),
          if (params != null) ...[
            _DetailDivider(),
            _DetailRow(label: 'Số nhóm xử lý', value: '${params.treatments ?? "-"}', icon: Icons.group_work_rounded),
            _DetailDivider(),
            _DetailRow(label: 'Cây/lô', value: '${params.plantsPerPlot ?? "-"}', icon: Icons.grass_rounded),
            _DetailDivider(),
            _DetailRow(label: 'Diện tích lô', value: '${params.plotArea ?? "-"} m²', icon: Icons.square_foot_rounded),
            if (params.spacing != null) ...[
              _DetailDivider(),
              _DetailRow(label: 'Khoảng cách hàng', value: params.spacing!.row ?? '-', icon: Icons.straighten_rounded),
              _DetailDivider(),
              _DetailRow(label: 'Khoảng cách cây', value: params.spacing!.plant ?? '-', icon: Icons.straighten_rounded),
            ],
            if (params.bufferZone != null) ...[
              _DetailDivider(),
              _DetailRow(label: 'Vùng đệm', value: params.bufferZone!, icon: Icons.warning_amber_rounded),
            ],
            if (params.randomSeed != null) ...[
              _DetailDivider(),
              _DetailRow(label: 'Random Seed', value: '${params.randomSeed}', icon: Icons.tag_rounded),
            ],
          ],
          if (params?.notes != null && params!.notes!.isNotEmpty) ...[
            _DetailDivider(),
            _DetailRow(label: 'Ghi chú', value: params.notes!, icon: Icons.note_rounded),
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

// ─── TAB 3: GROUPS ───────────────────────────────────────────────────────────

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab({required this.experimentId});
  final String experimentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(experimentGroupsProvider(experimentId));

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Chưa có nhóm thí nghiệm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Các nhóm thí nghiệm sẽ được hiển thị sau khi được tạo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          itemCount: groups.length,
          separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final group = groups[index];
            return StaggeredListItem(
              index: index,
              child: _FullGroupCard(group: group),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
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

class _ResultsTab extends ConsumerWidget {
  const _ResultsTab({required this.experimentId});
  final String experimentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(experimentStagesProvider(experimentId));
    final groups = ref.watch(experimentGroupsProvider(experimentId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredListItem(
            index: 0,
            child: _ResultsIntro(stages: stages, groups: groups),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Show groups from API /experiments/{id}/groups
          groups.when(
            data: (groupList) {
              if (groupList.isEmpty) return const SizedBox.shrink();
              return Column(
                children: groupList.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: StaggeredListItem(
                    index: e.key + 1,
                    child: _GroupResultCard(group: e.value, index: e.key),
                  ),
                )).toList(),
              );
            },
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Show completed stages from API /experiments/{id}/stages
          stages.when(
            data: (stageList) {
              final completed = stageList.where((s) => s.status == StageStatus.completed).toList();
              if (completed.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredListItem(
                    index: 10,
                    child: _StagesResultsSection(stages: completed),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _ResultsIntro extends StatelessWidget {
  const _ResultsIntro({required this.stages, required this.groups});
  final AsyncValue<List<ExperimentStage>> stages;
  final AsyncValue<List<ExperimentGroup>> groups;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = stages.valueOrNull?.where((s) => s.status == StageStatus.completed).length ?? 0;
    final groupCount = groups.valueOrNull?.length ?? 0;
    
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
                  'Kết quả thí nghiệm',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$groupCount nhóm | $completedCount giai đoạn hoàn thành',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
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

class _GroupResultCard extends StatelessWidget {
  const _GroupResultCard({required this.group, required this.index});
  final ExperimentGroup group;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bgCard = isDark ? AppColors.cardDark : AppColors.cardLight;
    final groupColor = index == 0 ? AppColors.primary : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 8), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: groupColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: Icon(group.groupType == GroupType.control ? Icons.science_outlined : Icons.science_rounded, size: 18, color: groupColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.groupName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(group.groupType == GroupType.control ? 'Nhóm đối chứng' : 'Nhóm thực nghiệm', style: tt.labelSmall?.copyWith(color: groupColor)),
                  ],
                ),
              ),
              if (group.sampleSize > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: groupColor.withAlpha(20), borderRadius: BorderRadius.circular(AppRadius.small)),
                  child: Text('n=${group.sampleSize}', style: tt.labelSmall?.copyWith(color: groupColor, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(group.description!, style: tt.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ],
      ),
    );
  }
}

class _StagesResultsSection extends StatelessWidget {
  const _StagesResultsSection({required this.stages});
  final List<ExperimentStage> stages;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kết quả theo giai đoạn', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ...stages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < stages.length - 1 ? AppSpacing.md : 0),
            child: _StageResultCard(stage: stage),
          );
        }),
      ],
    );
  }
}

class _StageResultCard extends StatelessWidget {
  const _StageResultCard({required this.stage});
  final ExperimentStage stage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bgCard = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.success.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stage.stageName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(stage.stageTypeLabel, style: tt.labelSmall?.copyWith(color: AppColors.success)),
                  ],
                ),
              ),
              Text('Giai đoạn ${stage.stageOrder}', style: tt.labelSmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ],
          ),
          if (stage.result?.summary.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(stage.result!.summary, style: tt.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ],
      ),
    );
  }
}

// ─── TAB 5: TASKS (Premium Smart Task List với API thật) ─────────────────

class _TasksTab extends ConsumerStatefulWidget {
  const _TasksTab({required this.experimentId});
  final String experimentId;

  @override
  ConsumerState<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<_TasksTab> {
  TaskFilter _activeFilter = TaskFilter.all;
  int? _overdueDays;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(experimentTasksProvider(widget.experimentId));

    return Column(
      children: [
        // KPI Stats
        tasks.when(
          data: (taskList) => _ExpTaskStatsBar(tasks: taskList),
          loading: () => const SizedBox(height: 100),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Filter Chips
        _ExpFilterChipsRow(
          activeFilter: _activeFilter,
          onFilterChanged: (f) => setState(() {
            _activeFilter = f;
            _overdueDays = null; // Reset overdue filter when changing main filter
          }),
        ),
        // Overdue date filter (khi chọn filter quá hạn)
        if (_activeFilter == TaskFilter.overdue)
          _ExpOverdueDateFilter(
            overdueDays: _overdueDays,
            onChanged: (days) => setState(() => _overdueDays = days),
          ),
        // Task List
        Expanded(
          child: tasks.when(
            data: (taskList) {
              if (taskList.isEmpty) {
                return _TasksEmptyState(message: 'Chưa có công việc nào');
              }
              return _ExpSmartTaskList(
                tasks: taskList,
                filter: _activeFilter,
                experimentId: widget.experimentId,
                overdueDays: _overdueDays,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
          ),
        ),
      ],
    );
  }
}

enum TaskFilter { all, overdue, today, upcoming, completed }

// Overdue Date Filter cho Experiment Tasks Tab
class _ExpOverdueDateFilter extends StatelessWidget {
  const _ExpOverdueDateFilter({required this.overdueDays, required this.onChanged});
  final int? overdueDays;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ExpDateChip(label: 'Tất cả', isSelected: overdueDays == null, onTap: () => onChanged(null), isDark: isDark),
          const SizedBox(width: 8),
          _ExpDateChip(label: '1 ngày', isSelected: overdueDays == 1, onTap: () => onChanged(1), isDark: isDark),
          const SizedBox(width: 8),
          _ExpDateChip(label: '3 ngày', isSelected: overdueDays == 3, onTap: () => onChanged(3), isDark: isDark),
          const SizedBox(width: 8),
          _ExpDateChip(label: '7 ngày', isSelected: overdueDays == 7, onTap: () => onChanged(7), isDark: isDark),
          const SizedBox(width: 8),
          _ExpDateChip(label: '14 ngày', isSelected: overdueDays == 14, onTap: () => onChanged(14), isDark: isDark),
        ],
      ),
    );
  }
}

class _ExpDateChip extends StatelessWidget {
  const _ExpDateChip({required this.label, required this.isSelected, required this.onTap, required this.isDark});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.error : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.error : Colors.grey.withAlpha(60)),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}

// Section Header for Experiment Tasks
class _ExpSectionHeader extends StatelessWidget {
  const _ExpSectionHeader({required this.label, required this.count, this.isOverdue = false, this.isCompleted = false});
  final String label;
  final int count;
  final bool isOverdue;
  final bool isCompleted;

  Color get _color {
    if (isOverdue) return AppColors.error;
    if (isCompleted) return AppColors.success;
    if (label == 'Hôm nay') return AppColors.warning;
    if (label == 'Ngày mai') return AppColors.info;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _color.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOverdue) ...[Icon(Icons.warning_amber_rounded, size: 14, color: _color), const SizedBox(width: 4)],
              if (isCompleted) ...[Icon(Icons.check_circle_rounded, size: 14, color: _color), const SizedBox(width: 4)],
              Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: _color)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: _color)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [_color.withAlpha(60), _color.withAlpha(0)])))),
      ],
    );
  }
}

class _ExpTaskStatsBar extends StatelessWidget {
  const _ExpTaskStatsBar({required this.tasks});
  final List<internal.TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final today = todayInVN();
    final weekLater = today.add(const Duration(days: 7));

    int overdueCount = 0, todayCount = 0, upcomingCount = 0, completedCount = 0;

    for (final task in tasks) {
      final dueDate = dateOnlyInVN(task.dueDate);
      if (task.status == internal.TaskStatus.completed) {
        completedCount++;
      } else if (dueDate.isBefore(today)) {
        overdueCount++;
      } else if (dueDate == today) {
        todayCount++;
      } else if (dueDate.isBefore(weekLater)) {
        upcomingCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _ExpStatTile(label: 'Quá hạn', count: overdueCount, color: AppColors.error, icon: Icons.warning_rounded),
          const SizedBox(width: 8),
          _ExpStatTile(label: 'Hôm nay', count: todayCount, color: AppColors.warning, icon: Icons.today_rounded),
          const SizedBox(width: 8),
          _ExpStatTile(label: 'Sắp tới', count: upcomingCount, color: AppColors.info, icon: Icons.schedule_rounded),
          const SizedBox(width: 8),
          _ExpStatTile(label: 'Xong', count: completedCount, color: AppColors.success, icon: Icons.check_circle_rounded),
        ],
      ),
    );
  }
}

class _ExpStatTile extends StatelessWidget {
  const _ExpStatTile({required this.label, required this.count, required this.color, required this.icon});
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text('$count', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            Text(label, style: tt.labelSmall?.copyWith(fontSize: 9, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}

class _ExpFilterChipsRow extends StatelessWidget {
  const _ExpFilterChipsRow({required this.activeFilter, required this.onFilterChanged});
  final TaskFilter activeFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ExpFilterChip(label: 'Tất cả', isSelected: activeFilter == TaskFilter.all, onTap: () => onFilterChanged(TaskFilter.all)),
          const SizedBox(width: 8),
          _ExpFilterChip(label: 'Quá hạn', isSelected: activeFilter == TaskFilter.overdue, onTap: () => onFilterChanged(TaskFilter.overdue), color: AppColors.error),
          const SizedBox(width: 8),
          _ExpFilterChip(label: 'Hôm nay', isSelected: activeFilter == TaskFilter.today, onTap: () => onFilterChanged(TaskFilter.today), color: AppColors.warning),
          const SizedBox(width: 8),
          _ExpFilterChip(label: 'Sắp tới', isSelected: activeFilter == TaskFilter.upcoming, onTap: () => onFilterChanged(TaskFilter.upcoming), color: AppColors.info),
          const SizedBox(width: 8),
          _ExpFilterChip(label: 'Hoàn thành', isSelected: activeFilter == TaskFilter.completed, onTap: () => onFilterChanged(TaskFilter.completed), color: AppColors.success),
        ],
      ),
    );
  }
}

class _ExpFilterChip extends StatelessWidget {
  const _ExpFilterChip({required this.label, required this.isSelected, required this.onTap, this.color});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? activeColor : (isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}

class _ExpSmartTaskList extends StatelessWidget {
  const _ExpSmartTaskList({required this.tasks, required this.filter, required this.experimentId, this.overdueDays});
  final List<internal.TaskModel> tasks;
  final TaskFilter filter;
  final String experimentId;
  final int? overdueDays;

  List<internal.TaskModel> get _filtered {
    final today = todayInVN();
    final weekLater = today.add(const Duration(days: 7));

    switch (filter) {
      case TaskFilter.all: return tasks;
      case TaskFilter.today:
        final tomorrow = today.add(const Duration(days: 1));
        return tasks.where((t) {
          final due = dateOnlyInVN(t.dueDate);
          return due == today || due == tomorrow;
        }).toList();
      case TaskFilter.upcoming:
        return tasks.where((t) {
          final due = dateOnlyInVN(t.dueDate);
          return due.isAfter(today) && due.isBefore(weekLater);
        }).toList();
      case TaskFilter.overdue:
        return tasks.where((t) {
          final due = dateOnlyInVN(t.dueDate);
          if (due.isBefore(today) && t.status != internal.TaskStatus.completed) {
            if (overdueDays != null) {
              final daysDiff = today.difference(due).inDays;
              return daysDiff <= overdueDays!;
            }
            return true;
          }
          return false;
        }).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.status == internal.TaskStatus.completed).toList();
    }
  }

  Map<String, List<internal.TaskModel>> get _grouped {
    final Map<String, List<internal.TaskModel>> grouped = {};
    final today = todayInVN();
    final tomorrow = today.add(const Duration(days: 1));

    for (final task in _filtered) {
      final dueDate = dateOnlyInVN(task.dueDate);
      String key;

      if (task.status == internal.TaskStatus.completed) {
        key = 'Hoàn thành';
      } else if (dueDate.isBefore(today)) {
        final daysOverdue = today.difference(dueDate).inDays;
        if (daysOverdue == 1) {
          key = 'Quá hạn 1 ngày';
        } else if (daysOverdue <= 3) {
          key = 'Quá hạn 1-3 ngày';
        } else if (daysOverdue <= 7) {
          key = 'Quá hạn 3-7 ngày';
        } else {
          key = 'Quá hạn $daysOverdue ngày';
        }
      } else if (dueDate == today) {
        key = 'Hôm nay';
      } else if (dueDate == tomorrow) {
        key = 'Ngày mai';
      } else {
        key = 'Sắp tới';
      }

      grouped.putIfAbsent(key, () => []).add(task);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(child: Text('Không có công việc phù hợp'));
    }

    final grouped = _grouped;
    final sections = grouped.keys.toList();

    // Sort sections in logical order
    sections.sort((a, b) {
      final order = ['Quá hạn 1 ngày', 'Quá hạn 1-3 ngày', 'Quá hạn 3-7 ngày', 'Hôm nay', 'Ngày mai', 'Sắp tới', 'Hoàn thành'];
      final aIndex = order.indexWhere((o) => b.contains(o));
      final bIndex = order.indexWhere((o) => a.contains(o));
      if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      return a.compareTo(b);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final section = sections[i];
        final sectionTasks = grouped[section]!;
        final isOverdueSection = section.contains('Quá hạn');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExpSectionHeader(
              label: section,
              count: sectionTasks.length,
              isOverdue: isOverdueSection,
              isCompleted: section == 'Hoàn thành',
            ),
            const SizedBox(height: 10),
            ...sectionTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExpPremiumTaskCard(
                task: task,
                onReportTap: task.status == internal.TaskStatus.completed ? () => _showReport(context, task) : null,
              ),
            )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showReport(BuildContext context, internal.TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ExpTaskReportSheet(task: task),
    );
  }
}

class _ExpPremiumTaskCard extends StatelessWidget {
  const _ExpPremiumTaskCard({required this.task, this.onReportTap});
  final internal.TaskModel task;
  final VoidCallback? onReportTap;

  Color get _statusColor => switch (task.status) {
    internal.TaskStatus.pending => AppColors.warning,
    internal.TaskStatus.inProgress => AppColors.info,
    internal.TaskStatus.completed => AppColors.success,
    internal.TaskStatus.overdue => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    internal.TaskType.planting => Icons.grass_rounded,
    internal.TaskType.watering => Icons.water_drop_rounded,
    internal.TaskType.fertilizing => Icons.science_rounded,
    internal.TaskType.observation => Icons.visibility_rounded,
    internal.TaskType.inspection => Icons.search_rounded,
    internal.TaskType.other => Icons.more_horiz_rounded,
  };

  String get _statusLabel => switch (task.status) {
    internal.TaskStatus.pending => 'Chờ xử lý',
    internal.TaskStatus.inProgress => 'Đang thực hiện',
    internal.TaskStatus.completed => 'Hoàn thành',
    internal.TaskStatus.overdue => 'Quá hạn',
  };

  bool get _isOverdue => task.status == internal.TaskStatus.overdue ||
      (task.status != internal.TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isOverdue ? AppColors.error.withAlpha(50) : (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 8), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_typeIcon, size: 22, color: _statusColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.taskName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (task.experimentStageName != null) ...[
                                const SizedBox(height: 2),
                                Text(task.experimentStageName!, style: tt.bodySmall?.copyWith(color: AppColors.primary.withAlpha(200), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        _ExpMetaTag(icon: Icons.person_outline_rounded, label: task.assignedTo ?? 'Chưa giao', color: AppColors.primary),
                        _ExpMetaTag(icon: _isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded, label: _formatDueDate(task.dueDate), color: _isOverdue ? AppColors.error : textSecondary),
                        if (task.batchCode != null) _ExpMetaTag(icon: Icons.inventory_2_outlined, label: task.batchCode!, color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
              // Report button for completed tasks
              if (task.status == internal.TaskStatus.completed && onReportTap != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(10),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                    border: Border(top: BorderSide(color: AppColors.success.withAlpha(30))),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onReportTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assessment_rounded, size: 18, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text('Xem báo cáo', style: tt.labelMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.success),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ExpTaskDetailSheet(task: task),
    );
  }

  String _formatDueDate(DateTime dt) {
    final today = todayInVN();
    final due = dateOnlyInVN(dt);
    if (due == today) return 'Hôm nay';
    if (due == today.add(const Duration(days: 1))) return 'Ngày mai';
    if (due.isBefore(today)) return 'Quá hạn';
    return formatDateShort(dt);
  }
}

class _ExpMetaTag extends StatelessWidget {
  const _ExpMetaTag({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withAlpha(180)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label, style: tt.labelSmall?.copyWith(color: color.withAlpha(200), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ExpTaskDetailSheet extends StatelessWidget {
  const _ExpTaskDetailSheet({required this.task});
  final internal.TaskModel task;

  Color get _statusColor => switch (task.status) {
    internal.TaskStatus.pending => AppColors.warning,
    internal.TaskStatus.inProgress => AppColors.info,
    internal.TaskStatus.completed => AppColors.success,
    internal.TaskStatus.overdue => AppColors.error,
  };

  IconData get _typeIcon => switch (task.taskType) {
    internal.TaskType.planting => Icons.grass_rounded,
    internal.TaskType.watering => Icons.water_drop_rounded,
    internal.TaskType.fertilizing => Icons.science_rounded,
    internal.TaskType.observation => Icons.visibility_rounded,
    internal.TaskType.inspection => Icons.search_rounded,
    internal.TaskType.other => Icons.more_horiz_rounded,
  };

  String get _statusLabel => switch (task.status) {
    internal.TaskStatus.pending => 'Chờ xử lý',
    internal.TaskStatus.inProgress => 'Đang thực hiện',
    internal.TaskStatus.completed => 'Hoàn thành',
    internal.TaskStatus.overdue => 'Quá hạn',
  };

  bool get _isOverdue => task.status == internal.TaskStatus.overdue ||
      (task.status != internal.TaskStatus.completed && task.dueDate.isBefore(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128), borderRadius: BorderRadius.circular(2))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(14)), child: Icon(_typeIcon, size: 28, color: _statusColor)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.taskName, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600))),
                  ],
                )),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    _ExpDetailItem(icon: Icons.description_outlined, label: 'Mô tả', value: task.description!, color: AppColors.info, isDark: isDark),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    Expanded(child: _ExpMiniDetail(icon: Icons.person_outline_rounded, label: 'Người được giao', value: task.assignedTo ?? 'Chưa giao', isDark: isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _ExpMiniDetail(icon: _isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined, label: 'Thời hạn', value: _formatDate(task.dueDate), valueColor: _isOverdue ? AppColors.error : null, isDark: isDark)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ExpMiniDetail(icon: Icons.layers_outlined, label: 'Giai đoạn', value: task.experimentStageName ?? 'Không có', isDark: isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _ExpMiniDetail(icon: Icons.inventory_2_outlined, label: 'Lô (Batch)', value: task.batchCode ?? 'Không có', isDark: isDark)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => formatDueDate(dt);
}

class _ExpDetailItem extends StatelessWidget {
  const _ExpDetailItem({required this.icon, required this.label, required this.value, required this.color, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(30))),
      child: Row(children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tt.labelSmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 3, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

class _ExpMiniDetail extends StatelessWidget {
  const _ExpMiniDetail({required this.icon, required this.label, required this.value, this.valueColor, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgCard = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(60))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: textSecondary.withAlpha(153)), const SizedBox(width: 6), Text(label, style: tt.labelSmall?.copyWith(color: textSecondary.withAlpha(153)))]),
          const SizedBox(height: 4),
          Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ExpTaskReportSheet extends ConsumerWidget {
  const _ExpTaskReportSheet({required this.task});
  final internal.TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportAsync = ref.watch(taskReportByTaskProvider(task.id));
    final imagesAsync = ref.watch(taskImagesByTaskProvider(task.id));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128), borderRadius: BorderRadius.circular(2))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assessment_rounded, color: AppColors.success, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Báo cáo: ${task.taskName}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('Thông tin báo cáo từ người thực hiện', style: tt.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ])),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: reportAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 64, color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77)),
                      const SizedBox(height: 12),
                      Text('Chưa có báo cáo', style: tt.titleMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      Text('Báo cáo sẽ được cập nhật sau khi công việc hoàn thành', style: tt.bodySmall?.copyWith(color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153))),
                    ],
                  ));
                }
                // Hiển thị báo cáo mới nhất
                final sorted = [...reports]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
                final report = sorted.first;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpReportItem(icon: Icons.description_rounded, label: 'Nội dung báo cáo', value: report.description.isNotEmpty ? report.description : report.title, color: AppColors.info, isDark: isDark),
                      const SizedBox(height: 12),
                      _ExpReportItem(icon: Icons.person_rounded, label: 'Người nộp', value: report.submittedBy ?? 'Không xác định', color: AppColors.primary, isDark: isDark),
                      const SizedBox(height: 12),
                      _ExpReportItem(icon: Icons.calendar_today_rounded, label: 'Ngày nộp', value: _formatDateTime(report.submittedAt), color: AppColors.success, isDark: isDark),
                      const SizedBox(height: 24),
                      Row(children: [
                        Icon(Icons.photo_library_rounded, size: 20, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('Hình ảnh', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      imagesAsync.when(
                        data: (images) {
                          if (images.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight).withAlpha(128), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('Chưa có hình ảnh', style: tt.bodyMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                            );
                          }
                          return SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final image = images[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: index < images.length - 1 ? 12 : 0),
                                  child: GestureDetector(
                                    onTap: () => _showImageFullScreen(context, image.imageUrl),
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.primary.withAlpha(20)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(image.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey))),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Lỗi tải ảnh: $e'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(imageUrl, fit: BoxFit.contain))),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => formatDateTime(dt);
}

class _ExpReportItem extends StatelessWidget {
  const _ExpReportItem({required this.icon, required this.label, required this.value, required this.color, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(30))),
      child: Row(children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tt.labelSmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 3, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

class _TasksEmptyState extends ConsumerWidget {
  const _TasksEmptyState({this.message});
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final bgCard = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_outlined, size: 56, color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77)),
            const SizedBox(height: AppSpacing.lg),
            Text(message ?? 'Chưa có task nào', style: tt.titleMedium?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
            if (message == null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Tạo task để theo dõi tiến độ thực nghiệm', style: tt.bodySmall?.copyWith(color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153)), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
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

