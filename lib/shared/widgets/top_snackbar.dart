import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Snackbar hiển thị phía trên cùng (top) — dùng cho thông báo trạng thái
/// báo cáo (thành công/thất bại) vì default `ScaffoldMessenger` show bottom
/// dễ bị conflict với keyboard / bottom sheet.
enum TopSnackType { success, error, warning, info }

void showTopSnackBar(
  BuildContext context, {
  required String message,
  TopSnackType type = TopSnackType.info,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
  VoidCallback? onAction,
  String? actionLabel,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // Ẩn snackbar cũ (nếu có) để tránh xếp chồng.
  messenger.hideCurrentSnackBar();

  final (bg, fg, defaultIcon) = switch (type) {
    TopSnackType.success => (
        AppColors.success,
        Colors.white,
        Icons.check_circle_rounded,
      ),
    TopSnackType.error => (
        AppColors.error,
        Colors.white,
        Icons.error_rounded,
      ),
    TopSnackType.warning => (
        AppColors.warning,
        Colors.white,
        Icons.warning_amber_rounded,
      ),
    TopSnackType.info => (
        AppColors.info,
        Colors.white,
        Icons.info_rounded,
      ),
  };

  final mediaQuery = MediaQuery.of(context);
  final topPadding = mediaQuery.padding.top;
  // Khoảng cách top padding (status bar + 12px).
  final marginTop = topPadding + 12;

  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(
        AppSpacingValues.md,
        marginTop,
        AppSpacingValues.md,
        0,
      ),
      content: _TopSnackContent(
        message: message,
        backgroundColor: bg,
        foregroundColor: fg,
        icon: icon ?? defaultIcon,
        onAction: onAction,
        actionLabel: actionLabel,
      ),
    ),
  );
}

class AppSpacingValues {
  static const double md = 12;
  static const double sm = 8;
  static const double lg = 16;
}

class _TopSnackContent extends StatelessWidget {
  const _TopSnackContent({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: () {
                  onAction!();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                style: TextButton.styleFrom(
                  foregroundColor: foregroundColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
