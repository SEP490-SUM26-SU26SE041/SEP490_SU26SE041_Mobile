import 'package:flutter/material.dart';

/// Material Symbols (Outlined) — light-weight glyph catalog cho AI Scan UI.
///
/// Thay thế cho Material Icons mặc định — cùng họ glyph nhưng dùng tên
/// giống `Material Symbols Outlined` của Google Fonts web.
///
/// Map giữa glyph name -> IconData (Material Icons tương đương) để không
/// phải load font Material Symbols.
class MaterialSymbol {
  MaterialSymbol._();

  static const IconData _fallback = Icons.help_outline;

  /// Lấy [IconData] tương ứng với tên glyph Material Symbols.
  static IconData get(String name) => _map[name] ?? _fallback;

  static final Map<String, IconData> _map = <String, IconData>{
    // Hero / Scan
    'center_focus_strong': Icons.center_focus_strong_rounded,
    'photo_camera': Icons.photo_camera_rounded,
    'photo_library': Icons.photo_library_rounded,

    // Header
    'notifications': Icons.notifications_none_rounded,

    // Result
    'warning': Icons.warning_amber_rounded,
    'thermostat': Icons.thermostat_rounded,
    'history': Icons.history_rounded,

    // Treatments
    'content_cut': Icons.content_cut_rounded,
    'opacity': Icons.opacity_rounded,
    'air': Icons.air_rounded,
    'eco': Icons.eco_rounded,
    'spa': Icons.spa_rounded,
    'compost': Icons.compost_rounded,

    // Expert advisory
    'support_agent': Icons.support_agent_rounded,
    'send': Icons.send_rounded,
    'phone_in_talk': Icons.phone_in_talk_rounded,
    'forum': Icons.forum_rounded,

    // Nav (AI Scan tab)
    'dashboard': Icons.dashboard_outlined,
    'potted_plant': Icons.local_florist_outlined,
    'monitoring': Icons.insights_rounded,
    'assignment': Icons.assignment_outlined,
  };
}