import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/mock_ai_scan.dart';

/// Section "Chi tiết phát hiện" — UX thân thiện cho người dùng.
///
/// Hiển thị:
///   1. Detection bệnh (disease) — kết quả chính, gộp theo class name.
///   2. Detection gate — phụ, label nhạt hơn (gate model tiền xử lý).
///   3. Bbox ở dạng gọn "vị trí" (vd: "Trung tâm - Rộng 60%"), không raw pixel.
class DetectionListSection extends StatelessWidget {
  const DetectionListSection({
    super.key,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    this.accentColor = AppColors.primary,
  });

  final List<DetectionItem> detections;
  final int imageWidth;
  final int imageHeight;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final diseaseDets = detections
        .where((d) => d.category == DetectionCategory.disease && d.box != null)
        .toList(growable: false);
    final gateDets = detections
        .where((d) => d.category == DetectionCategory.gate)
        .toList(growable: false);

    if (diseaseDets.isEmpty && gateDets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Gộp disease detections theo label (vd: "Tomato_Late_blight" xuất hiện 2 lần → 1 dòng).
    final diseaseGroups = _groupByLabel(diseaseDets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diseaseGroups.isNotEmpty) ...[
          _SectionTitle(
            title: 'Vùng nghi ngờ (${diseaseGroups.length})',
            icon: Icons.center_focus_strong_rounded,
            color: accentColor,
          ),
          const SizedBox(height: 12),
          ...diseaseGroups.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DiseaseDetectionGroupCard(
                  group: g,
                  accentColor: accentColor,
                ),
              )),
          if (gateDets.isNotEmpty) const SizedBox(height: 16),
        ],
        if (gateDets.isNotEmpty) ...[
          _SectionTitle(
            title: 'Cổng kiểm tra',
            icon: Icons.shield_outlined,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          ...gateDets.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _GateDetectionCard(detection: g),
              )),
        ],
      ],
    );
  }

  /// Gộp các detection cùng label thành 1 group (đếm số lượng, lấy confidence max).
  List<_DiseaseGroup> _groupByLabel(List<DetectionItem> items) {
    final byLabel = <String, List<DetectionItem>>{};
    for (final d in items) {
      byLabel.putIfAbsent(d.label.isEmpty ? 'unknown' : d.label, () => []).add(d);
    }
    return byLabel.entries
        .map((e) {
          final list = e.value;
          final maxConf = list
              .map((d) => d.confidence)
              .fold<double>(0, (a, b) => a > b ? a : b);
          return _DiseaseGroup(
            label: e.key,
            count: list.length,
            maxConfidence: maxConf,
            detections: list,
          );
        })
        .toList()
      ..sort((a, b) => b.maxConfidence.compareTo(a.maxConfidence));
  }
}

class _DiseaseGroup {
  _DiseaseGroup({
    required this.label,
    required this.count,
    required this.maxConfidence,
    required this.detections,
  });

  final String label;
  final int count;
  final double maxConfidence;
  final List<DetectionItem> detections;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Card cho 1 nhóm disease detection — format bbox thân thiện người dùng.
class _DiseaseDetectionGroupCard extends StatelessWidget {
  const _DiseaseDetectionGroupCard({
    required this.group,
    required this.accentColor,
  });

  final _DiseaseGroup group;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = _pretty(group.label);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6, height: 44,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (group.count > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '×${group.count}',
                          style: tt.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${(group.maxConfidence * 100).toStringAsFixed(0)}%',
                        style: tt.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (group.detections.isNotEmpty)
                  _BboxSummary(detection: group.detections.first),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pretty(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }
}

/// Hiển thị bbox dạng người dùng dễ hiểu:
///   - Vị trí: "Trung tâm", "Góc trên-trái", ...
///   - Kích thước: "Nhỏ (<10%)", "Trung bình", "Lớn (>50%)".
class _BboxSummary extends StatelessWidget {
  const _BboxSummary({required this.detection});
  final DetectionItem detection;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final box = detection.box;
    if (box == null) return const SizedBox.shrink();

    final position = _describePosition(box);
    final size = _describeSize(box);
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 14, color: cs.onSurface.withAlpha(153)),
        const SizedBox(width: 4),
        Text(
          position,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(178)),
        ),
        const SizedBox(width: 10),
        Icon(Icons.straighten_outlined, size: 14, color: cs.onSurface.withAlpha(153)),
        const SizedBox(width: 4),
        Text(
          size,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(178)),
        ),
      ],
    );
  }

  String _describePosition(BoundingBox box) {
    final w = box.originalWidth.toDouble();
    final h = box.originalHeight.toDouble();
    if (w <= 0 || h <= 0) return '';
    final centerX = (box.x1 + box.x2) / 2 / w;
    final centerY = (box.y1 + box.y2) / 2 / h;

    final vertical = centerY < 0.33
        ? 'trên'
        : (centerY > 0.66 ? 'dưới' : 'giữa');
    final horizontal = centerX < 0.33
        ? 'trái'
        : (centerX > 0.66 ? 'phải' : 'giữa');

    if (vertical == 'giữa' && horizontal == 'giữa') return 'Trung tâm';
    if (vertical == 'giữa') return 'Giữa $horizontal';
    if (horizontal == 'giữa') return '${_capitalize(vertical)}';
    return '${_capitalize(vertical)}-$horizontal';
  }

  String _describeSize(BoundingBox box) {
    final area = (box.width * box.height) /
        (box.originalWidth * box.originalHeight);
    if (area < 0.05) return 'Rất nhỏ';
    if (area < 0.15) return 'Nhỏ';
    if (area < 0.35) return 'Trung bình';
    if (area < 0.6) return 'Lớn';
    return 'Chiếm phần lớn';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Card cho gate detection — hiển thị nhỏ gọn, không có bbox.
class _GateDetectionCard extends StatelessWidget {
  const _GateDetectionCard({required this.detection});
  final DetectionItem detection;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = detection.label.isEmpty ? 'Gate' : detection.label;
    final pretty = label
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined,
              size: 16, color: cs.onSurface.withAlpha(153)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pretty,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(178)),
            ),
          ),
          Text(
            '${detection.confidencePercent}%',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withAlpha(178),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section "Phân bố xác suất" — list probabilities từng class (Tomato API có thể trả).
class ProbabilitiesSection extends StatelessWidget {
  const ProbabilitiesSection({
    super.key,
    required this.probabilities,
    this.accentColor = AppColors.primary,
  });

  final Map<String, double> probabilities;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (probabilities.isEmpty) return const SizedBox.shrink();
    final entries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final maxValue = entries.first.value.clamp(0.0001, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: accentColor, size: 18),
            const SizedBox(width: 6),
            Text(
              'Phân bố xác suất',
              style: tt.titleMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ProbabilityBar(
                label: e.key,
                value: e.value,
                ratio: e.value / maxValue,
                accentColor: accentColor,
                onSurface: cs.onSurface,
              ),
            )),
      ],
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  const _ProbabilityBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.accentColor,
    required this.onSurface,
  });

  final String label;
  final double value;
  final double ratio;
  final Color accentColor;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final formatted = label
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(formatted, style: tt.bodyMedium),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: onSurface.withAlpha(20),
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
        ),
      ],
    );
  }
}