import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Toggle "Chỉ truy xuất" (spec mục 4.2):
/// Hiển thị cho Student + Technician. Default ON (web v1.3).
class RetrievalOnlyToggle extends StatelessWidget {
  const RetrievalOnlyToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: value
            ? AppColors.info.withAlpha(18)
            : cs.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.info.withAlpha(80)
              : cs.outline.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: value ? AppColors.info : cs.onSurface.withAlpha(128),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỉ truy xuất tài liệu gốc',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? AppColors.info : cs.onSurface,
                  ),
                ),
                Text(
                  'Xem nguyên văn đoạn trích, không qua AI tổng hợp',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(153),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.info,
          ),
        ],
      ),
    );
  }
}
