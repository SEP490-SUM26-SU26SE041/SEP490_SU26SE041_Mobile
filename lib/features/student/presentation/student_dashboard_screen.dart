import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../../shared/widgets/plant_photo_gallery.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/models/growth_task_model.dart';
import '../providers/student_task_providers.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final tasks = ref.watch(studentTasksProvider);

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.dashboard,
        accentColor: AppColors.accent,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderSection(tt: tt, cs: cs),
                      const SizedBox(height: AppSpacing.xl),
                      _buildKPIGrid(context, tasks),
                      const SizedBox(height: AppSpacing.xl),
                      const GradientHeader(
                        title: 'Hình ảnh cây gần đây',
                        subtitle: 'Cập nhật từ Student & Technician',
                        leading: Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const PlantPhotoGallery(maxPhotos: 5),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              // Cong viec cho xu ly section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _SectionTitle(
                    title: 'Cong viec cho xu ly',
                    tt: tt,
                    icon: Icons.pending_actions_rounded,
                    badge: _getPendingCount(tasks),
                    ttBadge: tt,
                    cs: cs,
                    onSeeAll: () => context.go('/student/tasks'),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: AppSpacing.md)),
              tasks.when(
                data: (taskList) {
                  final pending = taskList.where((t) => t.status != TaskStatus.completed).toList();
                  if (pending.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _EmptyTaskCard(tt: tt, cs: cs, message: 'Khong co cong viec nao cho xu ly'),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: index == pending.length - 1 ? AppSpacing.xl : AppSpacing.sm,
                        ),
                        child: _TaskCard(task: pending[index], tt: tt, cs: cs),
                      ),
                      childCount: pending.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, s) => const SliverToBoxAdapter(child: SizedBox()),
              ),
              // Da hoan thanh section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                  child: _SectionTitle(
                    title: 'Da hoan thanh tuan nay',
                    tt: tt,
                    icon: Icons.task_alt_rounded,
                    badge: _getCompletedCount(tasks),
                    ttBadge: tt,
                    cs: cs,
                    onSeeAll: () => context.go('/student/tasks'),
                  ),
                ),
              ),
              tasks.when(
                data: (taskList) {
                  final completed = taskList.where((t) => t.status == TaskStatus.completed).toList();
                  if (completed.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _EmptyTaskCard(tt: tt, cs: cs, message: 'Chua co cong viec hoan thanh'),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: index == completed.length - 1 ? AppSpacing.xl : AppSpacing.sm,
                        ),
                        child: _TaskCard(task: completed[index], tt: tt, cs: cs),
                      ),
                      childCount: completed.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox()),
                error: (e, s) => const SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getPendingCount(AsyncValue<List<TaskModel>> tasks) {
    return tasks.whenOrNull(
      data: (list) {
        final n = list.where((t) => t.status != TaskStatus.completed).length;
        return n > 0 ? n.toString() : null;
      },
    );
  }

  String? _getCompletedCount(AsyncValue<List<TaskModel>> tasks) {
    return tasks.whenOrNull(
      data: (list) {
        final n = list.where((t) => t.status == TaskStatus.completed).length;
        return n > 0 ? n.toString() : null;
      },
    );
  }

  Widget _buildKPIGrid(BuildContext context, AsyncValue<List<TaskModel>> tasks) {
    final todayCount = tasks.whenOrNull(
      data: (list) => list.where((t) =>
        t.dueDate.year == DateTime.now().year &&
        t.dueDate.month == DateTime.now().month &&
        t.dueDate.day == DateTime.now().day
      ).length,
    ) ?? 0;
    final pendingCount = tasks.whenOrNull(
      data: (list) => list.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.inProgress).length,
    ) ?? 0;
    final completedCount = tasks.whenOrNull(
      data: (list) => list.where((t) => t.status == TaskStatus.completed).length,
    ) ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    Widget kpiCard({
      required Color color,
      required IconData icon,
      required int value,
      required String label,
    }) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 22 : 10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(30)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary)),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: kpiCard(color: AppColors.info, icon: Icons.task_alt_rounded, value: todayCount, label: 'Hôm nay')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: kpiCard(color: AppColors.warning, icon: Icons.pending_actions_rounded, value: pendingCount, label: 'Đang xử lý')),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: kpiCard(color: AppColors.success, icon: Icons.check_circle_outline_rounded, value: completedCount, label: 'Hoàn thành')),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng!';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều!';
    } else {
      greeting = 'Chào buổi tối!';
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: AppSpacing.xs),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Sinh viên nghiên cứu', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const ProfileButton(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.tt, required this.icon, required this.badge, required this.ttBadge, required this.cs, required this.onSeeAll});
  final String title;
  final TextTheme tt;
  final IconData icon;
  final String? badge;
  final TextTheme ttBadge;
  final ColorScheme cs;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            if (badge != null && badge != '0') ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge!, style: ttBadge.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Text('Xem tat ca', style: tt.labelMedium?.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  const _EmptyTaskCard({required this.tt, required this.cs, required this.message});
  final TextTheme tt;
  final ColorScheme cs;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: 16,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: AppColors.success.withAlpha(180)),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.tt, required this.cs});

  final TaskModel task;
  final TextTheme tt;
  final ColorScheme cs;

  Color get _statusColor {
    return switch (task.status) {
      TaskStatus.pending    => AppColors.warning,
      TaskStatus.inProgress => AppColors.primary,
      TaskStatus.completed  => AppColors.success,
      TaskStatus.overdue    => AppColors.error,
    };
  }

  IconData get _icon {
    return switch (task.taskType) {
      TaskType.planting    => Icons.eco_rounded,
      TaskType.watering   => Icons.water_drop_rounded,
      TaskType.fertilizing => Icons.science_rounded,
      TaskType.observation => Icons.visibility_rounded,
      TaskType.inspection  => Icons.search_rounded,
      TaskType.other       => Icons.more_horiz_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Use API data directly, fallback to — if not available
    final expCode = task.experimentCode ?? '—';
    final stageName = task.experimentStageName ?? '—';
    final batchLabel = task.batchCode ?? '—';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: 16,
      elevation: 6,
      onTap: () => _showTaskDetail(context, task),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _statusColor.withAlpha(40),
                      _statusColor.withAlpha(15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, size: 22, color: _statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.taskName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(expCode, style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 10)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stageName,
                            style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _statusColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                    child: Text(task.statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Student',
                      style: tt.labelSmall?.copyWith(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (batchLabel != '—') ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.batch_prediction_rounded, size: 11, color: cs.onSurface.withAlpha(102)),
                const SizedBox(width: 4),
                Text(batchLabel, style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128), fontSize: 10)),
                const Spacer(),
                Icon(Icons.schedule_rounded, size: 11, color: cs.onSurface.withAlpha(102)),
                const SizedBox(width: 2),
                Text(formatTime(task.dueDate), style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(102), fontSize: 10)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showTaskDetail(BuildContext context, TaskModel task) {
    context.push('/student/tasks/${task.id}');
  }
}

class _StudentTaskDetailSheet extends StatefulWidget {
  const _StudentTaskDetailSheet({required this.task});
  final TaskModel task;

  @override
  State<_StudentTaskDetailSheet> createState() => _StudentTaskDetailSheetState();
}

class _StudentTaskDetailSheetState extends State<_StudentTaskDetailSheet> {
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLeafColor = 'Xanh đậm';
  String _selectedHealth = 'Khỏe mạnh';
  final List<String> _photoUrls = [];
  bool _showReportForm = false;

  @override
  void initState() {
    super.initState();
    _showReportForm = widget.task.taskType == TaskType.observation || widget.task.taskType == TaskType.inspection;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _leafCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    // Use API data directly
    final expCode = widget.task.experimentCode ?? '—';
    final stageName = widget.task.experimentStageName ?? '—';
    final batchLabel = widget.task.batchCode ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Chi tiết công việc', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.lg),

                // Experiment + Stage info
                SNMSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.task.taskName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(label: expCode, color: AppColors.primary, tt: tt),
                          _InfoChip(label: stageName, color: AppColors.info, tt: tt),
                          if (batchLabel != '—') _InfoChip(label: batchLabel, color: AppColors.warning, tt: tt),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _InfoRow(icon: Icons.calendar_today_rounded, label: 'Hạn', value: formatDate(widget.task.dueDate), tt: tt, cs: cs),
                          const SizedBox(width: AppSpacing.xl),
                          _InfoRow(icon: _getTaskIcon(widget.task.taskType), label: 'Loại', value: widget.task.taskTypeLabel, tt: tt, cs: cs),
                        ],
                      ),
                      if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(widget.task.description!, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _StudentGuidanceCard(taskType: widget.task.taskType, tt: tt, cs: cs),
                const SizedBox(height: AppSpacing.xl),

                if (_showReportForm) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Báo cáo quan sát', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => setState(() => _showReportForm = !_showReportForm),
                        icon: Icon(_showReportForm ? Icons.visibility_off_rounded : Icons.edit_note_rounded, size: 18),
                        label: Text(_showReportForm ? 'Ẩn form' : 'Mở form'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SNMSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Chiều cao (cm)', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: _heightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: 'VD: 25.5',
                                      suffixText: 'cm',
                                      filled: true,
                                      fillColor: cs.surfaceContainerHighest.withAlpha(128),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Số lá', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: _leafCountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'VD: 8',
                                      suffixText: 'lá',
                                      filled: true,
                                      fillColor: cs.surfaceContainerHighest.withAlpha(128),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Màu lá', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: _selectedLeafColor,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withAlpha(128),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Xanh đậm', child: Text('Xanh đậm')),
                            DropdownMenuItem(value: 'Xanh nhạt', child: Text('Xanh nhạt')),
                            DropdownMenuItem(value: 'Vàng nhẹ', child: Text('Vàng nhẹ')),
                            DropdownMenuItem(value: 'Vàng đậm', child: Text('Vàng đậm')),
                          ],
                          onChanged: (v) => setState(() => _selectedLeafColor = v ?? _selectedLeafColor),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Tình trạng cây', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: _selectedHealth,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withAlpha(128),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Khỏe mạnh', child: Text('Khỏe mạnh')),
                            DropdownMenuItem(value: 'Bình thường', child: Text('Bình thường')),
                            DropdownMenuItem(value: 'Có vấn đề', child: Text('Có vấn đề')),
                          ],
                          onChanged: (v) => setState(() => _selectedHealth = v ?? _selectedHealth),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Ghi chú quan sát', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'VD: Cây phát triển tốt, một số lá có dấu hiệu vàng nhẹ...',
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withAlpha(128),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _PhotoSection(
                          tt: tt, cs: cs,
                          photoUrls: _photoUrls,
                          onRemove: (url) => setState(() => _photoUrls.remove(url)),
                          onAdd: () => setState(() => _photoUrls.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Gửi báo cáo', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  _PhotoSection(
                    tt: tt, cs: cs,
                    photoUrls: _photoUrls,
                    onRemove: (url) => setState(() => _photoUrls.remove(url)),
                    onAdd: () => setState(() => _photoUrls.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showReportForm = true),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Báo cáo quan sát'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xác nhận hoàn thành!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 18, color: Colors.white),
                              SizedBox(width: AppSpacing.sm),
                              Text('Xác nhận xong'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Báo cáo quan sát đã được gửi!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  IconData _getTaskIcon(TaskType type) {
    return switch (type) {
      TaskType.planting    => Icons.eco_rounded,
      TaskType.watering   => Icons.water_drop_rounded,
      TaskType.fertilizing => Icons.science_rounded,
      TaskType.observation => Icons.visibility_rounded,
      TaskType.inspection  => Icons.search_rounded,
      TaskType.other       => Icons.more_horiz_rounded,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color, required this.tt});
  final String label;
  final Color color;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Text(label, style: tt.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.tt, required this.cs});
  final IconData icon;
  final String label;
  final String value;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withAlpha(128)),
        const SizedBox(width: 4),
        Text('$label: ', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
        Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.tt, required this.cs, required this.photoUrls, required this.onRemove, required this.onAdd});
  final TextTheme tt;
  final ColorScheme cs;
  final List<String> photoUrls;
  final void Function(String) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_rounded, size: 16, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Hình ảnh minh chứng', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: AppSpacing.xs),
            Text('(tùy chọn)', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(102))),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...photoUrls.map((url) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        width: 90, height: 90,
                        color: cs.outline.withAlpha(20),
                        child: Icon(Icons.image_rounded, size: 32, color: cs.outline.withAlpha(77)),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(url),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black.withAlpha(153), shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(51)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 28, color: AppColors.primary.withAlpha(179)),
                      const SizedBox(height: 4),
                      Text('Thêm ảnh', style: tt.labelSmall?.copyWith(color: AppColors.primary.withAlpha(179))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (photoUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('${photoUrls.length} hình ảnh được chọn', style: tt.bodySmall?.copyWith(color: AppColors.primary)),
        ],
      ],
    );
  }
}

