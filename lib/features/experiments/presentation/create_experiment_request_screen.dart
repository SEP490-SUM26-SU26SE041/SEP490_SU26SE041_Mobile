import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class CreateExperimentRequestScreen extends ConsumerStatefulWidget {
  const CreateExperimentRequestScreen({super.key});

  @override
  ConsumerState<CreateExperimentRequestScreen> createState() => _CreateExperimentRequestScreenState();
}

class _CreateExperimentRequestScreenState extends ConsumerState<CreateExperimentRequestScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _titleCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  String _selectedCrop = 'Cà chua bi Cherry 101';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 45));
  final _plantQtyCtrl = TextEditingController(text: '60');
  final _groupCountCtrl = TextEditingController(text: '2');
  final _areaCtrl = TextEditingController(text: '50');
  final _zoneCountCtrl = TextEditingController(text: '2');
  final _bedCountCtrl = TextEditingController(text: '4');
  final _spacingCtrl = TextEditingController(text: '30');
  String _soilType = 'Đất phù sa pha cát';
  final Set<String> _monitoring = {'Temperature', 'Humidity', 'Soil Moisture'};

  final List<String> _crops = [
    'Cà chua bi Cherry 101', 'Cà chua thường', 'Dưa leo', 'Rau muống', 'Ớt chuông',
  ];
  final List<String> _soilTypes = [
    'Đất phù sa pha cát', 'Đất thịt nặng', 'Đất đen', 'Đất laterite',
  ];
  final List<String> _monitoringOptions = [
    'Temperature', 'Humidity', 'Soil Moisture', 'Light',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _objectiveCtrl.dispose();
    _plantQtyCtrl.dispose();
    _groupCountCtrl.dispose();
    _areaCtrl.dispose();
    _zoneCountCtrl.dispose();
    _bedCountCtrl.dispose();
    _spacingCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && (_titleCtrl.text.trim().isEmpty || _objectiveCtrl.text.trim().isEmpty)) return;
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Experiment request submitted successfully!'), backgroundColor: AppColors.success),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('New Experiment Request'),
        backgroundColor: cs.surface,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: List.generate(3, (i) {
                final isDone = i < _currentStep;
                final isActive = i == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? AppSpacing.sm : 0),
                    decoration: BoxDecoration(
                      color: isDone || isActive ? AppColors.primary : cs.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepLabel(label: 'Basic Info', isActive: _currentStep >= 0),
                _StepLabel(label: 'Location', isActive: _currentStep >= 1),
                _StepLabel(label: 'Review', isActive: _currentStep >= 2),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Body(titleCtrl: _titleCtrl, objectiveCtrl: _objectiveCtrl, selectedCrop: _selectedCrop,
                  startDate: _startDate, endDate: _endDate, plantQtyCtrl: _plantQtyCtrl,
                  groupCountCtrl: _groupCountCtrl, areaCtrl: _areaCtrl, crops: _crops,
                  onCropChanged: (v) => setState(() => _selectedCrop = v!),
                  onStartDateTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _startDate,
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setState(() => _startDate = d);
                  },
                  onEndDateTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _endDate,
                      firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 730)));
                    if (d != null) setState(() => _endDate = d);
                  },
                ),
                _Step2Body(zoneCountCtrl: _zoneCountCtrl, bedCountCtrl: _bedCountCtrl,
                  spacingCtrl: _spacingCtrl, soilType: _soilType, monitoring: _monitoring,
                  soilTypes: _soilTypes, monitoringOptions: _monitoringOptions,
                  onSoilChanged: (v) => setState(() => _soilType = v!),
                  onMonitoringToggle: (opt, selected) {
                    setState(() {
                      if (selected) { _monitoring.add(opt); }
                      else { _monitoring.remove(opt); }
                    });
                  },
                ),
                _Step3Body(titleCtrl: _titleCtrl, selectedCrop: _selectedCrop,
                  startDate: _startDate, endDate: _endDate, plantQtyCtrl: _plantQtyCtrl,
                  groupCountCtrl: _groupCountCtrl, areaCtrl: _areaCtrl,
                  zoneCountCtrl: _zoneCountCtrl, bedCountCtrl: _bedCountCtrl,
                  soilType: _soilType, monitoring: _monitoring,
                ),
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.md),
            decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outline.withAlpha(51)))),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(child: OutlinedButton(onPressed: _prevStep, child: const Text('Back'))),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == 2 ? _submit : _nextStep,
                    child: Text(_currentStep == 2 ? 'Submit Request' : 'Continue'),
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

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withAlpha(102),
      fontWeight: FontWeight.w600,
    ));
  }
}

class _Step1Body extends StatelessWidget {
  const _Step1Body({required this.titleCtrl, required this.objectiveCtrl, required this.selectedCrop,
    required this.startDate, required this.endDate, required this.plantQtyCtrl,
    required this.groupCountCtrl, required this.areaCtrl, required this.crops,
    required this.onCropChanged, required this.onStartDateTap, required this.onEndDateTap});

