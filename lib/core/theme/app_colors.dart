import 'package:flutter/material.dart';

abstract class AppColors {
  // === BRAND ===
  static const Color primary       = Color(0xFF2E7D32);
  static const Color primaryLight  = Color(0xFF4CAF50);
  static const Color accent        = Color(0xFF81C784);
  static const Color accentLight   = Color(0xFFA5D6A7);

  // === LIGHT THEME — Sky Gradient ===
  // Layer 1: Sky Gradient (fresh morning atmosphere)
  static const Color skyTop     = Color(0xFFEAF6FF); // Fresh morning sky
  static const Color skyMid     = Color(0xFFF6FBFF); // Soft cloud white
  static const Color skyBottom  = Color(0xFFF7FAF5); // Natural green-white

  // Light theme
  static const Color backgroundLight = Color(0xFFF7FAF5);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color textPrimaryLight   = Color(0xFF1B1F1B);
  static const Color textSecondaryLight = Color(0xFF6E776E);
  static const Color borderLight    = Color(0xFFE8EDE8);
  static const Color iconLight     = Color(0xFF424242);

  // === DARK THEME — Greenhouse Control Center ===
  static const Color backgroundDark = Color(0xFF0F1411);
  static const Color surfaceDark    = Color(0xFF18201B);
  static const Color cardDark       = Color(0xFF202A23);
  static const Color textPrimaryDark   = Color(0xFFF5F7F5);
  static const Color textSecondaryDark = Color(0xFFAAB7AA);
  static const Color borderDark    = Color(0xFF2A3A2D);
  static const Color iconDark      = Color(0xFFE0E0E0);

  // === SEMANTIC — Semantic & Status ===
  static const Color success   = Color(0xFF4CAF50);
  static const Color warning  = Color(0xFFFFA726);
  static const Color error    = Color(0xFFEF5350);
  static const Color info     = Color(0xFF42A5F5);
  static const Color neutral  = Color(0xFF9E9E9E);

  // === AGRITECH DATA COLORS ===
  // Plant Health gradient (green spectrum)
  static const Color healthExcellent = Color(0xFF2E7D32);
  static const Color healthGood     = Color(0xFF4CAF50);
  static const Color healthWarning  = Color(0xFFFFB74D);
  static const Color healthCritical = Color(0xFFEF5350);

  // Growth metrics (scientific)
  static const Color growthLine   = Color(0xFF66BB6A);
  static const Color growthFill    = Color(0xFF81C784);
  static const Color controlLine   = Color(0xFF42A5F5);
  static const Color controlFill   = Color(0xFF90CAF9);

  // Sensor status
  static const Color sensorOnline  = Color(0xFF4CAF50);
  static const Color sensorOffline = Color(0xFFEF5350);
  static const Color sensorWarning = Color(0xFFFFA726);
  static const Color sensorIdle   = Color(0xFF90A4AE);

  // Experiment status
  static const Color experimentActive    = Color(0xFF4CAF50);
  static const Color experimentPlanning = Color(0xFF42A5F5);
  static const Color experimentCompleted = Color(0xFF90A4AE);
  static const Color experimentPaused   = Color(0xFFFFA726);

  // AI Insights accent
  static const Color aiInsight  = Color(0xFF7E57C2);
  static const Color aiInsightBg = Color(0xFFF3E5F5);

  // Hero gradient colors
  static const Color heroGlow   = Color(0xFFA5D6A7);
  static const Color heroShadow = Color(0xFF1B5E20);

  // === INTERACTIVE STATES ===
  static const Color hovered   = Color(0x0A2E7D32);
  static const Color pressed   = Color(0x142E7D32);
  static const Color disabled  = Color(0x612E7D32);
  static const Color focused   = Color(0x1F2E7D32);

  // === CHART COLORS ===
  static const List<Color> chartPalette = [
    Color(0xFF4CAF50),
    Color(0xFF42A5F5),
    Color(0xFFFFA726),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF26A69A),
  ];

  // Gradients
  static const LinearGradient lightSkyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyTop, skyMid, skyBottom],
    stops: [0.0, 0.4, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
      Color(0xFF43A047),
    ],
  );

  static LinearGradient greenGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
      stops: [0.0, 0.4, 1.0],
    );
  }
}
