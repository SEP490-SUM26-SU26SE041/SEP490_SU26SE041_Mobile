import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/snms_bottom_nav.dart';
import '../../auth/providers/auth_provider.dart';

final currentNavIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  // Routes per role — keep in sync with snms_bottom_nav.dart destination count.
  // Notify removed across all roles (per design).
  List<String> _routesForRole(UserRole role) {
    switch (role) {
      // Researcher không được hỗ trợ trên mobile — fallback về student routes.
      // Router đã tự động logout researcher về /login nên thường không vào đây.
      case UserRole.researcher:
        return const [
          '/student/dashboard',
          '/student/tasks',
          '/ai-scan',
          '/student/growth',
          '/student/chat',
        ];
      case UserRole.student:
        return [
          '/student/dashboard',
          '/student/tasks',
          '/ai-scan',
          '/student/growth',
          '/student/chat',
        ];
      case UserRole.technician:
        return [
          '/tech/dashboard',
          '/tech/tasks',
          '/ai-scan',
          '/tech/chat',
        ];
    }
  }

  void _onDestinationSelected(BuildContext context, int index, UserRole role) {
    final routes = _routesForRole(role);
    if (index < routes.length) {
      context.go(routes[index]);
    }
  }

  int _getIndexFromLocation(String location, UserRole role) {
    final routes = _routesForRole(role);
    for (int i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    // Default: Student (Researcher không được hỗ trợ trên mobile)
    final role = currentUser?.role ?? UserRole.student;
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getIndexFromLocation(location, role);

    return Scaffold(
      body: child,
      bottomNavigationBar: SNMSBottomNav(
        role: role,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index, role),
      ),
    );
  }
}
