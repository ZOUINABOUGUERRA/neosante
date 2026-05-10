import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_guard.dart';
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/admin_archive_screen.dart';
import '../features/admin/screens/user_management_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/dossiers/screens/dossier_list_screen.dart';
import '../features/dossiers/screens/create_dossier_screen.dart';
import '../features/dossiers/screens/dossier_detail_screen.dart';
import '../features/alerts/screens/alert_center_screen.dart';
import '../features/transfers/screens/transfer_requests_screen.dart';
import '../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../features/backup/screens/backup_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/auth/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authGuard = ref.read(authGuardProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => authGuard.redirect(state),
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          // 📌 Routes pour les sages‑femmes (et aussi admin pour certaines)
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/dossiers',
            name: 'dossiers',
            builder: (context, state) => const DossierListScreen(),
          ),
          GoRoute(
            path: '/dossiers/create',
            name: 'create_dossier',
            builder: (context, state) => const CreateDossierScreen(),
          ),
          GoRoute(
            path: '/dossiers/:id',
            name: 'dossier_detail',
            builder: (context, state) => DossierDetailScreen(
              dossierId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (context, state) => const AlertCenterScreen(),
          ),
          GoRoute(
            path: '/transfers',
            name: 'transfers',
            builder: (context, state) => const TransferRequestsScreen(),
          ),
          GoRoute(
            path: '/ai-assistant',
            name: 'ai_assistant',
            builder: (context, state) => const AIAssistantScreen(),
          ),
          GoRoute(
            path: '/backup',
            name: 'backup',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          // 📌 Routes spécifiques à l'administrateur
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin_dashboard',
            builder: (context, state) => const AdminDashboard(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin_users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/archives',
            name: 'admin_archives',
            builder: (context, state) => const AdminArchiveScreen(),
          ),
        ],
      ),
    ],
  );
});

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  /// Retourne l'index sélectionné en fonction du chemin et du rôle
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
      };
      return sageFemmeRoutes[location] ?? 0;
    }
  }

  void _navigateToDesktop(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0: context.go('/admin/dashboard'); break;
        case 1: context.go('/admin/users'); break;
        case 2: context.go('/admin/archives'); break;
        case 3: context.go('/backup'); break;
        case 4: context.go('/settings'); break;
      }
    } else {
      switch (index) {
        case 0: context.go('/dashboard'); break;
        case 1: context.go('/dossiers'); break;
        case 2: context.go('/alerts'); break;
        case 3: context.go('/transfers'); break;
        case 4: context.go('/ai-assistant'); break;
        case 5: context.go('/backup'); break;
        case 6: context.go('/settings'); break;
      }
    }
  }

  void _navigateToMobile(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0: context.go('/admin/dashboard'); break;
        case 1: context.go('/admin/users'); break;
        case 2: context.go('/admin/archives'); break;
        case 3: context.go('/settings'); break;
      }
    } else {
      switch (index) {
        case 0: context.go('/dashboard'); break;
        case 1: context.go('/dossiers'); break;
        case 2: context.go('/alerts'); break;
        case 3: context.go('/ai-assistant'); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final location = GoRouterState.of(context).uri.path;

    // Récupération du rôle de l'utilisateur courant
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(authProvider).user;
        final isAdmin = user?.isAdmin == true;
        final selectedIndex = _getSelectedIndex(location, isAdmin);

        if (isDesktop) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                extended: true,
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
                onDestinationSelected: (index) {
                  _navigateToDesktop(index, context, isAdmin);
                },
              ),
              Expanded(child: child),
            ],
          );
        } else {
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedIndex,
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
                _navigateToMobile(index, context, isAdmin);
              },
            ),
          );
        }
      },
    );
  }
}