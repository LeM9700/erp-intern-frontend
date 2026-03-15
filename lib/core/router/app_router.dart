import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:erp_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:erp_frontend/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:erp_frontend/features/dashboard/presentation/screens/intern_dashboard_screen.dart';
import 'package:erp_frontend/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:erp_frontend/features/tasks/presentation/screens/admin_tasks_screen.dart';
import 'package:erp_frontend/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:erp_frontend/features/attendance/presentation/screens/admin_attendance_screen.dart';
import 'package:erp_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:erp_frontend/features/users/presentation/screens/admin_users_screen.dart';
import 'package:erp_frontend/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:erp_frontend/core/router/shell_screen.dart';

// Route names
class AppRoutes {
  static const login = '/login';
  static const adminDashboard = '/admin';
  static const adminTasks = '/admin/tasks';
  static const adminAttendance = '/admin/attendance';
  static const adminUsers = '/admin/users';
  static const adminNotifications = '/admin/notifications';
  static const adminProfile = '/admin/profile';
  static const internDashboard = '/intern';
  static const internTasks = '/intern/tasks';
  static const internAttendance = '/intern/attendance';
  static const internNotifications = '/intern/notifications';
  static const internProfile = '/intern/profile';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoginRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isLoginRoute) {
        return authState.isAdmin
            ? AppRoutes.adminDashboard
            : AppRoutes.internDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Admin Shell ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(
          isAdmin: true,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminTasks,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminTasksScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminAttendance,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminAttendanceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminUsersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminNotifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.adminProfile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Intern Shell ──
      ShellRoute(
        builder: (context, state, child) => ShellScreen(
          isAdmin: false,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.internDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InternDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.internTasks,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TasksScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.internAttendance,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendanceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.internNotifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.internProfile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
