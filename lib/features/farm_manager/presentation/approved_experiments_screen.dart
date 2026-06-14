import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_animation.dart';

class ApprovedExperimentsScreen extends ConsumerStatefulWidget {
  const ApprovedExperimentsScreen({super.key});

  @override
  ConsumerState<ApprovedExperimentsScreen> createState() => _ApprovedExperimentsScreenState();
}

class _ApprovedExperimentsScreenState extends ConsumerState<ApprovedExperimentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final approvedExps = ref.watch(approvedExperimentsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Yêu cầu đã duyệt',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            color: isDark ? AppColors.surfaceDark : cs.surface,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm yêu cầu...',
                hintStyle: tt.bodyMedium?.copyWith(
                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(153),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: 20,
                ),
                filled: true,
                fillColor: bgColor.withAlpha(128),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          // Tab bar
          Container(
            color: isDark ? AppColors.surfaceDark : cs.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              labelStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Đang chạy'),
                Tab(text: 'Hoàn thành'),
                Tab(text: 'Tạm dừng'),
              ],
            ),
          ),
          // List
          Expanded(
            child: approvedExps.when(
              data: (exps) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _ApprovedList(
                      exps: exps
                          .where((e) => e.status == _ExpStatus.active)
                          .toList(),
                      searchQuery: _searchQuery,
                      emptyLabel: 'Không có thí nghiệm đang chạy',
                    ),
                    _ApprovedList(
                      exps: exps
                          .where((e) => e.status == _ExpStatus.completed)
                          .toList(),
                      searchQuery: _searchQuery,
                      emptyLabel: 'Không có thí nghiệm hoàn thành',
                    ),
                    _ApprovedList(
                      exps: exps
                          .where((e) => e.status == _ExpStatus.paused)
                          .toList(),
                      searchQuery: _searchQuery,
                      emptyLabel: 'Không có thí nghiệm tạm dừng',
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedList extends StatelessWidget {
  const _ApprovedList({required this.exps, required this.searchQuery, required this.emptyLabel});
  final List<_ApprovedExp> exps;
  final String searchQuery;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    var filtered = exps;
    if (searchQuery.isNotEmpty) {
      filtered = exps.where((e) =>
          e.title.toLowerCase().contains(searchQuery) ||
          e.researcherName.toLowerCase().contains(searchQuery) ||
          e.cropVariety.toLowerCase().contains(searchQuery)
      ).toList();
    }

    if (filtered.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(77),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              searchQuery.isNotEmpty ? 'Không tìm thấy yêu cầu phù hợp' : emptyLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: filtered.length,
      separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _ApprovedExpCard(exp: filtered[index]),
    );
  }
}

class _ApprovedExpCard extends StatefulWidget {
  const _ApprovedExpCard({required this.exp});
  final _ApprovedExp exp;

  @override
  State<_ApprovedExpCard> createState() => _ApprovedExpCardState();
}

class _ApprovedExpCardState extends State<_ApprovedExpCard> {
  bool _isPressed = false;

  Color get _statusColor => switch (widget.exp.status) {
    _ExpStatus.active    => AppColors.success,
    _ExpStatus.completed => AppColors.neutral,
    _ExpStatus.paused   => AppColors.warning,
  };

  String get _statusLabel => switch (widget.exp.status) {
    _ExpStatus.active    => 'Đang chạy',
    _ExpStatus.completed => 'Hoàn thành',
    _ExpStatus.paused    => 'Tạm dừng',
  };

  IconData get _statusIcon => switch (widget.exp.status) {
    _ExpStatus.active    => Icons.play_circle_rounded,
    _ExpStatus.completed => Icons.check_circle_rounded,
    _ExpStatus.paused    => Icons.pause_circle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final statusColor = _statusColor;

    // Colored shadow toward status color
    final shadowColor = isDark
        ? statusColor.withAlpha(12)
        : statusColor.withAlpha(7);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppDuration.quick,
        curve: AppCurve.standard,
        transform: Matrix4.translationValues(0.0, _isPressed ? 1.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: _isPressed
                ? statusColor.withAlpha(80)
                : (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80),
            width: _isPressed ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.cardRadius,
          child: InkWell(
            onTap: () {},
            borderRadius: AppRadius.cardRadius,
            splashColor: statusColor.withAlpha(13),
            highlightColor: statusColor.withAlpha(8),
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
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withAlpha(30), width: 0.8),
                        ),
                        child: Icon(_statusIcon, size: 22, color: statusColor),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.exp.title,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  widget.exp.researcherName,
                                  style: tt.bodySmall?.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withAlpha(35), width: 0.8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: tt.labelSmall?.copyWith(
                            color: statusColor,
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
                      _MetaChip(
                        icon: Icons.grass_rounded,
                        label: widget.exp.cropVariety,
                        color: AppColors.primary,
                      ),
                      _MetaChip(
                        icon: Icons.straighten_rounded,
                        label: '${widget.exp.plantCount} cây',
                        color: textSecondary,
                      ),
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: '${_fmt(widget.exp.startDate)} - ${_fmt(widget.exp.endDate)}',
                        color: textSecondary,
                      ),
                      _MetaChip(
                        icon: Icons.grid_view_rounded,
                        label: '${widget.exp.bedCount} luống',
                        color: textSecondary,
                      ),
                    ],
                  ),
                  if (widget.exp.progress != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tiến độ', style: tt.labelSmall?.copyWith(color: textSecondary)),
                            Text('${widget.exp.progress}%', style: tt.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.exp.progress! / 100,
                            backgroundColor: statusColor.withAlpha(25),
                            valueColor: AlwaysStoppedAnimation(statusColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});
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

// ─── Providers ──────────────────────────────────────────────────────────────────

enum _ExpStatus { active, completed, paused }

class _ApprovedExp {
  final String id;
  final String title;
  final String researcherName;
  final String cropVariety;
  final int plantCount;
  final int bedCount;
  final DateTime startDate;
  final DateTime endDate;
  final _ExpStatus status;
  final int? progress;

  const _ApprovedExp({
    required this.id,
    required this.title,
    required this.researcherName,
    required this.cropVariety,
    required this.plantCount,
    required this.bedCount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.progress,
  });
}

final approvedExperimentsProvider = FutureProvider<List<_ApprovedExp>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    _ApprovedExp(
      id: 'fm-exp-001',
      title: 'So sánh phương pháp tưới nhỏ giọt thông minh',
      researcherName: 'TS. Nguyễn Minh Khoa',
      cropVariety: 'Cà chua bi Cherry 101',
      plantCount: 60,
      bedCount: 4,
      startDate: DateTime(2024, 7, 1),
      endDate: DateTime(2024, 9, 30),
      status: _ExpStatus.active,
      progress: 62,
    ),
    _ApprovedExp(
      id: 'fm-exp-002',
      title: 'So sánh giống ớt chuông trong điều kiện nhà kính',
      researcherName: 'TS. Trần Thị Lan',
      cropVariety: 'Ớt chuông đỏ',
      plantCount: 80,
      bedCount: 6,
      startDate: DateTime(2024, 8, 1),
      endDate: DateTime(2024, 11, 30),
      status: _ExpStatus.active,
      progress: 38,
    ),
    _ApprovedExp(
      id: 'fm-exp-003',
      title: 'Thí nghiệm phân bón hữu cơ trên rau muống',
      researcherName: 'PGS. Hoàng Văn Minh',
      cropVariety: 'Rau muống VT5',
      plantCount: 120,
      bedCount: 3,
      startDate: DateTime(2024, 6, 1),
      endDate: DateTime(2024, 7, 30),
      status: _ExpStatus.completed,
      progress: 100,
    ),
    _ApprovedExp(
      id: 'fm-exp-004',
      title: 'Khảo sát ánh sáng LED trên rau xanh',
      researcherName: 'TS. Lê Thị Hương',
      cropVariety: 'Rau xanh các loại',
      plantCount: 40,
      bedCount: 2,
      startDate: DateTime(2024, 5, 1),
      endDate: DateTime(2024, 6, 30),
      status: _ExpStatus.paused,
      progress: 45,
    ),
  ];
});
