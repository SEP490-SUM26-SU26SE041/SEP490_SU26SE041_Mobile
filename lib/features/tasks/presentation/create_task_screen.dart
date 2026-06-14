import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../mock/mock_users.dart';
import '../../../mock/mock_experiments.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key, this.experimentId});

  final String? experimentId;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TaskType _taskType = TaskType.observation;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _showAISuggestion = false;
  AITaskSuggestion? _aiSuggestion;
  bool _isLoadingSuggestion = false;
  AICandidateSuggestion? _selectedCandidate;

  String? _selectedExperimentId;
  String? _selectedStageId;

  @override
  void initState() {
    super.initState();
    _selectedExperimentId = widget.experimentId;
    if (_selectedExperimentId != null) {
      final exp = getExperimentById(_selectedExperimentId!);
      if (exp != null && exp.stages.isNotEmpty) {
        final activeStage = exp.stages.firstWhere(
          (s) => s.status == StageStatus.active,
          orElse: () => exp.stages.first,
        );
        _selectedStageId = activeStage.id;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? get _currentExperimentName {
    if (_selectedExperimentId == null) return null;
    return getExperimentById(_selectedExperimentId!)?.title;
  }

  List<_ExperimentOption> get _availableExperiments {
    return mockExperiments
        .where((e) => e.status == ExperimentStatus.active || e.status == ExperimentStatus.pending)
        .map((e) => _ExperimentOption(
              id: e.id,
              code: e.experimentCode,
              title: e.title,
            ))
        .toList();
  }

  List<_StageOption> get _availableStages {
    if (_selectedExperimentId == null) return [];
    final exp = getExperimentById(_selectedExperimentId!);
    if (exp == null) return [];
    return exp.stages.map((s) => _StageOption(id: s.id, name: s.stageName)).toList();
  }

  Future<void> _getAISuggestion() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên task trước'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoadingSuggestion = true);

    await Future.delayed(const Duration(seconds: 2));

    final candidates = mockUsers
        .where((u) => u.role.name == 'technician' || u.role.name == 'student')
        .map((u) {
      final skillCount = u.skills.length;
      final score = 60.0 + (skillCount * 8.0);
      return AICandidateSuggestion(
        userId: u.id,
        fullName: u.fullName,
        matchScore: score.clamp(0, 100),
        currentTaskCount: u.role.name == 'student' ? 2 : 1,
        reason: '${u.fullName} phù hợp với yêu cầu task "${_nameCtrl.text}"',
      );
    }).toList();

    candidates.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    setState(() {
      _aiSuggestion = AITaskSuggestion(
        suggestedAssigneeId: candidates.first.userId,
        matchScore: candidates.first.matchScore,
        reason: candidates.first.reason,
        reviewStatus: 'suggested',
        alternativeCandidates: candidates,
      );
      _selectedCandidate = candidates.first;
      _showAISuggestion = true;
      _isLoadingSuggestion = false;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedExperimentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thí nghiệm'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${_nameCtrl.text}" đã được tạo thành công!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (widget.experimentId != null) {
      context.pop();
    } else {
      context.go('/tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.compact,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withAlpha(230),
                  border: Border(
                    bottom: BorderSide(
                      color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(77),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New Task',
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                          ),
                          if (_currentExperimentName != null)
                            Text(
                              _currentExperimentName!,
                              style: tt.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _submit,
                      child: Text(
                        'Create',
                        style: tt.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Experiment selector
                      _SectionLabel(label: 'Thí nghiệm', required: true),
                      const SizedBox(height: AppSpacing.sm),
                      _ExperimentSelector(
                        experiments: _availableExperiments,
                        selectedId: _selectedExperimentId,
                        onChanged: (id) {
                          setState(() {
                            _selectedExperimentId = id;
                            _selectedStageId = null;
                            if (id != null) {
                              final exp = getExperimentById(id);
                              if (exp != null && exp.stages.isNotEmpty) {
                                final activeStage = exp.stages.firstWhere(
                                  (s) => s.status == StageStatus.active,
                                  orElse: () => exp.stages.first,
                                );
                                _selectedStageId = activeStage.id;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Stage selector
                      if (_availableStages.isNotEmpty) ...[
                        _SectionLabel(label: 'Giai đoạn'),
                        const SizedBox(height: AppSpacing.sm),
                        _StageSelector(
                          stages: _availableStages,
                          selectedId: _selectedStageId,
                          onChanged: (id) => setState(() => _selectedStageId = id),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Task name
                      _SectionLabel(label: 'Tên Task', required: true),
                      const SizedBox(height: AppSpacing.sm),
                      _PremiumTextField(
                        controller: _nameCtrl,
                        hint: 'e.g. Quan sat tang truong Nhom Doi Chung - Tuan 4',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên task' : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Task type
                      _SectionLabel(label: 'Loại Task'),
                      const SizedBox(height: AppSpacing.sm),
                      _TaskTypeSelector(
                        selected: _taskType,
                        onChanged: (t) => setState(() => _taskType = t),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Description
                      _SectionLabel(label: 'Mô tả'),
                      const SizedBox(height: AppSpacing.sm),
                      _PremiumTextField(
                        controller: _descCtrl,
                        hint: 'Mô tả chi tiết công việc...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Schedule
                      _SectionLabel(label: 'Lịch trình'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _DateCard(
                              label: 'Ngày bắt đầu',
                              date: _startDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) setState(() => _startDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _DateCard(
                              label: 'Ngày hết hạn',
                              date: _dueDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) setState(() => _dueDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // AI Assignment
                      _SectionLabel(label: 'Phân công AI'),
                      const SizedBox(height: AppSpacing.sm),
                      _AIAssignmentCard(
                        isLoading: _isLoadingSuggestion,
                        suggestion: _aiSuggestion,
                        selectedCandidate: _selectedCandidate,
                        showSuggestion: _showAISuggestion,
                        onGetSuggestion: _getAISuggestion,
                        onSelectCandidate: (c) => setState(() => _selectedCandidate = c),
                      ),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperimentOption {
  final String id;
  final String code;
  final String title;
  const _ExperimentOption({required this.id, required this.code, required this.title});
}

class _StageOption {
  final String id;
  final String name;
  const _StageOption({required this.id, required this.name});
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _ExperimentSelector extends StatelessWidget {
  const _ExperimentSelector({
    required this.experiments,
    required this.selectedId,
    required this.onChanged,
  });
  final List<_ExperimentOption> experiments;
  final String? selectedId;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = experiments.where((e) => e.id == selectedId).firstOrNull;

    return GestureDetector(
      onTap: () => _showExperimentPicker(context),
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
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selected != null) ...[
                    Text(
                      selected.code,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      'Chọn thí nghiệm...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withAlpha(102)),
          ],
        ),
      ),
    );
  }

  void _showExperimentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Chọn Thí nghiệm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: experiments.length,
                  itemBuilder: (ctx, i) {
                    final exp = experiments[i];
                    final isSelected = exp.id == selectedId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withAlpha(15)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withAlpha(102)
                              : Theme.of(context).colorScheme.outline.withAlpha(51),
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          onChanged(exp.id);
                          Navigator.pop(ctx);
                        },
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withAlpha(40)
                                : AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppRadius.small),
                          ),
                          child: Icon(
                            Icons.science_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          exp.code,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          exp.title,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageSelector extends StatelessWidget {
  const _StageSelector({
    required this.stages,
    required this.selectedId,
    required this.onChanged,
  });
  final List<_StageOption> stages;
  final String? selectedId;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: stages.map((s) {
        final isSelected = s.id == selectedId;
        return GestureDetector(
          onTap: () => onChanged(s.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outline.withAlpha(77),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              s.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(153),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.hint,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

class _TaskTypeSelector extends StatelessWidget {
  const _TaskTypeSelector({required this.selected, required this.onChanged});
  final TaskType selected;
  final void Function(TaskType) onChanged;

  IconData _icon(TaskType t) => switch (t) {
    TaskType.planting     => Icons.grass_rounded,
    TaskType.watering    => Icons.water_drop_rounded,
    TaskType.fertilizing => Icons.eco_rounded,
    TaskType.observation => Icons.visibility_rounded,
    TaskType.inspection  => Icons.search_rounded,
  };

  String _label(TaskType t) => switch (t) {
    TaskType.planting     => 'Trồng',
    TaskType.watering    => 'Tưới nước',
    TaskType.fertilizing => 'Bón phân',
    TaskType.observation => 'Quan sát',
    TaskType.inspection  => 'Kiểm tra',
  };

  Color _color(TaskType t) => switch (t) {
    TaskType.planting     => AppColors.success,
    TaskType.watering    => AppColors.info,
    TaskType.fertilizing => AppColors.accent,
    TaskType.observation => AppColors.primary,
    TaskType.inspection  => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: TaskType.values.map((t) {
        final isSelected = t == selected;
        final color = _color(t);
        return GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(
                color: isSelected ? color : Theme.of(context).colorScheme.outline.withAlpha(77),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(t), size: 16, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(128)),
                const SizedBox(width: 6),
                Text(
                  _label(t),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(128),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 8), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAssignmentCard extends StatelessWidget {
  const _AIAssignmentCard({
    required this.isLoading,
    required this.suggestion,
    required this.selectedCandidate,
    required this.showSuggestion,
    required this.onGetSuggestion,
    required this.onSelectCandidate,
  });

  final bool isLoading;
  final AITaskSuggestion? suggestion;
  final AICandidateSuggestion? selectedCandidate;
  final bool showSuggestion;
  final VoidCallback onGetSuggestion;
  final void Function(AICandidateSuggestion) onSelectCandidate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.heroRadius,
        border: Border.all(color: AppColors.aiInsight.withAlpha(51)),
        boxShadow: [
          BoxShadow(color: AppColors.aiInsight.withAlpha(isDark ? 10 : 8), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.aiInsight.withAlpha(40), AppColors.aiInsight.withAlpha(20)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.aiInsight, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gợi ý phân công AI', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                    Text('Dựa trên kỹ năng + khối lượng công việc',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                      )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (showSuggestion && suggestion != null)
            _AISuggestionContent(suggestion: suggestion!, selectedCandidate: selectedCandidate, onSelectCandidate: onSelectCandidate)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGetSuggestion,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Nhận gợi ý AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aiInsight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AISuggestionContent extends StatelessWidget {
  const _AISuggestionContent({required this.suggestion, required this.selectedCandidate, required this.onSelectCandidate});
  final AITaskSuggestion suggestion;
  final AICandidateSuggestion? selectedCandidate;
  final void Function(AICandidateSuggestion) onSelectCandidate;

  @override
  Widget build(BuildContext context) {
    final candidates = suggestion.alternativeCandidates ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedCandidate != null)
          _CandidateCard(candidate: selectedCandidate!, isSelected: true, isTopPick: true),
        ...candidates.skip(1).take(3).map((c) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: _CandidateCard(candidate: c, isSelected: false, isTopPick: false),
        )),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.isSelected, required this.isTopPick});
  final AICandidateSuggestion candidate;
  final bool isSelected;
  final bool isTopPick;

  Color get _scoreColor => candidate.matchScore >= 80
      ? AppColors.success
      : candidate.matchScore >= 60 ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.aiInsight.withAlpha(15) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: isSelected ? AppColors.aiInsight.withAlpha(102) : (isDark ? AppColors.borderDark : AppColors.borderLight).withAlpha(77),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.greenGradient(context),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Center(
              child: Text(
                candidate.fullName.split(' ').last[0].toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(candidate.fullName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    ),
                    if (isTopPick) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.aiInsight.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text('Best Match', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.aiInsight, fontWeight: FontWeight.w700, fontSize: 10,
                        )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(candidate.reason, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(color: _scoreColor.withAlpha(25), borderRadius: BorderRadius.circular(AppRadius.xs)),
                child: Text('${candidate.matchScore.toInt()}%', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _scoreColor, fontWeight: FontWeight.w800,
                )),
              ),
              const SizedBox(height: 4),
              Text('${candidate.currentTaskCount} tasks', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
