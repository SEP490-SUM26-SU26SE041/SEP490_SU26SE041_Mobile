import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/mock_ai_scan.dart';
import 'material_symbol.dart';

/// Section "Đề xuất xử lý" — list các treatment item dạng card.
class TreatmentsSection extends StatelessWidget {
  const TreatmentsSection({super.key, required this.items});
  final List<TreatmentItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Chưa có đề xuất xử lý cho kết quả này.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(178)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đề xuất xử lý', style: tt.titleLarge?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 12),
        ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TreatmentCard(item: t),
            )),
      ],
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({required this.item});
  final TreatmentItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final iconBg = _iconBackground(item.id, cs);
    final iconColor = _iconForeground(item.id, cs);
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline.withAlpha(60)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(MaterialSymbol.get(item.iconName), color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(178)),
                    ),
                  ],
                ),
              ),
              if (item.hasChevron)
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }

  Color _iconBackground(String id, ColorScheme cs) {
    return switch (id) {
      't1' => AppColors.accent.withAlpha(64),
      't2' => AppColors.primary.withAlpha(20),
      _ => cs.surfaceContainerHighest,
    };
  }

  Color _iconForeground(String id, ColorScheme cs) {
    return switch (id) {
      't1' => AppColors.primaryLight,
      't2' => AppColors.primary,
      _ => cs.onSurface.withAlpha(180),
    };
  }
}