import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../theme/colors.dart';

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {

  // ================= INDEX MAPPING =================
  int _getSelectedIndex(String location, bool isAdmin) {
    if (isAdmin) {
      const adminRoutes = {
        '/admin/dashboard': 0,
        '/admin/users': 1,
        '/admin/archives': 2,
        '/backup': 3,
        '/settings': 4,
      };
      return adminRoutes[location] ?? 0;
    } else {
      const sageFemmeRoutes = {
        '/dashboard': 0,
        '/dossiers': 1,
        '/alerts': 2,
        '/transfers': 3,
        '/ai-assistant': 4,
        '/backup': 5,
        '/settings': 6,
        '/notifications': 7,
      };
      return sageFemmeRoutes[location] ?? 0;
    }
  }

  // ================= DESKTOP NAV =================
  void _navigateToDesktop(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go('/admin/dashboard');
          break;
        case 1:
          context.go('/admin/users');
          break;
        case 2:
          context.go('/admin/archives');
          break;
        case 3:
          context.go('/backup');
          break;
        case 4:
          context.go('/settings');
          break;
        default:
          context.go('/admin/dashboard');
      }
    } else {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/dossiers');
          break;
        case 2:
          context.go('/alerts');
          break;
        case 3:
          context.go('/transfers');
          break;
        case 4:
          context.go('/ai-assistant');
          break;
        case 5:
          context.go('/backup');
          break;
        case 6:
          context.go('/settings');
          break;
        case 7:
          context.go('/notifications');
          break;
        default:
          context.go('/dashboard');
      }
    }
  }

  // ================= MOBILE NAV =================
  void _navigateToMobile(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {

      // ❌ FIX: admin has 5 items not 4
      if (index > 4) index = 0;

      switch (index) {
        case 0:
          context.go('/admin/dashboard');
          break;
        case 1:
          context.go('/admin/users');
          break;
        case 2:
          context.go('/admin/archives');
          break;
        case 3:
          context.go('/backup');
          break;
        case 4:
          context.go('/settings');
          break;
        default:
          context.go('/admin/dashboard');
      }

    } else {

      // ❌ FIX: mismatch safe bound
      if (index > 3) index = 0;

      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/dossiers');
          break;
        case 2:
          context.go('/alerts');
          break;
        case 3:
          context.go('/ai-assistant');
          break;
        default:
          context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {

        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isDesktop = width >= 1200;

        // ❌ FIX IMPORTANT: correct GoRouter state usage
        final location = GoRouterState.of(context).uri.toString();

        return Consumer(
          builder: (context, ref, _) {

            final user = ref.watch(authProvider).user;
            final isAdmin = user?.role == AppConstants.roleAdmin;

            final selectedIndex = _getSelectedIndex(location, isAdmin);

            // ================= MOBILE =================
            if (isMobile) {

              int safeIndex = selectedIndex;

              if (isAdmin) {
                if (safeIndex < 0 || safeIndex > 4) safeIndex = 0;
              } else {
                if (safeIndex < 0 || safeIndex > 3) safeIndex = 0;
              }

              return Scaffold(
                body: widget.child,

                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: safeIndex,
                  selectedItemColor: AppColors.medicalBlue,
                  unselectedItemColor: Colors.grey,
                  backgroundColor: Colors.white,

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
                            icon: Icon(Icons.backup),
                            label: 'Sauvegarde',
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
                    _navigateToMobile(index, context, isAdmin);
                  },
                ),
              );
            }

            // ================= DESKTOP =================
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  extended: isDesktop,
                  minExtendedWidth: 200,
                  backgroundColor: Colors.white,

                  destinations: isAdmin
                      ? _buildAdminDestinations()
                      : _buildSageFemmeDestinations(),

                  onDestinationSelected: (index) {
                    _navigateToDesktop(index, context, isAdmin);
                  },
                ),

                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: widget.child,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= ADMIN RAIL =================
  List<NavigationRailDestination> _buildAdminDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        selectedIcon: Icon(Icons.dashboard, color: AppColors.medicalBlue),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people),
        selectedIcon: Icon(Icons.people, color: AppColors.medicalBlue),
        label: Text('Utilisateurs'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.archive),
        selectedIcon: Icon(Icons.archive, color: AppColors.medicalBlue),
        label: Text('Archives'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.backup),
        selectedIcon: Icon(Icons.backup, color: AppColors.medicalBlue),
        label: Text('Sauvegarde'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings),
        selectedIcon: Icon(Icons.settings, color: AppColors.medicalBlue),
        label: Text('Paramètres'),
      ),
    ];
  }

  // ================= USER RAIL =================
  List<NavigationRailDestination> _buildSageFemmeDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        selectedIcon: Icon(Icons.dashboard, color: AppColors.medicalBlue),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.folder),
        selectedIcon: Icon(Icons.folder, color: AppColors.medicalBlue),
        label: Text('Dossiers'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.warning),
        selectedIcon: Icon(Icons.warning, color: AppColors.medicalBlue),
        label: Text('Alertes'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.swap_horiz),
        selectedIcon: Icon(Icons.swap_horiz, color: AppColors.medicalBlue),
        label: Text('Transferts'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assistant),
        selectedIcon: Icon(Icons.assistant, color: AppColors.medicalBlue),
        label: Text('AI'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.backup),
        selectedIcon: Icon(Icons.backup, color: AppColors.medicalBlue),
        label: Text('Sauvegarde'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings),
        selectedIcon: Icon(Icons.settings, color: AppColors.medicalBlue),
        label: Text('Paramètres'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.notifications),
        selectedIcon: Icon(Icons.notifications, color: AppColors.medicalBlue),
        label: Text('Notifications'),
      ),
    ];
  }
}