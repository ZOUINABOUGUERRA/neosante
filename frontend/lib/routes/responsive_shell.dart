// lib/routes/responsive_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin == true;
    final currentPath = GoRouterState.of(context).uri.path;

    _updateSelectedIndex(currentPath, isAdmin);

    if (isDesktop) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              _navigateToDestination(index, context, isAdmin);
            },
            labelType: NavigationRailLabelType.all,
            destinations: isAdmin
                ? const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people),
                      label: Text('Utilisateurs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.archive),
                      label: Text('Archives'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.backup),
                      label: Text('Sauvegarde'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Paramètres'),
                    ),
                  ]
                : const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.folder),
                      label: Text('Dossiers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.warning),
                      label: Text('Alertes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.swap_horiz),
                      label: Text('Transferts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assistant),
                      label: Text('AI'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.backup),
                      label: Text('Sauvegarde'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Paramètres'),
                    ),
                  ],
          ),
          Expanded(child: widget.child),
        ],
      );
    } else {
      // Mode mobile
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          items: isAdmin
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Utilisateurs',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.archive),
                    label: 'Archives',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Paramètres',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder),
                    label: 'Dossiers',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.warning),
                    label: 'Alertes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assistant),
                    label: 'AI',
                  ),
                ],
          onTap: (index) {
            setState(() => _selectedIndex = index);
            _navigateToMobileDestination(index, context, isAdmin);
          },
        ),
      );
    }
  }

  void _updateSelectedIndex(String path, bool isAdmin) {
    if (isAdmin) {
      if (path.startsWith('/admin/dashboard')) {
        _selectedIndex = 0;
      } else if (path.startsWith('/admin/users')) {
        _selectedIndex = 1;
      } else if (path.startsWith('/admin/archives')) {
        _selectedIndex = 2;
      } else if (path.startsWith('/backup')) {
        _selectedIndex = 3;
      } else if (path.startsWith('/settings')) {
        _selectedIndex = 4;
      } else {
        _selectedIndex = 0;
      }
    } else {
      if (path.startsWith('/dashboard')) {
        _selectedIndex = 0;
      } else if (path.startsWith('/dossiers')) {
        _selectedIndex = 1;
      } else if (path.startsWith('/alerts')) {
        _selectedIndex = 2;
      } else if (path.startsWith('/transfers')) {
        _selectedIndex = 3;
      } else if (path.startsWith('/ai-assistant')) {
        _selectedIndex = 4;
      } else if (path.startsWith('/backup')) {
        _selectedIndex = 5;
      } else if (path.startsWith('/settings')) {
        _selectedIndex = 6;
      } else {
        _selectedIndex = 0;
      }
    }
  }

  void _navigateToDestination(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          GoRouter.of(context).go('/admin/dashboard');
          break;
        case 1:
          GoRouter.of(context).go('/admin/users');
          break;
        case 2:
          GoRouter.of(context).go('/admin/archives');
          break;
        case 3:
          GoRouter.of(context).go('/backup');
          break;
        case 4:
          GoRouter.of(context).go('/settings');
          break;
      }
    } else {
      switch (index) {
        case 0:
          GoRouter.of(context).go('/dashboard');
          break;
        case 1:
          GoRouter.of(context).go('/dossiers');
          break;
        case 2:
          GoRouter.of(context).go('/alerts');
          break;
        case 3:
          GoRouter.of(context).go('/transfers');
          break;
        case 4:
          GoRouter.of(context).go('/ai-assistant');
          break;
        case 5:
          GoRouter.of(context).go('/backup');
          break;
        case 6:
          GoRouter.of(context).go('/settings');
          break;
      }
    }
  }

  void _navigateToMobileDestination(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          GoRouter.of(context).go('/admin/dashboard');
          break;
        case 1:
          GoRouter.of(context).go('/admin/users');
          break;
        case 2:
          GoRouter.of(context).go('/admin/archives');
          break;
        case 3:
          GoRouter.of(context).go('/settings');
          break;
      }
    } else {
      switch (index) {
        case 0:
          GoRouter.of(context).go('/dashboard');
          break;
        case 1:
          GoRouter.of(context).go('/dossiers');
          break;
        case 2:
          GoRouter.of(context).go('/alerts');
          break;
        case 3:
          GoRouter.of(context).go('/ai-assistant');
          break;
      }
    }
  }
}