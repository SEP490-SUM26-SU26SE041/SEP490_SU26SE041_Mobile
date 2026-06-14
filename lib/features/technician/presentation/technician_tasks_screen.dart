import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/utils/experiment_helper.dart';

final List<TaskModel> _mockTechnicianTasks = [
  TaskModel(
    id: 'task-t001',
    taskName: 'Tưới nước - Nhóm Đối Chứng',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.pending,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now(),
    description: 'Tưới nhỏ giọt 200ml/gốc cây cho nhóm đối chứng trong giai đoạn tăng trưởng.',
  ),
  TaskModel(
    id: 'task-t002',
    taskName: 'Bón phân NPK - Nhóm Thực Nghiệm',
    taskType: TaskType.fertilizing,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-trt-01',
    status: TaskStatus.inProgress,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now(),
    description: 'Bón phân NPK 20-20-20, 5g/cây cho nhóm thực nghiệm.',
  ),
  TaskModel(
    id: 'task-t003',
    taskName: 'Kiểm tra độ ẩm đất',
    taskType: TaskType.inspection,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.pending,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now(),
  ),
  TaskModel(
    id: 'task-t004',
    taskName: 'Tưới nước - Khu thủy canh',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-002',
    batchId: 'batch-trt-01',
    status: TaskStatus.completed,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TaskModel(
    id: 'task-t005',
    taskName: 'Điều chỉnh độ ẩm đất',
    taskType: TaskType.inspection,
    experimentId: 'exp-001',
    stageId: 'stage-002',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.completed,
    assignedTo: 'usr-technician-001',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

class TechnicianTasksScreen extends StatefulWidget {
  const TechnicianTasksScreen({super.key});

  @override
  State<TechnicianTasksScreen> createState() => _TechnicianTasksScreenState();
}

class _TechnicianTasksScreenState extends State<TechnicianTasksScreen>
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

  List<TaskModel> _filterTasks(List<TaskModel> all, String status) {
    return all.where((t) => t.statusLabel == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Công việc của tôi', style: tt.titleLarge),
        backgroundColor: cs.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang chờ'),
            Tab(text: 'Đang làm'),
            Tab(text: 'Hoàn thành'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: cs.onSurface.withAlpha(153),
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_filterTasks(_mockTechnicianTasks, 'Pending')),
          _buildTaskList(_filterTasks(_mockTechnicianTasks, 'In Progress')),
          _buildTaskList(_filterTasks(_mockTechnicianTasks, 'Completed')),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text('Không có công việc', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _TechnicianTaskCard(
            task: task,
            onTap: () => _showTaskDetail(context, task),
          ),
        );
      },
    );
  }

  void _showTaskDetail(BuildContext context, TaskModel task) {
    context.push('/tech/tasks/${task.id}');
  }
}

class _TechnicianTaskCard extends StatelessWidget {
  const _TechnicianTaskCard({required this.task, required this.onTap});

  final TaskModel task;
  final VoidCallback onTap;

  Color get _statusColor {
    return switch (task.status) {
      TaskStatus.pending    => AppColors.warning,
      TaskStatus.inProgress => AppColors.info,
      TaskStatus.completed  => AppColors.success,
      TaskStatus.overdue    => AppColors.error,
    };
  }

  Color get _typeColor {
    return switch (task.taskType) {
      TaskType.watering   => AppColors.info,
      TaskType.fertilizing => AppColors.primary,
      TaskType.inspection  => AppColors.warning,
      _ => AppColors.accent,
    };
  }

  IconData get _icon {
    return switch (task.taskType) {
      TaskType.watering   => Icons.water_drop_rounded,
      TaskType.fertilizing => Icons.grass_rounded,
      TaskType.inspection  => Icons.search_rounded,
      _ => Icons.agriculture_rounded,
    };
  }

  String get _statusLabel {
    return switch (task.status) {
      TaskStatus.pending    => 'Đang chờ',
      TaskStatus.inProgress => 'Đang làm',
      TaskStatus.completed  => 'Hoàn thành',
      TaskStatus.overdue    => 'Quá hạn',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final expCode = ExperimentHelper.getExperimentCode(task.experimentId);
    final stageName = ExperimentHelper.getStageName(task.experimentId, task.stageId);
    final stageStatus = ExperimentHelper.getStageStatus(task.experimentId, task.stageId);
    final batchLabel = ExperimentHelper.getBatchLabel(task.batchId);

    return SNMSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _typeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _typeColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(expCode, style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 10)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text('${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
              const SizedBox(width: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _stageStatusColor(stageStatus).withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ExperimentHelper.getStageStatusLabel(stageStatus),
                  style: tt.labelSmall?.copyWith(color: _stageStatusColor(stageStatus), fontWeight: FontWeight.w500, fontSize: 10),
                ),
              ),
              if (batchLabel != '—') ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.batch_prediction_rounded, size: 12, color: cs.onSurface.withAlpha(102)),
                const SizedBox(width: 2),
                Text(batchLabel, style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128), fontSize: 10)),
              ],
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withAlpha(102)),
            ],
          ),
        ],
      ),
    );
  }

  Color _stageStatusColor(StageStatus? status) {
    if (status == null) return AppColors.textSecondaryLight;
    return switch (status) {
      StageStatus.active    => AppColors.primary,
      StageStatus.completed => AppColors.success,
      StageStatus.upcoming  => AppColors.warning,
    };
  }
}

