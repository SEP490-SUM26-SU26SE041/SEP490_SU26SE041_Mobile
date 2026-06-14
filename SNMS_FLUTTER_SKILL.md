# Flutter SNMS Premium Agritech UI/UX Skill — v2.0
# Smart Nursery Management System — Production Grade

---

## ROLE

You are a Principal Flutter Architect, Staff Product Designer, Senior UX Researcher, and Agritech SaaS Expert building the **Smart Nursery Management System (SNMS)** — a production-grade IoT-integrated agricultural research platform.

You do NOT generate generic Flutter applications.

You create production-grade mobile experiences comparable to **Linear, Notion, Vercel, CropX, Climate FieldView, and John Deere Operations Center**.

---

## PRODUCT CONTEXT

**App:** Smart Nursery Management System (SNMS)  
**Domain:** IoT Agricultural Research Platform  
**Users:** 5 roles — Admin, Researcher, Farm Manager, Technician, Student  
**Platform:** Flutter mobile (iOS + Android), dark/light mode

### Core Domain Objects
- **Farm → Zone → Bed → Sensor** (spatial hierarchy)
- **Experiments** (owned by Researcher)
- **Nursery Batches** (created by Farm Manager)
- **Cultivation Methods**
- **Care Schedules**
- **KPIs** (Key Performance Indicators)

### Role Permissions Summary
| Role | Primary Responsibility |
|------|----------------------|
| Admin | User management, system config |
| Researcher | Create/manage Experiments, assign Students |
| Farm Manager | Create Nursery Batches, assign Technicians |
| Technician | Execute Care Schedules, report sensor issues |
| Student | View assigned Experiments, log observations |

---

## TECH STACK (MANDATORY)

```yaml
# pubspec.yaml dependencies
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^13.2.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  dio: ^5.4.3
  cached_network_image: ^3.3.1
  fl_chart: ^0.68.0
  intl: ^0.19.0
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.0.0
  mqtt_client: ^10.2.1       # IoT sensor data
  permission_handler: ^11.3.1

dev_dependencies:
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  build_runner: ^2.4.9
```

**State Management:** Riverpod (with code generation)  
**Navigation:** GoRouter  
**Data Models:** Freezed + JSON Serializable  
**Charts:** fl_chart  
**IoT:** MQTT Client  
**HTTP:** Dio  

---

## PROJECT STRUCTURE

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # ThemeData light + dark
│   │   ├── app_colors.dart         # Color tokens
│   │   ├── app_typography.dart     # TextTheme
│   │   └── app_spacing.dart        # Spacing constants
│   ├── router/
│   │   └── app_router.dart         # GoRouter config
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── api_endpoints.dart
│   └── utils/
│       ├── date_formatter.dart
│       └── sensor_utils.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/
│   ├── experiments/
│   ├── nursery_batches/
│   ├── care_schedules/
│   ├── sensors/
│   └── farm_map/
└── shared/
    ├── widgets/
    │   ├── snms_card.dart
    │   ├── sensor_status_badge.dart
    │   ├── kpi_tile.dart
    │   ├── alert_banner.dart
    │   ├── batch_card.dart
    │   ├── experiment_card.dart
    │   └── bottom_nav.dart
    └── models/
```

---

## DESIGN SYSTEM

### Spacing Scale (STRICT — no other values)

```dart
// lib/core/theme/app_spacing.dart
abstract class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;
}
```

### Border Radius

```dart
abstract class AppRadius {
  static const double small  = 12.0;
  static const double medium = 16.0;
  static const double large  = 24.0;
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: Radius.circular(24));
}
```

### Color Tokens

```dart
// lib/core/theme/app_colors.dart
abstract class AppColors {
  // === BRAND ===
  static const Color primary      = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color accent       = Color(0xFF81C784);
  static const Color accentLight  = Color(0xFFA5D6A7);

  // === LIGHT THEME ===
  static const Color backgroundLight = Color(0xFFF7FAF5);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color cardLight       = Color(0xFFFFFFFF);
  static const Color textPrimaryLight   = Color(0xFF1B1F1B);
  static const Color textSecondaryLight = Color(0xFF6E776E);
  static const Color borderLight     = Color(0xFFE8EDE8);

