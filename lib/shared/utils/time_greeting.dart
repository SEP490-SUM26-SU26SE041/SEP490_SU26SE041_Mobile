import 'package:flutter/material.dart';

/// Greeting theo giờ trong ngày, kèm icon mặt trời/mặt trăng cho hợp ngữ cảnh.
///
/// Mapping:
/// - 5h-11h59  → "Chào buổi sáng!"  ☀️  (mặt trời đầy đủ, màu warning/amber)
/// - 12h-17h59 → "Chào buổi chiều!" 🌤️ (mặt trời viền, màu accent)
/// - 18h-21h59 → "Chào buổi tối!"  🌙  (trăng khuyết, màu info indigo)
/// - 22h-4h59  → "Đêm khuya rồi!"  🌑  (trăng đầy, màu primaryDark/indigo)
///
/// Trả về cả text và iconData để caller render theo design của mình.
class TimeGreeting {
  const TimeGreeting({
    required this.text,
    required this.icon,
    required this.tone,
  });

  final String text;
  final IconData icon;

  /// Tone màu nên dùng cho icon (đã align với `AppColors`).
  /// Caller có thể dùng trực tiếp hoặc override.
  final Color tone;

  /// Trả về greeting dựa trên `DateTime.now()`.
  factory TimeGreeting.now() => TimeGreeting.fromHour(DateTime.now().hour);

  /// Trả về greeting dựa trên giờ cụ thể (0-23) — testable.
  ///
  /// [morningColor] / [afternoonColor] / [eveningColor] / [nightColor] cho phép
  /// override tone màu (mặc định dùng tone hợp agritech theme).
  factory TimeGreeting.fromHour(
    int hour, {
    Color morningColor = const Color(0xFFFFB74D), // amber 300
    Color afternoonColor = const Color(0xFFFFA726), // warning orange
    Color eveningColor = const Color(0xFF7E57C2), // deep purple 400
    Color nightColor = const Color(0xFF5C6BC0), // indigo 400
  }) {
    if (hour >= 5 && hour < 12) {
      return TimeGreeting(
        text: 'Chào buổi sáng!',
        icon: Icons.wb_sunny_rounded,
        tone: morningColor,
      );
    }
    if (hour >= 12 && hour < 18) {
      return TimeGreeting(
        text: 'Chào buổi chiều!',
        icon: Icons.wb_sunny_outlined,
        tone: afternoonColor,
      );
    }
    if (hour >= 18 && hour < 22) {
      return TimeGreeting(
        text: 'Chào buổi tối!',
        icon: Icons.nights_stay_rounded,
        tone: eveningColor,
      );
    }
    return TimeGreeting(
      text: 'Đêm khuya rồi!',
      icon: Icons.bedtime_rounded,
      tone: nightColor,
    );
  }
}