class _StudentGuidanceCard extends StatelessWidget {
  const _StudentGuidanceCard({required this.taskType, required this.tt, required this.cs});
  final TaskType taskType;
  final TextTheme tt;
  final ColorScheme cs;

  String get _guidanceText {
    return switch (taskType) {
      TaskType.watering =>
        '1. Kiểm tra độ ẩm đất bằng ngón tay (độ sâu 2cm).\n'
        '2. Tưới đều tại gốc cây, tránh làm ướt lá.\n'
        '3. Sử dụng bình tưới nhỏ để kiểm soát lượng nước.\n'
        '4. Ghi nhận kết quả vào phần Báo cáo.',
      TaskType.fertilizing =>
        '1. Pha loãng phân theo hướng dẫn trên bao bì.\n'
        '2. Bổ sung sau khi tưới nước 30 phút.\n'
        '3. Tránh để phân chạm trực tiếp vào thân cây.\n'
        '4. Theo dõi phản ứng của cây trong 24h.',
      TaskType.observation =>
        '1. Quan sát sự phát triển của cây: chiều cao, số lá, màu sắc.\n'
        '2. Ghi nhận các dấu hiệu bất thường (nếu có).\n'
        '3. Chụp ảnh minh chứng nếu phát hiện bất thường.\n'
        '4. Ghi nhận kết quả vào phần Báo cáo.',
      TaskType.inspection =>
        '1. Kiểm tra tổng thể: lá, thân, rễ.\n'
        '2. Ghi nhận tất cả các vấn đề phát hiện.\n'
        '3. Báo cáo ngay cho giáo viên hướng dẫn.\n'
        '4. Không tự ý xử lý nếu chưa được chỉ đạo.',
      TaskType.planting =>
        '1. Chuẩn bị đất: xới phóng, phân hữu cơ theo tỷ lệ.\n'
        '2. Tạo lỗ chấm nước 2-3cm sau cây.\n'
        '3. Tưới nước nhẹ ngay sau trồng.\n'
        '4. Theo dõi 3-5 ngày đầu sau trồng.',
      TaskType.other =>
        '1. Thực hiện theo hướng dẫn của giáo viên.\n'
        '2. Ghi nhận tiến độ và kết quả.\n'
        '3. Báo cáo khi hoàn thành.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện', style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._guidanceText.split('\n').map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(179), height: 1.5)),
          )),
        ],
      ),
    );
  }
}
