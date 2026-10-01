import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/rag_models.dart';

/// Knowledge Group Filter (spec mục 3.3):
/// 5 nhóm + "Tất cả", hiển thị dưới dạng horizontal scroll chips.
class KnowledgeGroupFilter extends StatelessWidget {
  const KnowledgeGroupFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String? selected; // null = Tất cả
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final groups = KnowledgeGroup.values;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, idx) {
          final g = groups[idx];
          final isSelected = selected == g.value;
          return GestureDetector(
            onTap: () => onChanged(g.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : cs.surfaceContainerHighest.withAlpha(160),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : cs.outline.withAlpha(60),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(g.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    g.label,
                    style: tt.labelMedium?.copyWith(
                      color: isSelected ? Colors.white : cs.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