  // === DARK THEME ===
  static const Color backgroundDark = Color(0xFF0F1411);
  static const Color surfaceDark    = Color(0xFF18201B);
  static const Color cardDark       = Color(0xFF202A23);
  static const Color textPrimaryDark   = Color(0xFFF5F7F5);
  static const Color textSecondaryDark = Color(0xFFAAB7AA);
  static const Color borderDark     = Color(0xFF2A3A2D);

  // === SEMANTIC ===
  static const Color success  = Color(0xFF4CAF50);
  static const Color warning  = Color(0xFFFFA726);
  static const Color error    = Color(0xFFEF5350);
  static const Color info     = Color(0xFF42A5F5);

  // === SENSOR STATUS ===
  static const Color sensorOnline  = Color(0xFF4CAF50);
  static const Color sensorOffline = Color(0xFFEF5350);
  static const Color sensorWarning = Color(0xFFFFA726);
  static const Color sensorIdle    = Color(0xFF90A4AE);

  // === EXPERIMENT STATUS ===
  static const Color experimentActive    = Color(0xFF4CAF50);
  static const Color experimentPlanning  = Color(0xFF42A5F5);
  static const Color experimentCompleted = Color(0xFF90A4AE);
  static const Color experimentPaused    = Color(0xFFFFA726);

  // === STATES ===
  static const Color hovered  = Color(0x0A2E7D32);
  static const Color pressed  = Color(0x142E7D32);
  static const Color disabled = Color(0x612E7D32);
  static const Color focused  = Color(0x1F2E7D32);
}
```

### Typography

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTypography {
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    // Display
    displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600),

    // Headline
    headlineLarge:  GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall:  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),

    // Title
    titleLarge:  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
    titleSmall:  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),

    // Body
    bodyLarge:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),

    // Label
    labelLarge:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}
```

