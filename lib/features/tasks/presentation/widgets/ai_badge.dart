import 'package:flutter/material.dart';

import '../../../../core/api/models/task_report_model.dart';
import '../../../../core/constants/ai_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Badge overlay nhỏ hiển thị trạng thái AI trên tile ảnh.
///
/// - Idle:        không hiển thị (tùy chọn)
/// - Pending:    spinner nhỏ + "AI"
/// - Completed:  checkmark + icon provider
/// - Failed:    dấu X đỏ
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, required this.image, this.compact = true});

  final TaskImageModel image;

  /// true → chỉ icon + 1 chữ cái. false → badge rộng hơn.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (image.aiProvider == null) return const SizedBox.shrink();
    final meta = AiProviders.getMeta(image.aiProvider);

    if (image.isAiPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(140),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Text('AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
    }

    if (image.isAiFailed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 11),
            SizedBox(width: 2),
            Text('Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
    }

    if (image.isAiCompleted) {
      final analysis = image.aiAnalysis;
      final isGateRejection = analysis?.isGateRejection == true;
      final hasError = analysis?.hasError == true;
      Color bg = Color(meta.colorValue);
      IconData icon = Icons.check_rounded;
      if (isGateRejection) {
        bg = AppColors.warning;
        icon = Icons.warning_amber_rounded;
      } else if (hasError) {
        bg = AppColors.warning;
        icon = Icons.error_outline_rounded;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 11),
            const SizedBox(width: 2),
            Text(meta.shortName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
