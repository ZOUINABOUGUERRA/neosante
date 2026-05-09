// lib/routes/responsive_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final currentPath = GoRouterState.of(context).uri.path;

    _updateSelectedIndex(currentPath);

    if (isDesktop) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              _navigateToDestination(index, context);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
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
                label: Text('Backup'),
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
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Dossiers'),
            BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alertes'),
            BottomNavigationBarItem(icon: Icon(Icons.assistant), label: 'AI'),
          ],
          onTap: (index) {
            setState(() => _selectedIndex = index);
            _navigateToMobileDestination(index, context);
          },
        ),
      );
    }
  }

  void _updateSelectedIndex(String path) {
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
    }
  }

  void _navigateToDestination(int index, BuildContext context) {
    switch (index) {
      case 0: GoRouter.of(context).go('/dashboard'); break;
      case 1: GoRouter.of(context).go('/dossiers'); break;
      case 2: GoRouter.of(context).go('/alerts'); break;
      case 3: GoRouter.of(context).go('/transfers'); break;
      case 4: GoRouter.of(context).go('/ai-assistant'); break;
      case 5: GoRouter.of(context).go('/backup'); break;
      case 6: GoRouter.of(context).go('/settings'); break;
    }
  }

  void _navigateToMobileDestination(int index, BuildContext context) {
    switch (index) {
      case 0: GoRouter.of(context).go('/dashboard'); break;
      case 1: GoRouter.of(context).go('/dossiers'); break;
      case 2: GoRouter.of(context).go('/alerts'); break;
      case 3: GoRouter.of(context).go('/ai-assistant'); break;
    }
  }
}