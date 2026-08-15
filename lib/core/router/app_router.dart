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
import 'package:flutter_application_2/features/ai_scan/presentation/ai_scan_screen.dart';
import 'package:flutter_application_2/features/measurement/presentation/measurement_statistics_screen.dart';
import 'package:flutter_application_2/features/measurement/presentation/growth_chart_screen.dart';
import 'package:flutter_application_2/features/chat/presentation/chat_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_dashboard_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_tasks_screen.dart';
import 'package:flutter_application_2/features/student/presentation/growth_log_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_chat_screen.dart';
import 'package:flutter_application_2/features/student/presentation/student_task_detail_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_dashboard_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_growth_log_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_tasks_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_report_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_iot_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_task_detail_screen.dart';
import 'package:flutter_application_2/features/technician/presentation/technician_chat_screen.dart';
import 'package:flutter_application_2/core/theme/app_animation.dart';
import 'package:flutter_application_2/shared/models/user_model.dart';

String _initialRouteForRole(UserRole role) => switch (role) {
  UserRole.researcher => '/dashboard',
  UserRole.student   => '/student/dashboard',
  UserRole.technician => '/tech/dashboard',
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState is AuthAuthenticated;
      final isSplashRoute = state.matchedLocation == '/splash';
      final isIntroRoute  = state.matchedLocation == '/intro';
      final isLoginRoute  = state.matchedLocation == '/login';
      if (isSplashRoute || isIntroRoute) return null;
      if (!isLoggedIn && !isLoginRoute) return '/splash';
      if (isLoggedIn && isLoginRoute) {
        final role = authState.user.role;
        return _initialRouteForRole(role);
      }
      if (isLoggedIn &&
          (state.matchedLocation == '/splash' ||
           state.matchedLocation == '/intro')) {
        return '/login';
      }
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
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

      // ── RESEARCHER ───────────────────────────────────────────────────────
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
                  child: const Scaffold(
                    body: MainShell(
                      child: ExperimentListScreen(analyticsMode: true),
                    ),
                  ),
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
                      final expId = state.uri.queryParameters['expId'] ??
                          state.pathParameters['id'];
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

      // ── AI Scan (shared) ─────────────────────────────────────────────────
      GoRoute(
        path: '/ai-scan',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: MainShell(child: AiScanScreen())),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),

      // ── Measurement Statistics ────────────────────────────────────────
      GoRoute(
        path: '/dashboard/statistics/:stageId',
        pageBuilder: (context, state) {
          final stageId = state.pathParameters['stageId']!;
          final stageName = state.uri.queryParameters['stageName'] ?? 'Thống kê';
          return CustomTransitionPage(
            key: state.pageKey,
            child: MeasurementStatisticsScreen(
              stageId: stageId,
              stageName: stageName,
            ),
            transitionsBuilder: _slideTransition,
            transitionDuration: AppDuration.page,
          );
        },
      ),

      // ── Growth Chart (xem chỉ số tăng trưởng theo batch) ─────────────
      GoRoute(
        path: '/growth/:batchId',
        pageBuilder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          final batchCode = state.uri.queryParameters['batchCode'];
          final experimentId = state.uri.queryParameters['experimentId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: GrowthChartScreen(
              batchId: batchId,
              batchCode: batchCode,
              experimentId: experimentId,
            ),
            transitionsBuilder: _slideTransition,
            transitionDuration: AppDuration.page,
          );
        },
      ),

      // ── STUDENT ───────────────────────────────────────────────────────
      GoRoute(
        path: '/student/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: StudentDashboardScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/tasks',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: StudentTasksScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/tasks/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: StudentTaskDetailScreen(
            taskId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/growth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: GrowthLogScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/student/chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: StudentChatScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),

      // ── TECHNICIAN ───────────────────────────────────────────────────
      GoRoute(
        path: '/tech/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: TechnicianDashboardScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/tasks',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: TechnicianTasksScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/tasks/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: TechnicianTaskDetailScreen(
            taskId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/report',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: TechnicianReportScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/chat',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: TechnicianChatScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/iot',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: TechnicianIoTScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
      GoRoute(
        path: '/tech/growth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: MainShell(child: TechnicianGrowthLogScreen()),
          ),
          transitionsBuilder: _slideTransition,
          transitionDuration: AppDuration.page,
        ),
      ),
    ],
  );
});

// ── Transitions ────────────────────────────────────────────────────────────────

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
