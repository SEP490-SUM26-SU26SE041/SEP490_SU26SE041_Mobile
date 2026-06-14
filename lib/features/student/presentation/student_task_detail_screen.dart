import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/utils/experiment_helper.dart';
import '../../../shared/widgets/snms_card.dart';

class StudentTaskDetailScreen extends ConsumerStatefulWidget {
  const StudentTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<StudentTaskDetailScreen> createState() => _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState extends ConsumerState<StudentTaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLeafColor = 'Xanh đậm';
  String _selectedHealth = 'Khỏe mạnh';
  String _selectedPest = 'Không phát hiện';
  final List<String> _photos = [];
  bool _showReportForm = false;
  TaskModel? _task;

  final List<String> _leafColors = ['Xanh đậm', 'Xanh', 'Vàng nhạt', 'Xanh bóng', 'Khác'];
  final List<String> _healthStatuses = ['Khỏe mạnh', 'Bình thường', 'Yếu', 'Rất tốt'];
  final List<String> _pestOptions = ['Không phát hiện', 'Có dấu hiệu sâu ăn lá', 'Có dấu hiệu rệp', 'Khác'];

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  void _loadTask() {
    final tasks = [
      TaskModel(
        id: 'task-s001',
        taskName: 'Quan sát tăng trưởng Nhóm Đối Chứng - Tuần 4',
        taskType: TaskType.observation,
        experimentId: 'exp-001',
        stageId: 'stage-003',
        batchId: 'batch-ctrl-01',
        status: TaskStatus.inProgress,
        assignedTo: 'usr-student-001',
        dueDate: DateTime.now(),
        description: 'Theo dõi sự phát triển của cây trong nhóm đối chứng trong giai đoạn tăng trưởng.',
      ),
      TaskModel(
        id: 'task-s002',
        taskName: 'Ghi nhận chiều cao cây - Ngày 09/06',
        taskType: TaskType.observation,
        experimentId: 'exp-001',
        stageId: 'stage-003',
        batchId: 'batch-ctrl-01',
        status: TaskStatus.pending,
        assignedTo: 'usr-student-001',
        dueDate: DateTime.now(),
      ),
      TaskModel(
        id: 'task-s003',
        taskName: 'Kiểm tra tình trạng lá - Nhóm Thực Nghiệm',
        taskType: TaskType.inspection,
        experimentId: 'exp-001',
        stageId: 'stage-003',
        batchId: 'batch-trt-01',
        status: TaskStatus.completed,
        assignedTo: 'usr-student-001',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    try {
      _task = tasks.firstWhere((t) => t.id == widget.taskId);
    } catch (_) {
      _task = tasks.first;
    }
    _showReportForm = _task?.taskType == TaskType.observation || _task?.taskType == TaskType.inspection;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _leafCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _statusColor => switch (_task?.status) {
    TaskStatus.pending    => AppColors.warning,
    TaskStatus.inProgress => AppColors.primary,
    TaskStatus.completed  => AppColors.success,
    TaskStatus.overdue    => AppColors.error,
    _                    => AppColors.warning,
  };

  Color get _typeColor => switch (_task?.taskType) {
    TaskType.observation => AppColors.accent,
    TaskType.inspection => AppColors.warning,
    TaskType.planting   => AppColors.success,
    TaskType.watering   => AppColors.info,
    TaskType.fertilizing => AppColors.primary,
    _                   => AppColors.accent,
  };

  IconData get _typeIcon => switch (_task?.taskType) {
    TaskType.observation => Icons.visibility_rounded,
    TaskType.inspection  => Icons.search_rounded,
    TaskType.planting   => Icons.eco_rounded,
    TaskType.watering   => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.science_rounded,
    _                   => Icons.help_outline_rounded,
  };

  String get _statusLabel => switch (_task?.status) {
    TaskStatus.pending    => 'Đang chờ',
    TaskStatus.inProgress => 'Đang làm',
    TaskStatus.completed  => 'Hoàn thành',
    TaskStatus.overdue    => 'Quá hạn',
    _                    => '—',
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
              _buildExperimentInfo(tt, cs, expCode, stageName, stage, batchLabel, expTitle),
              const SizedBox(height: AppSpacing.lg),
              _buildGuidanceCard(tt, cs),
              const SizedBox(height: AppSpacing.lg),
              if (_showReportForm) ...[
                _buildObservationReportSection(tt, cs),
                const SizedBox(height: AppSpacing.lg),
                _buildPhotoSection(tt, cs),
                const SizedBox(height: AppSpacing.xl),
                _buildSubmitButton(tt),
              ] else ...[
                _buildPhotoSection(tt, cs),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showReportForm = true),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Báo cáo quan sát'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xác nhận hoàn thành!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        label: const Text('Xác nhận xong'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildExperimentInfo(TextTheme tt, ColorScheme cs, String expCode, String stageName, dynamic stage, String batchLabel, String expTitle) {
    final stageStatus = stage?.status;
    final stageStatusColor = _stageStatusColor(stageStatus);
    final stageStatusLabel = ExperimentHelper.getStageStatusLabel(stageStatus);

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              Text('Thông tin thí nghiệm', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
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
          Flexible(
            child: Text(value, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(TextTheme tt, ColorScheme cs) {
    final guidanceText = switch (_task?.taskType) {
      TaskType.observation =>
        '1. Quan sát sự phát triển: chiều cao, số lá, màu sắc.\n'
        '2. Ghi nhận các dấu hiệu bất thường (nếu có).\n'
        '3. Chụp ảnh minh chứng nếu phát hiện bất thường.\n'
        '4. Ghi nhận kết quả vào phần Báo cáo.',
      TaskType.inspection =>
        '1. Kiểm tra tổng thể: lá, thân, rễ.\n'
        '2. Ghi nhận tất cả các vấn đề phát hiện.\n'
        '3. Báo cáo ngay cho giáo viên hướng dẫn.\n'
        '4. Không tự ý xử lý nếu chưa được chỉ đạo.',
      _ => '1. Đọc kỹ mô tả công việc.\n2. Thực hiện đúng quy trình.\n3. Ghi nhận kết quả.\n4. Báo cáo nếu gặp vấn đề.',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text('Hướng dẫn thực hiện', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
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

  Widget _buildObservationReportSection(TextTheme tt, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: cs.onSurface.withAlpha(153)),
                const SizedBox(width: AppSpacing.sm),
                Text('Báo cáo quan sát', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showReportForm = !_showReportForm),
              icon: Icon(_showReportForm ? Icons.visibility_off_rounded : Icons.edit_note_rounded, size: 16),
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
                        TextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: 'VD: 25.5', suffixText: 'cm'),
                          validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
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
                        TextFormField(
                          controller: _leafCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'VD: 8', suffixText: 'lá'),
                          validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
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
                decoration: const InputDecoration(),
                items: _leafColors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedLeafColor = v ?? _selectedLeafColor),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tình trạng cây', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedHealth,
                decoration: const InputDecoration(),
                items: _healthStatuses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (v) => setState(() => _selectedHealth = v ?? _selectedHealth),
              ),
              if (_task?.taskType == TaskType.inspection) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Dấu hiệu sâu bệnh', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedPest,
                  decoration: const InputDecoration(),
                  items: _pestOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _selectedPest = v ?? _selectedPest),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('Ghi chú quan sát', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'VD: Cây phát triển tốt, một số lá có dấu hiệu vàng nhẹ...',
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
            Text('(tùy chọn)', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(102))),
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
                    color: AppColors.accent.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withAlpha(40)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 24, color: AppColors.accent.withAlpha(179)),
                      const SizedBox(height: 2),
                      Text('Thêm ảnh', style: tt.labelSmall?.copyWith(color: AppColors.accent.withAlpha(179), fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('${_photos.length} hình ảnh được chọn', style: tt.bodySmall?.copyWith(color: AppColors.success)),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(TextTheme tt) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
        label: Text('Gửi báo cáo', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _stageStatusColor(dynamic status) {
    if (status == null) return AppColors.textSecondaryLight;
    return switch (status.toString()) {
      'StageStatus.active'   => AppColors.primary,
      'StageStatus.completed' => AppColors.success,
      'StageStatus.upcoming'  => AppColors.warning,
      _                      => AppColors.textSecondaryLight,
    };
  }

  void _submitReport() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Báo cáo quan sát đã được gửi!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }
}
