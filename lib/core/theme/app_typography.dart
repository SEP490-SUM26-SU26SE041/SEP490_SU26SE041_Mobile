import 'package:flutter/material.dart';

/// Typography cho 3 role: Researcher / Student / Technician.
///
/// Font: system default (Roboto trên Android, SF Pro trên iOS) — không cần
/// network fetch, hoạt động offline hoàn toàn.
abstract class AppTypography {
  static TextTheme get textTheme => const TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge:   TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium:  TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall:   TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      );

  /// Style riêng cho tiêu đề nổi bật (AI Scan screen, hero sections).
  static const TextStyle heroTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 30 / 24,
  );

  /// Label uppercase kiểu Material — dùng cho "KẾT QUẢ", "PHÁT HIỆN"...
  static const TextStyle overlineLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 16 / 12,
  );
}