class _CareActivitySheet extends StatefulWidget {
  const _CareActivitySheet({required this.task});
  final TaskModel task;

  @override
  State<_CareActivitySheet> createState() => _CareActivitySheetState();
}

class _CareActivitySheetState extends State<_CareActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _waterController = TextEditingController();
  final _fertilizerController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _photos = [];
  DateTime _performedAt = DateTime.now();

  @override
  void dispose() {
    _waterController.dispose();
    _fertilizerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final expCode = ExperimentHelper.getExperimentCode(widget.task.experimentId);
    final stageName = ExperimentHelper.getStageName(widget.task.experimentId, widget.task.stageId);
    final batchLabel = ExperimentHelper.getBatchLabel(widget.task.batchId);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: AppSpacing.lg),
                  Text('Chi tiết công việc', style: tt.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),

                  // Experiment + Stage info
                  SNMSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.task.taskName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        if (widget.task.description != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(widget.task.description!, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _buildChip(expCode, AppColors.primary, tt),
                            _buildChip(stageName, AppColors.info, tt),
                            if (batchLabel != '—') _buildChip(batchLabel, AppColors.warning, tt),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _InfoRow(icon: Icons.calendar_today_rounded, label: 'Hạn', value: '${widget.task.dueDate.day}/${widget.task.dueDate.month}/${widget.task.dueDate.year}', tt: tt, cs: cs),
                            const SizedBox(width: AppSpacing.xl),
                            _InfoRow(icon: _getTypeIcon(widget.task.taskType), label: 'Loại', value: widget.task.taskTypeLabel, tt: tt, cs: cs),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _TaskGuidanceSection(tt: tt, cs: cs, taskType: widget.task.taskTypeLabel),
                  const SizedBox(height: AppSpacing.xl),

                  Text('Ghi nhận Care Activity', style: tt.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _waterController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Lượng nước (ml)',
                      prefixIcon: const Icon(Icons.water_drop_rounded),
                      suffixText: 'ml',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _fertilizerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Lượng phân bón (g)',
                      prefixIcon: const Icon(Icons.grass_rounded),
                      suffixText: 'g',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      prefixIcon: Icon(Icons.note_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Time picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                    ),
                    title: const Text('Thời gian thực hiện'),
                    subtitle: Text(_formatDateTime(_performedAt)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _performedAt,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_performedAt),
                        );
                        if (time != null) {
                          setState(() {
                            _performedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Photo section
                  _TechPhotoSection(
                    tt: tt, cs: cs,
                    photos: _photos,
                    onAdd: () => setState(() => _photos.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
                    onRemove: (p) => setState(() => _photos.remove(p)),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Hoàn thành công việc', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color color, TextTheme tt) {
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

  IconData _getTypeIcon(TaskType type) {
    return switch (type) {
      TaskType.watering   => Icons.water_drop_rounded,
      TaskType.fertilizing => Icons.grass_rounded,
      TaskType.inspection  => Icons.search_rounded,
      _ => Icons.agriculture_rounded,
    };
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi báo cáo thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} lúc ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

class _TaskGuidanceSection extends StatelessWidget {
  const _TaskGuidanceSection({required this.tt, required this.cs, required this.taskType});
  final TextTheme tt;
  final ColorScheme cs;
  final String taskType;

  String get _guidanceText {
    final lower = taskType.toLowerCase();
    return switch (lower) {
      'watering' => '1. Kiểm tra độ ẩm đất trước khi tưới.\n2. Tưới đều tại gốc cây, tránh làm ướt lá.\n3. Lượng nước khuyến nghị: 200-500ml/gốc cây.\n4. Ghi nhận lại lượng nước đã sử dụng.',
      'fertilizing' => '1. Pha loãng phân theo tỷ lệ khuyến nghị.\n2. Bổ sung sau khi tưới nước.\n3. Tránh bón phân trực tiếp vào thân cây.\n4. Theo dõi phản ứng của cây sau 24h.',
      'inspection' => '1. Kiểm tra tình trạng tổng quát của cây.\n2. Ghi nhận tất cả các dấu hiệu bất thường.\n3. Chụp ảnh minh chứng (nếu có).\n4. Báo cáo ngay cho người phụ trách.',
      _ => '1. Đọc kỹ mô tả công việc.\n2. Thực hiện đúng quy trình.\n3. Ghi nhận kết quả và chủ động.\n4. Báo cáo nếu gặp vấn đề.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withAlpha(30)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện', style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.info,
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

class _TechPhotoSection extends StatelessWidget {
  const _TechPhotoSection({required this.tt, required this.cs, required this.photos, required this.onAdd, required this.onRemove});
  final TextTheme tt;
  final ColorScheme cs;
  final List<String> photos;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_rounded, size: 16, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Hình ảnh minh chứng', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Khuyến nghi', style: tt.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ...photos.map((p) => Stack(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: cs.outline.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.image_rounded, size: 28, color: cs.outline.withAlpha(77)),
                ),
                Positioned(
                  top: 2, right: 2,
                  child: GestureDetector(
                    onTap: () => onRemove(p),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withAlpha(153), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_rounded, size: 22, color: AppColors.primary.withAlpha(179)),
                    const SizedBox(height: 2),
                    Text('Chụp thêm', style: tt.labelSmall?.copyWith(color: AppColors.primary.withAlpha(179), fontSize: 9)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('${photos.length} hình ảnh đính kèm', style: tt.bodySmall?.copyWith(color: AppColors.success)),
        ],
      ],
    );
  }
}
