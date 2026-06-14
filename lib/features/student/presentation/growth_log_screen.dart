import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../mock/mock_growth_data.dart';

final selectedBatchIdProvider = StateProvider<String>((ref) => 'batch-ctrl-01');

final filteredGrowthRecordsProvider = Provider<List<GrowthRecordModel>>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  return mockGrowthRecords.where((r) => r.batchId == batchId).toList()
    ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
});

final chartDataProvider = Provider<List<FlSpot>>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  final now = DateTime.now();
  final spots = <FlSpot>[];

  for (int i = 13; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final record = mockGrowthRecords.where((r) =>
      r.batchId == batchId &&
      r.recordedAt.year == date.year &&
      r.recordedAt.month == date.month &&
      r.recordedAt.day == date.day
    ).toList();

    if (record.isNotEmpty) {
      spots.add(FlSpot((14 - i).toDouble(), record.first.plantHeight));
    }
  }
  return spots;
});

final hasTodayRecordProvider = Provider<bool>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  final now = DateTime.now();
  return mockGrowthRecords.any((r) =>
    r.batchId == batchId &&
    r.recordedAt.year == now.year &&
    r.recordedAt.month == now.month &&
    r.recordedAt.day == now.day
  );
});

final leafCountChartProvider = Provider<List<FlSpot>>((ref) {
  final batchId = ref.watch(selectedBatchIdProvider);
  final now = DateTime.now();
  final spots = <FlSpot>[];

  for (int i = 13; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final record = mockGrowthRecords.where((r) =>
      r.batchId == batchId &&
      r.recordedAt.year == date.year &&
      r.recordedAt.month == date.month &&
      r.recordedAt.day == date.day
    ).toList();

    if (record.isNotEmpty) {
      spots.add(FlSpot((14 - i).toDouble(), record.first.leafCount.toDouble()));
    }
  }
  return spots;
});

class GrowthLogScreen extends ConsumerStatefulWidget {
  const GrowthLogScreen({super.key});

  @override
  ConsumerState<GrowthLogScreen> createState() => _GrowthLogScreenState();
}

class _GrowthLogScreenState extends ConsumerState<GrowthLogScreen> {
  final _heightController = TextEditingController();
  final _leafCountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedLeafColor = 'Xanh đậm';

