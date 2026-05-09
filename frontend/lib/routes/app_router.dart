import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_guard.dart';
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
        ],
      ),
    ],
  );
});

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  int getSelectedIndex(String location) {
    const routes = {
      '/dashboard': 0,
      '/dossiers': 1,
      '/alerts': 2,
      '/transfers': 3,
      '/ai-assistant': 4,
      '/backup': 5,
      '/settings': 6,
    };

    return routes[location] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final location = GoRouterState.of(context).uri.path;
    final index = getSelectedIndex(location);

    if (isDesktop) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            extended: true,
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
                label: Text('Sauvegarde'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Paramètres'),
              ),
            ],
            onDestinationSelected: (index) {
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
              }
            },
          ),
          Expanded(child: child),
        ],
      );
    } else {
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          items: const [
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
            }
          },
        ),
      );
    }
  }
}