import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
class TechnicianReportScreen extends StatefulWidget {
  const TechnicianReportScreen({super.key});

  @override
  State<TechnicianReportScreen> createState() => _TechnicianReportScreenState();
}

class _TechnicianReportScreenState extends State<TechnicianReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workDoneController = TextEditingController();
  final _issuesFoundController = TextEditingController();
  final _sensorReadingsController = TextEditingController();

  String? _selectedTaskId;
  String _selectedSeverity = 'Low';
  bool _showReportHistory = false;

  final List<_TaskReport> _reportHistory = _mockReportHistory;

  @override
  void dispose() {
    _workDoneController.dispose();
    _issuesFoundController.dispose();
    _sensorReadingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Báo cáo', style: tt.titleLarge),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showReportHistory = !_showReportHistory),
            icon: Icon(
              _showReportHistory ? Icons.add_rounded : Icons.history_rounded,
              size: 20,
            ),
            label: Text(_showReportHistory ? 'Viết báo cáo' : 'Lịch sử'),
          ),
        ],
      ),
      body: _showReportHistory ? _buildReportHistory() : _buildReportForm(context),
    );
  }

  Widget _buildReportForm(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SNMSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Báo cáo gửi Researcher',
                          style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ghi nhận công việc đã thực hiện và các vấn đề phát hiện được.',
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Chọn công việc liên quan', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _selectedTaskId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.task_alt_rounded),
                hintText: 'Chọn công việc',
              ),
              items: _mockTasks.map((task) {
                return DropdownMenuItem(
                  value: task.id,
                  child: Text(task.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTaskId = value),
              validator: (value) =>
                  value == null ? 'Vui lòng chọn công việc' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Tóm tắt công việc đã làm', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _workDoneController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả chi tiết công việc đã thực hiện...',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập mô tả công việc' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Vấn đề phát hiện', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _issuesFoundController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ghi nhận các vấn đề (nếu có)...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Chỉ số cảm biến (thủ công)', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _sensorReadingsController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'VD: Nhiệt độ: 28.5°C, Độ ẩm: 72%',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mức độ nghiêm trọng', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _SeveritySelector(
              selectedSeverity: _selectedSeverity,
              onChanged: (value) =>
                  setState(() => _selectedSeverity = value ?? 'Low'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Hình ảnh minh họa', style: tt.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _ImageUploadPlaceholder(),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text('Gửi báo cáo cho Researcher'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHistory() {
    if (_reportHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text('Chưa có báo cáo nào',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _reportHistory.length,
      itemBuilder: (context, index) {
        final report = _reportHistory[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ReportHistoryCard(
            report: report,
            onTap: () => _showReportDetail(context, report),
          ),
        );
      },
    );
  }

  void _submitReport() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Báo cáo đã được gửi cho Researcher!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _formKey.currentState?.reset();
      _workDoneController.clear();
      _issuesFoundController.clear();
      _sensorReadingsController.clear();
      setState(() {
        _selectedTaskId = null;
        _selectedSeverity = 'Low';
        _showReportHistory = true;
      });
    }
  }

  void _showReportDetail(BuildContext context, _TaskReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailSheet(report: report),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({
    required this.selectedSeverity,
    required this.onChanged,
  });

  final String selectedSeverity;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final severities = ['Low', 'Medium', 'High', 'Critical'];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: severities.map((severity) {
        final isSelected = selectedSeverity == severity;
        final color = _getSeverityColor(severity);

        return ChoiceChip(
          label: Text(severity),
          selected: isSelected,
          onSelected: (_) => onChanged(severity),
          selectedColor: color.withAlpha(38),
          backgroundColor: Theme.of(context).cardTheme.color,
          side: BorderSide(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
          ),
          labelStyle: TextStyle(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Color _getSeverityColor(String severity) {
    return switch (severity) {
      'Low' => AppColors.info,
      'Medium' => AppColors.warning,
      'High' => const Color(0xFFFF7043),
      'Critical' => AppColors.error,
      _ => AppColors.info,
    };
  }
}

class _ImageUploadPlaceholder extends StatefulWidget {
  @override
  State<_ImageUploadPlaceholder> createState() => _ImageUploadPlaceholderState();
}

class _ImageUploadPlaceholderState extends State<_ImageUploadPlaceholder> {
  final List<String> _photos = [];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withAlpha(77)),
      ),
      child: Column(
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
                child: Text('Khuyến nghị', style: tt.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ..._photos.map((p) => Stack(
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
                      onTap: () => setState(() => _photos.remove(p)),
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
                onTap: () => setState(() => _photos.add('photo_${DateTime.now().millisecondsSinceEpoch}')),
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
                      Text('Thêm', style: tt.labelSmall?.copyWith(color: AppColors.primary.withAlpha(179), fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${_photos.length} hình ảnh đính kèm', style: tt.bodySmall?.copyWith(color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  const _ReportHistoryCard({required this.report, required this.onTap});

  final _TaskReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.taskName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getSeverityColor(report.severity).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.severity,
                  style: tt.labelSmall?.copyWith(
                    color: _getSeverityColor(report.severity),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.workDone,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatDateTime(report.submittedAt),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(128),
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurface.withAlpha(128)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    return switch (severity) {
      'Low' => AppColors.info,
      'Medium' => AppColors.warning,
      'High' => const Color(0xFFFF7043),
      'Critical' => AppColors.error,
      _ => AppColors.info,
    };
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} lúc ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report});

  final _TaskReport report;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Chi tiết báo cáo', style: tt.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            _DetailRow(label: 'Công việc', value: report.taskName),
            _DetailRow(label: 'Mức độ', value: report.severity),
            _DetailRow(
              label: 'Ngày gửi',
              value: _formatDateTime(report.submittedAt),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Công việc đã làm', style: tt.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SNMSCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(report.workDone, style: tt.bodyMedium),
            ),
            if (report.issuesFound.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Vấn đề phát hiện', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SNMSCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(report.issuesFound, style: tt.bodyMedium),
              ),
            ],
            if (report.sensorReadings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Chỉ số cảm biến', style: tt.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SNMSCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(report.sensorReadings, style: tt.bodyMedium),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} lúc ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withAlpha(153),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskReport {
  const _TaskReport({
    required this.id,
    required this.taskName,
    required this.workDone,
    required this.issuesFound,
    required this.sensorReadings,
    required this.severity,
    required this.submittedAt,
  });

  final String id;
  final String taskName;
  final String workDone;
  final String issuesFound;
  final String sensorReadings;
  final String severity;
  final DateTime submittedAt;
}

final _mockReportHistory = [
  _TaskReport(
    id: 'report-001',
    taskName: 'Tưới nước - Khu A01',
    workDone: 'Đã tưới 200ml nước cho từng cây trong khu vực thí nghiệm.',
    issuesFound: 'Một số cây ở hàng 3 có dấu hiệu thiếu nước.',
    sensorReadings: 'Nhiệt độ: 28.5°C, Độ ẩm: 65%',
    severity: 'Low',
    submittedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _TaskReport(
    id: 'report-002',
    taskName: 'Kiểm tra cảm biến',
    workDone: 'Đã kiểm tra và vệ sinh 5 cảm biến trong khu vực.',
    issuesFound: 'Cảm biến TEMP-Z01-B02 không phản hồi, cần thay thế.',
    sensorReadings: 'TEMP-Z01-B02: Không hoạt động',
    severity: 'High',
    submittedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

final _mockTasks = [
  const _MockTask(id: 'task-001', name: 'Tưới nước - Nhóm Đối Chứng'),
  const _MockTask(id: 'task-002', name: 'Bón phân NPK - Khu A01'),
  const _MockTask(id: 'task-003', name: 'Kiểm tra cảm biến nhiệt độ'),
];

class _MockTask {
  const _MockTask({required this.id, required this.name});
  final String id;
  final String name;
}