  final List<String> _leafColors = ['Xanh đậm', 'Xanh', 'Vàng nhạt', 'Xanh bóng', 'Khác'];

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
    final hasTodayRecord = ref.watch(hasTodayRecordProvider);
    final records = ref.watch(filteredGrowthRecordsProvider);
    final chartSpots = ref.watch(chartDataProvider);
    final leafCountSpots = ref.watch(leafCountChartProvider);
    final selectedBatchId = ref.watch(selectedBatchIdProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Nhật ký tăng trưởng'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BatchSelector(tt: tt, cs: cs, ref: ref, selectedBatchId: selectedBatchId),
            const SizedBox(height: AppSpacing.xl),
            if (!hasTodayRecord) ...[
              _MeasurementFormSection(
                tt: tt,
                cs: cs,
                heightController: _heightController,
                leafCountController: _leafCountController,
                noteController: _noteController,
                selectedLeafColor: _selectedLeafColor,
                leafColors: _leafColors,
                onLeafColorChanged: (v) => setState(() => _selectedLeafColor = v),
                onSave: _saveRecord,
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              _TodayRecordedBanner(tt: tt, cs: cs),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (chartSpots.isNotEmpty) ...[
              Text('Biểu đồ tăng trưởng', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              _GrowthChart(
                heightSpots: chartSpots,
                leafCountSpots: leafCountSpots,
                tt: tt,
                cs: cs,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text('Lịch sử ghi nhận', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            if (records.isEmpty)
              _EmptyRecordsState(tt: tt, cs: cs)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: _GrowthRecordCard(record: records[index], tt: tt, cs: cs),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _saveRecord() {
    final height = double.tryParse(_heightController.text);
    final leafCount = int.tryParse(_leafCountController.text);

    if (height == null || leafCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập chiều cao và số lá!'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu nhật ký tăng trưởng!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _heightController.clear();
    _leafCountController.clear();
    _noteController.clear();
    setState(() => _selectedLeafColor = 'Xanh đậm');

    ref.invalidate(hasTodayRecordProvider);
    ref.invalidate(filteredGrowthRecordsProvider);
    ref.invalidate(chartDataProvider);
    ref.invalidate(leafCountChartProvider);
  }
}

class _BatchSelector extends StatelessWidget {
  const _BatchSelector({required this.tt, required this.cs, required this.ref, required this.selectedBatchId});
  final TextTheme tt;
  final ColorScheme cs;
  final WidgetRef ref;
  final String selectedBatchId;

  @override
  Widget build(BuildContext context) {
    final batches = [
      {'id': 'batch-ctrl-01', 'name': 'Nhóm Đối Chứng (B01)', 'tag': 'Đối Chứng'},
      {'id': 'batch-trt-01', 'name': 'Nhóm Thực Nghiệm (B02)', 'tag': 'Thực Nghiệm'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn lô cây', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withAlpha(30)),
          ),
          child: DropdownButton<String>(
            value: selectedBatchId,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent),
            dropdownColor: cs.surface,
            items: batches.map((b) => DropdownMenuItem(
              value: b['id'] as String,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(b['tag'] as String, style: tt.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(b['name'] as String, style: tt.bodyMedium),
                ],
              ),
            )).toList(),
            onChanged: (v) {
              if (v != null) ref.read(selectedBatchIdProvider.notifier).state = v;
            },
          ),
        ),
      ],
    );
  }
}

class _MeasurementFormSection extends StatelessWidget {
  const _MeasurementFormSection({
    required this.tt,
    required this.cs,
    required this.heightController,
    required this.leafCountController,
    required this.noteController,
    required this.selectedLeafColor,
    required this.leafColors,
    required this.onLeafColorChanged,
    required this.onSave,
  });

  final TextTheme tt;
  final ColorScheme cs;
  final TextEditingController heightController;
  final TextEditingController leafCountController;
  final TextEditingController noteController;
  final String selectedLeafColor;
  final List<String> leafColors;
  final ValueChanged<String> onLeafColorChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.straighten_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ghi nhận chỉ số hôm nay', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Đo lường tăng trưởng', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chiều cao (cm) *', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'VD: 18.5',
                        suffixText: 'cm',
                        filled: true,
                        fillColor: AppColors.accent.withAlpha(8),
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
                    Text('Số lá *', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: leafCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'VD: 8',
                        suffixText: 'lá',
                        filled: true,
                        fillColor: AppColors.accent.withAlpha(8),
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
          _DropdownField(
            value: selectedLeafColor,
            items: leafColors,
            onChanged: onLeafColorChanged,
            tt: tt,
            cs: cs,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Ghi chú', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú (tùy chọn)',
              filled: true,
              fillColor: AppColors.accent.withAlpha(8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 20, color: Colors.white),
              label: Text('Lưu nhật ký', style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRecordedBanner extends StatelessWidget {
  const _TodayRecordedBanner({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đã ghi nhận hôm nay', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.success)),
                Text('Bạn đã ghi nhận tăng trưởng cho lô này hôm nay', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatefulWidget {
  const _GrowthChart({required this.heightSpots, required this.leafCountSpots, required this.tt, required this.cs});
  final List<FlSpot> heightSpots;
  final List<FlSpot> leafCountSpots;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  State<_GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<_GrowthChart> {
  bool _showLeafCount = false;

  @override
  Widget build(BuildContext context) {
    final spots = _showLeafCount ? widget.leafCountSpots : widget.heightSpots;
    final color = _showLeafCount ? AppColors.success : AppColors.accent;
    final label = _showLeafCount ? 'Số lá' : 'Chiều cao (cm)';

    return SNMSCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: widget.tt.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
              const Spacer(),
              ToggleButtons(
                isSelected: [!_showLeafCount, _showLeafCount],
                onPressed: (index) => setState(() => _showLeafCount = index == 1),
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 28),
                fillColor: color.withAlpha(25),
                selectedColor: color,
                color: widget.cs.onSurface.withAlpha(128),
                textStyle: widget.tt.labelSmall,
                children: const [
                  Text('Cao'),
                  Text('Lá'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(child: Text('Chưa có đủ dữ liệu', style: widget.tt.bodyMedium?.copyWith(color: widget.cs.onSurface.withAlpha(128))))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _showLeafCount ? 2 : 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: widget.cs.outline.withAlpha(51),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: _showLeafCount ? 2 : 5,
                            getTitlesWidget: (value, meta) => Text(
                              _showLeafCount ? '${value.toInt()}' : '${value.toInt()}',
                              style: widget.tt.labelSmall?.copyWith(color: widget.cs.onSurface.withAlpha(102)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 3,
                            getTitlesWidget: (value, meta) => Text(
                              'D${value.toInt()}',
                              style: widget.tt.labelSmall?.copyWith(color: widget.cs.onSurface.withAlpha(102)),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withAlpha(25),
                          ),
                        ),
                      ],
                      minY: (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2).clamp(0, double.infinity),
                      maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrowthRecordCard extends StatelessWidget {
  const _GrowthRecordCard({required this.record, required this.tt, required this.cs});
  final GrowthRecordModel record;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (record.plantStatus) {
      'Khỏe mạnh' => AppColors.success,
      'Bình thường' => AppColors.warning,
      'Yếu' => AppColors.error,
      'Rất tốt' => AppColors.primary,
      _ => AppColors.info,
    };

    return SNMSCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('dd').format(record.recordedAt), style: tt.titleMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                Text(DateFormat('MM').format(record.recordedAt), style: tt.labelSmall?.copyWith(color: AppColors.accent)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                    ),
                    const SizedBox(width: 6),
                    Text('${record.plantHeight} cm', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppSpacing.sm),
                    Text('• ${record.leafCount} lá', style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(record.plantStatus, style: tt.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600, fontSize: 10)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(record.leafColor, style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(102), fontSize: 10)),
                  ],
                ),
                if (record.note != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(record.note!, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getHealthColor(record.plantStatus).withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getHealthIcon(record.plantStatus), size: 10, color: _getHealthColor(record.plantStatus)),
                    const SizedBox(width: 2),
                    Text(record.plantStatus, style: tt.labelSmall?.copyWith(color: _getHealthColor(record.plantStatus), fontWeight: FontWeight.w600, fontSize: 9)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withAlpha(77), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String status) => switch (status) {
    'Khỏe mạnh' => AppColors.success,
    'Bình thường' => AppColors.warning,
    'Yếu' => AppColors.error,
    'Rất tốt' => AppColors.primary,
    _ => AppColors.info,
  };

  IconData _getHealthIcon(String status) => switch (status) {
    'Khỏe mạnh' => Icons.favorite_rounded,
    'Bình thường' => Icons.thumb_up_outlined,
    'Yếu' => Icons.warning_rounded,
    'Rất tốt' => Icons.star_rounded,
    _ => Icons.eco_rounded,
  };
}

class _EmptyRecordsState extends StatelessWidget {
  const _EmptyRecordsState({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 48, color: cs.onSurface.withAlpha(77)),
              const SizedBox(height: AppSpacing.sm),
              Text('Chưa có dữ liệu ghi nhận', style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(128))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.value, required this.items, required this.onChanged, required this.tt, required this.cs, required this.color});
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final TextTheme tt;
  final ColorScheme cs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: cs.surface,
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: tt.bodyMedium))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}