### ThemeData (Full — Light + Dark)

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: AppTypography.textTheme,
    colorScheme: const ColorScheme.light(
      primary:       AppColors.primary,
      secondary:     AppColors.primaryLight,
      tertiary:      AppColors.accent,
      background:    AppColors.backgroundLight,
      surface:       AppColors.surfaceLight,
      error:         AppColors.error,
      onPrimary:     Colors.white,
      onSecondary:   Colors.white,
      onBackground:  AppColors.textPrimaryLight,
      onSurface:     AppColors.textPrimaryLight,
      outline:       AppColors.borderLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardTheme: CardTheme(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundLight,
      selectedColor: AppColors.primary.withOpacity(0.12),
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: AppTypography.textTheme.labelMedium,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: AppTypography.textTheme,
    colorScheme: const ColorScheme.dark(
      primary:       AppColors.primaryLight,
      secondary:     AppColors.accent,
      tertiary:      AppColors.accentLight,
      background:    AppColors.backgroundDark,
      surface:       AppColors.surfaceDark,
      error:         AppColors.error,
      onPrimary:     Colors.black,
      onSecondary:   Colors.black,
      onBackground:  AppColors.textPrimaryDark,
      onSurface:     AppColors.textPrimaryDark,
      outline:       AppColors.borderDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardTheme: CardTheme(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDark, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.cardDark,
      selectedColor: AppColors.primaryLight.withOpacity(0.15),
      side: const BorderSide(color: AppColors.borderDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: AppTypography.textTheme.labelMedium,
    ),
  );
}
```

---

## COMPONENT LIBRARY

### 1. SNMSCard (Base Card)

```dart
// lib/shared/widgets/snms_card.dart
class SNMSCard extends StatelessWidget {
  const SNMSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### 2. SensorStatusBadge

```dart
// lib/shared/widgets/sensor_status_badge.dart
enum SensorStatus { online, offline, warning, idle }

class SensorStatusBadge extends StatelessWidget {
  const SensorStatusBadge({super.key, required this.status, this.showLabel = true});

  final SensorStatus status;
  final bool showLabel;

  Color get _color => switch (status) {
    SensorStatus.online  => AppColors.sensorOnline,
    SensorStatus.offline => AppColors.sensorOffline,
    SensorStatus.warning => AppColors.sensorWarning,
    SensorStatus.idle    => AppColors.sensorIdle,
  };

  String get _label => switch (status) {
    SensorStatus.online  => 'Online',
    SensorStatus.offline => 'Offline',
    SensorStatus.warning => 'Warning',
    SensorStatus.idle    => 'Idle',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot for online status
          if (status == SensorStatus.online)
            _PulsingDot(color: _color)
          else
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(_label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _color),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
```

### 3. KPITile

```dart
// lib/shared/widgets/kpi_tile.dart
class KPITile extends StatelessWidget {
  const KPITile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.trend,          // positive/negative % string e.g. "+2.4%"
    this.isAlert = false,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String? trend;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final trendPositive = trend?.startsWith('+') ?? false;
    final alertColor = isAlert ? AppColors.warning : cs.primary;

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: alertColor),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(trend!,
                    style: tt.labelSmall?.copyWith(
                      color: trendPositive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              text: value,
              style: tt.headlineMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
```

### 4. AlertBanner

```dart
// lib/shared/widgets/alert_banner.dart
enum AlertLevel { info, warning, critical }

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    required this.level,
    this.onTap,
    this.onDismiss,
  });

  final String message;
  final AlertLevel level;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  Color get _color => switch (level) {
    AlertLevel.info     => AppColors.info,
    AlertLevel.warning  => AppColors.warning,
    AlertLevel.critical => AppColors.error,
  };

  IconData get _icon => switch (level) {
    AlertLevel.info     => Icons.info_outline_rounded,
    AlertLevel.warning  => Icons.warning_amber_rounded,
    AlertLevel.critical => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(_icon, color: _color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                style: tt.bodySmall?.copyWith(color: _color, fontWeight: FontWeight.w500),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close_rounded, color: _color, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 5. ExperimentCard

```dart
// lib/shared/widgets/experiment_card.dart
enum ExperimentStatus { active, planning, completed, paused }

class ExperimentCard extends StatelessWidget {
  const ExperimentCard({
    super.key,
    required this.title,
    required this.status,
    required this.startDate,
    required this.zone,
    required this.progress,     // 0.0 to 1.0
    this.studentCount = 0,
    this.onTap,
  });

  final String title;
  final ExperimentStatus status;
  final DateTime startDate;
  final String zone;
  final double progress;
  final int studentCount;
  final VoidCallback? onTap;

  Color get _statusColor => switch (status) {
    ExperimentStatus.active    => AppColors.experimentActive,
    ExperimentStatus.planning  => AppColors.experimentPlanning,
    ExperimentStatus.completed => AppColors.experimentCompleted,
    ExperimentStatus.paused    => AppColors.experimentPaused,
  };

  String get _statusLabel => switch (status) {
    ExperimentStatus.active    => 'Active',
    ExperimentStatus.planning  => 'Planning',
    ExperimentStatus.completed => 'Completed',
    ExperimentStatus.paused    => 'Paused',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14,
                color: cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(zone, style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.5))),
              const SizedBox(width: 12),
              Icon(Icons.people_outline_rounded, size: 14,
                color: cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('$studentCount students', style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.outline.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(_statusColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withOpacity(0.4))),
              Text('${(progress * 100).toInt()}%', style: tt.labelSmall?.copyWith(
                color: _statusColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

### 6. BatchCard (Nursery Batch)

```dart
// lib/shared/widgets/batch_card.dart
class BatchCard extends StatelessWidget {
  const BatchCard({
    super.key,
    required this.batchCode,
    required this.cultivationMethod,
    required this.bedLocation,
    required this.plantedDate,
    required this.plantCount,
    required this.healthScore,   // 0–100
    this.technicianName,
    this.onTap,
  });

  final String batchCode;
  final String cultivationMethod;
  final String bedLocation;
  final DateTime plantedDate;
  final int plantCount;
  final int healthScore;
  final String? technicianName;
  final VoidCallback? onTap;

  Color get _healthColor {
    if (healthScore >= 80) return AppColors.success;
    if (healthScore >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batchCode,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onSurface, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(cultivationMethod,
                    style: tt.bodySmall?.copyWith(color: cs.primary)),
                ],
              ),
              // Health Score Ring
              _HealthRing(score: healthScore, color: _healthColor),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoItem(icon: Icons.grid_view_rounded, label: bedLocation),
              const SizedBox(width: 16),
              _InfoItem(icon: Icons.eco_outlined, label: '$plantCount plants'),
              if (technicianName != null) ...[
                const SizedBox(width: 16),
                _InfoItem(icon: Icons.person_outline_rounded, label: technicianName!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 44,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
            strokeWidth: 3.5,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text('$score',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurface.withOpacity(0.45)),
        const SizedBox(width: 4),
        Text(label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.55))),
      ],
    );
  }
}
```

---

## SCREEN INVENTORY

### Auth Screens
| Screen | Route | Access |
|--------|-------|--------|
| Login | `/login` | All |
| Forgot Password | `/forgot-password` | All |

### Dashboard (Role-Adaptive)
| Screen | Route | Access |
|--------|-------|--------|
| Dashboard | `/dashboard` | All (content adapts per role) |

### Farm Management
| Screen | Route | Access |
|--------|-------|--------|
| Farm Map | `/farm` | Admin, Farm Manager, Technician |
| Zone Detail | `/farm/zones/:id` | Admin, Farm Manager, Technician |
| Bed Detail | `/farm/zones/:zoneId/beds/:bedId` | All |
| Sensor Detail | `/sensors/:id` | Admin, Technician |

### Experiments
| Screen | Route | Access |
|--------|-------|--------|
| Experiment List | `/experiments` | Researcher, Student |
| Experiment Detail | `/experiments/:id` | Researcher, Student |
| Create Experiment | `/experiments/create` | Researcher |
| Observation Log | `/experiments/:id/observations` | Student, Researcher |

### Nursery Batches
| Screen | Route | Access |
|--------|-------|--------|
| Batch List | `/batches` | Farm Manager, Technician |
| Batch Detail | `/batches/:id` | Farm Manager, Technician |
| Create Batch | `/batches/create` | Farm Manager |

### Care Schedules
| Screen | Route | Access |
|--------|-------|--------|
| Schedule List | `/schedules` | Farm Manager, Technician |
| Schedule Detail | `/schedules/:id` | Technician |
| Create Schedule | `/schedules/create` | Farm Manager |

### Admin
| Screen | Route | Access |
|--------|-------|--------|
| User Management | `/admin/users` | Admin |
| System Config | `/admin/config` | Admin |
| KPI Config | `/admin/kpis` | Admin |

---

## NAVIGATION (GoRouter)

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/experiments',
            builder: (_, __) => const ExperimentListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ExperimentDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/batches',
            builder: (_, __) => const BatchListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => BatchDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/farm', builder: (_, __) => const FarmMapScreen()),
          GoRoute(path: '/schedules', builder: (_, __) => const ScheduleListScreen()),
        ],
      ),
    ],
  );
});
```

---

## STATE MANAGEMENT (Riverpod Patterns)

### Auth Provider

```dart
// lib/features/auth/providers/auth_provider.dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial()                       = _Initial;
  const factory AuthState.loading()                       = _Loading;
  const factory AuthState.authenticated(UserModel user)   = _Authenticated;
  const factory AuthState.unauthenticated()               = _Unauthenticated;
  const factory AuthState.error(String message)           = _Error;
}
```

### Experiment Provider

```dart
// lib/features/experiments/providers/experiment_provider.dart
@riverpod
Future<List<Experiment>> experiments(ExperimentsRef ref) async {
  final repo = ref.read(experimentRepositoryProvider);
  return repo.getExperiments();
}

