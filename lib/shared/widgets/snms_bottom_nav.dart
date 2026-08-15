import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_animation.dart';

/// SNMS Bottom Navigation — Material 3 pill indicator style.
///
/// Tham khảo: pill highlight cho selected item (background màu primary,
/// icon trắng, label đậm), label luôn hiển thị, spacing rộng giữa các tab,
/// background trắng + shadow nhẹ phía trên.
class SNMSBottomNav extends StatelessWidget {
  const SNMSBottomNav({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final UserRole role;
  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  // -------------------- DESTINATIONS per role --------------------

  List<NavigationDestination> get _destinations {
    switch (role) {
      case UserRole.researcher:
        return [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.dashboard_rounded),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.science_rounded),
            ),
            label: 'Experiments',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.task_alt_rounded),
            ),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.smart_toy_rounded),
            ),
            label: 'AI Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.chat_rounded),
            ),
            label: 'Chat',
          ),
        ];
      case UserRole.student:
        return [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.dashboard_rounded),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.task_alt_rounded),
            ),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.smart_toy_rounded),
            ),
            label: 'AI Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_rounded),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.trending_up_rounded),
            ),
            label: 'Growth',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.chat_rounded),
            ),
            label: 'Chat',
          ),
        ];
      case UserRole.technician:
        return [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.dashboard_rounded),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.task_alt_rounded),
            ),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.sensors_rounded),
            ),
            label: 'IoT',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.smart_toy_rounded),
            ),
            label: 'AI Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 26),
              child: Icon(Icons.chat_rounded),
            ),
            label: 'Chat',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Shadow mềm phía trên, tone primary
    final topShadow = isDark
        ? Colors.black.withAlpha(60)
        : AppColors.primary.withAlpha(10);

    // Background bar hơi tint primary
    final barBg = isDark ? cs.surface : Colors.white;

    return Semantics(
      label: 'Bottom navigation bar',
      child: Container(
        decoration: BoxDecoration(
          color: barBg,
          boxShadow: [
            BoxShadow(
              color: topShadow,
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            // Pill (stadium) indicator — kính hơn border radius cố định
            indicatorShape: const StadiumBorder(),
            indicatorColor: AppColors.primary,
            height: 72,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : cs.onSurfaceVariant,
                letterSpacing: 0.2,
                height: 1.1,
              );
            }),
            destinations: _destinations,
            animationDuration: AppDuration.normal,
          ),
        ),
      ),
    );
  }
}
