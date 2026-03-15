import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_frontend/core/router/app_router.dart';
import 'package:erp_frontend/features/notifications/presentation/providers/notification_provider.dart';

class ShellScreen extends ConsumerWidget {
  final bool isAdmin;
  final Widget child;

  const ShellScreen({
    super.key,
    required this.isAdmin,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(currentLocation),
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations:
            isAdmin ? _adminDestinations(unreadCount) : _internDestinations(unreadCount),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (isAdmin) {
      if (location.startsWith(AppRoutes.adminTasks)) return 1;
      if (location.startsWith(AppRoutes.adminAttendance)) return 2;
      if (location.startsWith(AppRoutes.adminUsers)) return 3;
      if (location.startsWith(AppRoutes.adminNotifications)) return 4;
      if (location.startsWith(AppRoutes.adminProfile)) return 5;
      return 0;
    } else {
      if (location.startsWith(AppRoutes.internTasks)) return 1;
      if (location.startsWith(AppRoutes.internAttendance)) return 2;
      if (location.startsWith(AppRoutes.internNotifications)) return 3;
      if (location.startsWith(AppRoutes.internProfile)) return 4;
      return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go(AppRoutes.adminDashboard);
        case 1:
          context.go(AppRoutes.adminTasks);
        case 2:
          context.go(AppRoutes.adminAttendance);
        case 3:
          context.go(AppRoutes.adminUsers);
        case 4:
          context.go(AppRoutes.adminNotifications);
        case 5:
          context.go(AppRoutes.adminProfile);
      }
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.internDashboard);
        case 1:
          context.go(AppRoutes.internTasks);
        case 2:
          context.go(AppRoutes.internAttendance);
        case 3:
          context.go(AppRoutes.internNotifications);
        case 4:
          context.go(AppRoutes.internProfile);
      }
    }
  }

  List<NavigationDestination> _adminDestinations(int unreadCount) => [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.task_outlined),
          selectedIcon: Icon(Icons.task),
          label: 'Tâches',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: 'Présences',
        ),
        const NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Stagiaires',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications),
          ),
          label: 'Notifs',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];

  List<NavigationDestination> _internDestinations(int unreadCount) => [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.task_outlined),
          selectedIcon: Icon(Icons.task),
          label: 'Tâches',
        ),
        const NavigationDestination(
          icon: Icon(Icons.access_time_outlined),
          selectedIcon: Icon(Icons.access_time_filled),
          label: 'Pointage',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.notifications),
          ),
          label: 'Notifs',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
}