@riverpod
Future<Experiment> experimentDetail(
  ExperimentDetailRef ref,
  String id,
) async {
  return ref.read(experimentRepositoryProvider).getExperiment(id);
}

// Invalidate on mutation
@riverpod
class ExperimentActions extends _$ExperimentActions {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createExperiment(CreateExperimentDto dto) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(experimentRepositoryProvider).create(dto);
      ref.invalidate(experimentsProvider);  // refresh list
    });
  }
}
```

### Sensor MQTT Provider

```dart
// lib/features/sensors/providers/sensor_stream_provider.dart
@riverpod
Stream<SensorReading> sensorStream(
  SensorStreamRef ref,
  String sensorId,
) {
  final mqttClient = ref.read(mqttClientProvider);
  return mqttClient.subscribe('sensors/$sensorId/data');
}
```

---

## ANIMATION SPEC

### Standard Durations

```dart
abstract class AppDuration {
  static const quick  = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow   = Duration(milliseconds: 400);
  static const page   = Duration(milliseconds: 300);
}
```

### Standard Curves

```dart
abstract class AppCurve {
  static const standard   = Curves.easeInOut;
  static const enter      = Curves.easeOut;
  static const exit       = Curves.easeIn;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}
```

### Page Transitions (GoRouter)

```dart
// Use for all screen transitions
CustomTransitionPage(
  child: screen,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: CurveTween(curve: AppCurve.enter).animate(animation),
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurveTween(curve: AppCurve.enter).animate(animation)),
        child: child,
      ),
    );
  },
  transitionDuration: AppDuration.page,
)
```

### Sensor Pulse Animation
→ Use `_PulsingDot` widget from SensorStatusBadge (see Component Library above)

### Staggered List (for dashboards)

```dart
// Wrap each list item with delay
AnimationConfiguration.staggeredList(
  position: index,
  duration: AppDuration.slow,
  child: SlideAnimation(
    verticalOffset: 24,
    child: FadeInAnimation(child: card),
  ),
)
// Requires: flutter_staggered_animations package
```

---

## DASHBOARD LAYOUT RULES

Every dashboard follows this section order — NO EXCEPTIONS:

```
1. AppBar (greeting + role badge + notifications)
2. AlertBanner(s) — if any critical/warning alerts
3. KPI Tiles row (2×2 grid, role-appropriate metrics)
4. Quick Actions (max 3 primary actions for role)
5. Active Work (active experiments / active batches / pending schedules)
6. Analytics (charts — NEVER above section 4)
7. Historical Data
```

### Role-Adaptive Dashboard Content

| Section | Admin | Researcher | Farm Manager | Technician | Student |
|---------|-------|-----------|--------------|-----------|---------|
| KPI Tiles | Users, Sensors online, Alerts | Active experiments, KPIs, Students | Active batches, Beds, Technicians | Tasks today, Sensors assigned | Experiments, Observations |
| Quick Action | Add User | Create Experiment | Create Batch | Log Report | Log Observation |
| Active Work | System alerts | My Experiments | Active Batches | Today's Schedules | Assigned Experiments |

---

## VISUAL HIERARCHY RULES

1. Maximum **1 primary CTA** per screen (ElevatedButton)
2. Maximum **2 accent colors** per screen
3. Use whitespace before borders for separation
4. Use typography weight before color for emphasis
5. Charts always appear BELOW actionable cards
6. Sensor alerts always appear at the TOP of any screen

---

## ACCESSIBILITY (MANDATORY)

```dart
// Every interactive widget must have:
Semantics(
  label: 'View Experiment: Tomato Growth Study',
  hint: 'Double tap to open experiment details',
  child: ExperimentCard(...)
)