  final TextEditingController titleCtrl;
  final TextEditingController objectiveCtrl;
  final String selectedCrop;
  final DateTime startDate;
  final DateTime endDate;
  final TextEditingController plantQtyCtrl;
  final TextEditingController groupCountCtrl;
  final TextEditingController areaCtrl;
  final List<String> crops;
  final ValueChanged<String?> onCropChanged;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: GlobalKey(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Basic Information', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Provide the basic details for your experiment.', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
          const SizedBox(height: AppSpacing.xl),
          _FormField(label: 'Title *', hint: 'e.g., So sánh tưới nhỏ giọt và phun sương', ctrl: titleCtrl),
          const SizedBox(height: AppSpacing.lg),
          _FormField(label: 'Objective *', hint: 'Mục tiêu và giả thuyết...', ctrl: objectiveCtrl, maxLines: 4),
          const SizedBox(height: AppSpacing.lg),
          Text('Crop Variety', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(value: selectedCrop, decoration: const InputDecoration(),
            items: crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: onCropChanged),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _DateField(label: 'Start Date', value: startDate, onTap: onStartDateTap)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _DateField(label: 'End Date', value: endDate, onTap: onEndDateTap)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _NumField(label: 'Plants', ctrl: plantQtyCtrl, suffix: 'plants')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _NumField(label: 'Groups', ctrl: groupCountCtrl, suffix: 'groups')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _NumField(label: 'Area', ctrl: areaCtrl, suffix: 'm²')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step2Body extends StatelessWidget {
  const _Step2Body({required this.zoneCountCtrl, required this.bedCountCtrl,
    required this.spacingCtrl, required this.soilType, required this.monitoring,
    required this.soilTypes, required this.monitoringOptions,
    required this.onSoilChanged, required this.onMonitoringToggle});

  final TextEditingController zoneCountCtrl;
  final TextEditingController bedCountCtrl;
  final TextEditingController spacingCtrl;
  final String soilType;
  final Set<String> monitoring;
  final List<String> soilTypes;
  final List<String> monitoringOptions;
  final ValueChanged<String?> onSoilChanged;
  final void Function(String, bool) onMonitoringToggle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Location Requirements', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text('Specify the physical requirements.', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: _NumField(label: 'Zones', ctrl: zoneCountCtrl, suffix: 'zones')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _NumField(label: 'Beds', ctrl: bedCountCtrl, suffix: 'beds')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _NumField(label: 'Spacing', ctrl: spacingCtrl, suffix: 'cm')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Required Soil Type', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(value: soilType, decoration: const InputDecoration(),
          items: soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onSoilChanged),
        const SizedBox(height: AppSpacing.xl),
        Text('Monitoring Requirements', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Text('Select the environmental parameters to monitor.', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
          children: monitoringOptions.map((opt) {
            final isSelected = monitoring.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (s) => onMonitoringToggle(opt, s),
              selectedColor: AppColors.primary.withAlpha(38),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? AppColors.primary : cs.onSurface.withAlpha(179)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Step3Body extends StatelessWidget {
  const _Step3Body({required this.titleCtrl, required this.selectedCrop,
    required this.startDate, required this.endDate, required this.plantQtyCtrl,
    required this.groupCountCtrl, required this.areaCtrl,
    required this.zoneCountCtrl, required this.bedCountCtrl,
    required this.soilType, required this.monitoring});

  final TextEditingController titleCtrl;
  final String selectedCrop;
  final DateTime startDate;
  final DateTime endDate;
  final TextEditingController plantQtyCtrl;
  final TextEditingController groupCountCtrl;
  final TextEditingController areaCtrl;
  final TextEditingController zoneCountCtrl;
  final TextEditingController bedCountCtrl;
  final String soilType;
  final Set<String> monitoring;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Review & Submit', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text('Review your experiment request before submitting.', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withAlpha(128)),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Title', value: titleCtrl.text.isEmpty ? '—' : titleCtrl.text),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Crop Variety', value: selectedCrop),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Duration', value: '${_fmt(startDate)} — ${_fmt(endDate)}'),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Plants', value: '${plantQtyCtrl.text} plants'),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Groups', value: '${groupCountCtrl.text} groups'),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Area', value: '${areaCtrl.text} m²'),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Zones / Beds', value: '${zoneCountCtrl.text} / ${bedCountCtrl.text}'),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(label: 'Soil Type', value: soilType),
              const Divider(height: AppSpacing.lg),
              Text('Monitoring', style: tt.labelMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: monitoring.map((m) => Chip(
                  label: Text(m, style: tt.labelSmall),
                  backgroundColor: AppColors.primary.withAlpha(25),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Your request will be reviewed by the Farm Manager before approval.', style: tt.bodySmall?.copyWith(color: AppColors.info))),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.hint, required this.ctrl, this.maxLines = 1});
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${value.day}/${value.month}/${value.year}'),
                const Icon(Icons.calendar_today_outlined, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.ctrl, required this.suffix});
  final String label;
  final TextEditingController ctrl;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(suffixText: suffix)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
        Flexible(child: Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ],
    );
  }
}
