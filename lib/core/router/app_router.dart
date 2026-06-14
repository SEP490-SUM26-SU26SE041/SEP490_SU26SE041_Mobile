import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_2/features/auth/presentation/login_screen.dart';
import 'package:flutter_application_2/features/auth/presentation/intro_screen.dart';
import 'package:flutter_application_2/features/auth/presentation/splash_screen.dart';
import 'package:flutter_application_2/features/auth/providers/auth_provider.dart';
import 'package:flutter_application_2/features/dashboard/presentation/main_shell.dart';
import 'package:flutter_application_2/features/dashboard/presentation/researcher_dashboard_screen.dart';
import 'package:flutter_application_2/features/experiments/presentation/experiment_list_screen.dart';
import 'package:flutter_application_2/features/experiments/presentation/experiment_detail_screen.dart';
import 'package:flutter_application_2/features/experiments/presentation/create_experiment_request_screen.dart';
import 'package:flutter_application_2/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter_application_2/features/tasks/presentation/create_task_screen.dart';
import 'package:flutter_application_2/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter_application_2/features/chat/presentation/chat_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_dashboard_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_tasks_screen.dart';
import 'package:flutter_application_2/features/student/presentation/growth_log_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_chat_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_dashboard_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_tasks_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_report_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_iot_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_task_detail_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_task_detail_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_chat_screen.dart';
import 'package:flutter_application_2/features/farm_manager/presentation/farm_manager_dashboard_screen.dart';
import 'package:flutter_application_2/features/farm_manager/presentation/farm_map_screen.dart';
import 'package:flutter_application_2/features/farm_manager/presentation/request_review_screen.dart';
import 'package:flutter_application_2/features/farm_manager/presentation/approved_experiments_screen.dart';
import 'package:flutter_application_2/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:flutter_application_2/features/admin/presentation/user_management_screen.dart';
import 'package:flutter_application_2/features/admin/presentation/system_settings_screen.dart';
import 'package:flutter_application_2/core/theme/app_animation.dart';
import 'package:flutter_application_2/shared/models/user_model.dart';

String _initialRouteForRole(UserRole role) => switch (role) {
  UserRole.researcher   => '/dashboard',
  UserRole.student      => '/student/dashboard',
  UserRole.technician   => '/tech/dashboard',
  UserRole.farmManager  => '/fm/dashboard',
  UserRole.admin        => '/admin/dashboard',
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState is AuthAuthenticated;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isIntroRoute = state.matchedLocation == '/intro';
      final isLoginRoute = state.matchedLocation == '/login';
      if (isSplashRoute || isIntroRoute) return null;
      if (!isLoggedIn && !isLoginRoute) return '/splash';
      if (isLoggedIn && isLoginRoute) {
        final role = authState.user.role;
        return _initialRouteForRole(role);
      }
      if (isLoggedIn && (state.matchedLocation == '/splash' || state.matchedLocation == '/intro')) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/intro',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const IntroScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: AppDuration.page,
        ),
      ),

      // ===================== RESEARCHER =====================
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ResearcherDashboardScreen(),
              transitionsBuilder: _slideTransition,
              transitionDuration: AppDuration.page,
            ),
          ),
          GoRoute(
            path: '/experiments',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ExperimentListScreen(),
              transitionsBuilder: _slideTransition,
              transitionDuration: AppDuration.page,
            ),
            routes: [
              GoRoute(
                path: 'analytics',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const Scaffold(body: MainShell(child: ExperimentListScreen(analyticsMode: true))),
                  transitionsBuilder: _slideTransition,
                  transitionDuration: AppDuration.page,
                ),
              ),
              GoRoute(
                path: 'create',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const CreateExperimentRequestScreen(),
                  transitionsBuilder: _slideUpTransition,
                  transitionDuration: AppDuration.page,
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: ExperimentDetailScreen(
                    id: state.pathParameters['id']!,
                    analyticsTab: state.uri.queryParameters['analytics'] == 'true',
                  ),
                  transitionsBuilder: _slideTransition,
                  transitionDuration: AppDuration.page,
                ),
                routes: [
                  GoRoute(
                    path: 'create-task',
                    pageBuilder: (context, state) {
                      final expId = state.uri.queryParameters['expId'] ?? state.pathParameters['id'];
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: CreateTaskScreen(experimentId: expId),
                        transitionsBuilder: _slideUpTransition,
                        transitionDuration: AppDuration.page,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'create-task',
                pageBuilder: (context, state) {
                  final expId = state.uri.queryParameters['expId'];
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: CreateTaskScreen(experimentId: expId),
                    transitionsBuilder: _slideUpTransition,
                    transitionDuration: AppDuration.page,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TasksScreen(),
              transitionsBuilder: _slideTransition,
              transitionDuration: AppDuration.page,
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
              transitionsBuilder: _slideTransition,
              transitionDuration: AppDuration.page,
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ChatScreen(),
              transitionsBuilder: _slideTransition,
              transitionDuration: AppDuration.page,
            ),
          ),
        ],
      ),

      // ===================== STUDENT =====================
      GoRoute(
        path: '/student/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: StudentDashboardScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/tasks',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: StudentTasksScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/tasks/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: StudentTaskDetailScreen(taskId: state.pathParameters['id']!),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/growth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: GrowthLogScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: StudentChatScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),

      // ===================== TECHNICIAN =====================
      GoRoute(
        path: '/tech/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: TechnicianDashboardScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/tasks',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: TechnicianTasksScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/tasks/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: TechnicianTaskDetailScreen(taskId: state.pathParameters['id']!),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/report',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: TechnicianReportScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: TechnicianChatScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/iot',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: TechnicianIoTScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),

      // ===================== FARM MANAGER =====================
      GoRoute(
        path: '/fm/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: FarmManagerDashboardScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/fm/farm-map',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: FarmMapScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/fm/experiments',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: ApprovedExperimentsScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/fm/notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: NotificationsScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/fm/requests',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RequestReviewScreen(),
          transitionsBuilder: _slideUpTransition,
          transitionDuration: AppDuration.page,
        ),
      ),

      // ===================== ADMIN =====================
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: AdminDashboardScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: UserManagementScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: SystemSettingsScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/admin/notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: NotificationsScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
    ],
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: AppCurve.enter).animate(animation),
    child: child,
  );
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
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
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurveTween(curve: AppCurve.enter).animate(animation)),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}