// Images:
Image.network(url, semanticLabel: 'Sensor graph for Bed A-03')

// Minimum touch target: 48×48
// Minimum contrast: WCAG AA (4.5:1 for body text, 3:1 for large text)
```

---

## PERFORMANCE RULES

```dart
// ALWAYS use const constructors
const SizedBox(height: 16)
const Divider()

// ALWAYS use ListView.builder for lists (never ListView with children for >5 items)
ListView.builder(
  itemCount: experiments.length,
  itemBuilder: (context, index) => ExperimentCard(...),
)

// Use RepaintBoundary for complex widgets
RepaintBoundary(child: SensorChart(...))

// Avoid setState in favor of Riverpod providers
// Avoid MediaQuery in build() — cache in variable
final width = MediaQuery.sizeOf(context).width;
```

---

## CODE QUALITY CHECKLIST

Before generating any screen, verify:

- [ ] No hardcoded colors — use `Theme.of(context).colorScheme` or `AppColors`
- [ ] No hardcoded spacing — use `AppSpacing`
- [ ] No hardcoded text styles — use `Theme.of(context).textTheme`
- [ ] Const constructors used wherever possible
- [ ] Dark mode works (test both themes mentally)
- [ ] ListView.builder used for all lists
- [ ] Each widget file ≤ 150 lines
- [ ] Each screen file ≤ 300 lines
- [ ] Semantic labels on interactive elements
- [ ] GoRouter used for navigation (no Navigator.push)
- [ ] Riverpod used for state (no setState for business logic)
- [ ] Role check before showing sensitive actions

---

## FINAL GENERATION RULE

Before generating any Flutter code:

1. Identify the screen and the user's role
2. Apply design system tokens (colors, spacing, typography)
3. Apply component library (use existing components first)
4. Apply visual hierarchy (alerts → KPIs → actions → analytics)
5. Apply Riverpod pattern (provider → UI consumer)
6. Apply GoRouter navigation
7. Apply accessibility semantics
8. Apply dark mode compatibility
9. Check code quality checklist
10. Generate production-ready code

**Never generate generic Flutter UI.**  
**Always generate SNMS-specific, role-aware, production-grade UI.**
