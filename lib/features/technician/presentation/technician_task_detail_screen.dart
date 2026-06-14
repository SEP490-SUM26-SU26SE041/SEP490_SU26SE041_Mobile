import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/utils/experiment_helper.dart';
import '../../../shared/widgets/snms_card.dart';

class TechnicianTaskDetailScreen extends ConsumerStatefulWidget {
  const TechnicianTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TechnicianTaskDetailScreen> createState() => _TechnicianTaskDetailScreenState();
}

class _TechnicianTaskDetailScreenState extends ConsumerState<TechnicianTaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _waterController = TextEditingController();
  final _fertilizerController = TextEditingController();
  final _soilMoistureController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _photos = [];

  TaskModel? _task;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  void _loadTask() {
    final tasks = [
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
        description: 'Kiểm tra độ ẩm đất tại các luống trong nhóm đối chứng.',
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
    try {
      _task = tasks.firstWhere((t) => t.id == widget.taskId);
    } catch (_) {
      _task = tasks.first;
    }
  }

  @override
  void dispose() {
    _waterController.dispose();
    _fertilizerController.dispose();
    _soilMoistureController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _statusColor => switch (_task?.status) {
    TaskStatus.pending    => AppColors.warning,
    TaskStatus.inProgress => AppColors.info,
    TaskStatus.completed  => AppColors.success,
    TaskStatus.overdue    => AppColors.error,
    _                     => AppColors.warning,
  };

  Color get _typeColor => switch (_task?.taskType) {
    TaskType.watering   => AppColors.info,
    TaskType.fertilizing => AppColors.primary,
    TaskType.inspection  => AppColors.warning,
    _                    => AppColors.accent,
  };

  IconData get _typeIcon => switch (_task?.taskType) {
    TaskType.watering   => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.grass_rounded,
    TaskType.inspection  => Icons.search_rounded,
    _                    => Icons.agriculture_rounded,
  };

  String get _statusLabel => switch (_task?.status) {
    TaskStatus.pending    => 'Đang chờ',
    TaskStatus.inProgress => 'Đang làm',
    TaskStatus.completed  => 'Hoàn thành',
    TaskStatus.overdue    => 'Quá hạn',
    _                     => '—',
  };

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy công việc')),
        body: const Center(child: Text('Công việc không tồn tại')),
      );
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final expCode = ExperimentHelper.getExperimentCode(_task!.experimentId);
    final stageName = ExperimentHelper.getStageName(_task!.experimentId, _task!.stageId);
    final stage = ExperimentHelper.getStage(_task!.experimentId, _task!.stageId);
    final batchLabel = ExperimentHelper.getBatchLabel(_task!.batchId);
    final expTitle = ExperimentHelper.getExperimentTitle(_task!.experimentId);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskHeader(tt, cs, expCode, stageName, batchLabel),
              const SizedBox(height: AppSpacing.lg),
              _buildStageInfoCard(tt, cs, expCode, stageName, stage, batchLabel, expTitle),
              const SizedBox(height: AppSpacing.lg),
              _buildGuidanceCard(tt, cs),
              const SizedBox(height: AppSpacing.lg),
              _buildCareActivitySection(tt, cs),
              const SizedBox(height: AppSpacing.lg),
              _buildPhotoSection(tt, cs),
              const SizedBox(height: AppSpacing.xl),
              _buildSubmitButton(tt),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHeader(TextTheme tt, ColorScheme cs, String expCode, String stageName, String batchLabel) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _typeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _task!.taskName,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_statusLabel, style: tt.labelSmall?.copyWith(color: _statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_task!.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_task!.description!, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153), height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildStageInfoCard(TextTheme tt, ColorScheme cs, String expCode, String stageName, dynamic stage, String batchLabel, String expTitle) {
    final stageStatus = stage?.status;
    final stageStatusColor = _stageStatusColor(stageStatus);
    final stageStatusLabel = ExperimentHelper.getStageStatusLabel(stageStatus);

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Thông tin thí nghiệm', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(Icons.code_rounded, 'Mã thí nghiệm', expCode, tt, cs),
          _buildInfoRow(Icons.title_rounded, 'Tên thí nghiệm', expTitle, tt, cs),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.timelapse_rounded, size: 16, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.sm),
              Text('Giai đoạn', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: stageStatusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(stageName, style: tt.labelSmall?.copyWith(color: stageStatusColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stageStatusColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(stageStatusLabel, style: tt.labelSmall?.copyWith(color: stageStatusColor, fontWeight: FontWeight.w500, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.batch_prediction_rounded, size: 16, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.sm),
              Text('Lô cây', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(batchLabel, style: tt.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.sm),
              Text('Hạn hoàn thành', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
              const Spacer(),
              Text(
                '${_task!.dueDate.day}/${_task!.dueDate.month}/${_task!.dueDate.year}',
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withAlpha(128)),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
          const Spacer(),
          Text(value, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(TextTheme tt, ColorScheme cs) {
    final guidanceText = switch (_task?.taskType) {
      TaskType.watering =>
        '1. Kiểm tra độ ẩm đất trước khi tưới (ngón tay, độ sâu 2cm).\n'
        '2. Tưới đều tại gốc cây, tránh làm ướt lá.\n'
        '3. Lượng nước khuyến nghị: 200-500ml/gốc cây.\n'
        '4. Ghi nhận lại lượng nước đã sử dụng.',
      TaskType.fertilizing =>
        '1. Pha loãng phân theo tỷ lệ khuyến nghị.\n'
        '2. Bổ sung sau khi tưới nước 30 phút.\n'
        '3. Tránh bón phân trực tiếp vào thân cây.\n'
        '4. Theo dõi phản ứng của cây sau 24h.',
      TaskType.inspection =>
        '1. Kiểm tra tình trạng tổng quát của cây và đất.\n'
        '2. Ghi nhận tất cả các dấu hiệu bất thường.\n'
        '3. Chụp ảnh minh chứng (nếu có).\n'
        '4. Báo cáo ngay cho người phụ trách.',
      _ => '1. Đọc kỹ mô tả công việc.\n2. Thực hiện đúng quy trình.\n3. Ghi nhận kết quả.\n4. Báo cáo nếu gặp vấn đề.',
    };

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
              Text('Hướng dẫn thực hiện', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...guidanceText.split('\n').map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(179), height: 1.5)),
          )),
        ],
      ),
    );
  }

  Widget _buildCareActivitySection(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Ghi nhận chăm sóc', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SNMSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_task?.taskType == TaskType.watering || _task?.taskType == TaskType.fertilizing) ...[
                Text('Lượng nước đã tưới', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _waterController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'VD: 200',
                    suffixText: 'ml',
                    prefixIcon: const Icon(Icons.water_drop_rounded, size: 20),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập lượng nước' : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_task?.taskType == TaskType.fertilizing) ...[
                Text('Lượng phân bón đã sử dụng', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _fertilizerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'VD: 5',
                    suffixText: 'g',
                    prefixIcon: const Icon(Icons.grass_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_task?.taskType == TaskType.inspection) ...[
                Text('Độ ẩm đất đo được', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _soilMoistureController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'VD: 45',
                    suffixText: '%',
                    prefixIcon: const Icon(Icons.water_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Ghi chú', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mô tả chi tiết công việc đã thực hiện...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_rounded, size: 18, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Hình ảnh minh chứng', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Khuyến nghị', style: tt.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SNMSCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ..._photos.map((p) => Stack(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: cs.outline.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.image_rounded, size: 32, color: cs.outline.withAlpha(77)),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _photos.remove(p)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withAlpha(153), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )),
              GestureDetector(
                onTap: () => setState(() => _photos.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 24, color: AppColors.primary.withAlpha(179)),
                      const SizedBox(height: 2),
                      Text('Thêm ảnh', style: tt.labelSmall?.copyWith(color: AppColors.primary.withAlpha(179), fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('${_photos.length} hình ảnh đính kèm', style: tt.bodySmall?.copyWith(color: AppColors.success)),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(TextTheme tt) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
        label: Text('Hoàn thành công việc', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _stageStatusColor(dynamic status) {
    if (status == null) return AppColors.textSecondaryLight;
    return switch (status.toString()) {
      'StageStatus.active'   => AppColors.primary,
      'StageStatus.completed' => AppColors.success,
      'StageStatus.upcoming'  => AppColors.warning,
      _                       => AppColors.textSecondaryLight,
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
      context.pop();
    }
  }
}
