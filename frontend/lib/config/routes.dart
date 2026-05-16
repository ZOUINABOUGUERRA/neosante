import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/dossiers/screens/dossier_list_screen.dart';
import '../features/dossiers/screens/create_dossier_screen.dart';
import '../features/dossiers/screens/dossier_detail_screen.dart';
import '../features/alerts/screens/alert_center_screen.dart';
import '../features/transfers/screens/transfer_requests_screen.dart';
import '../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../features/backup/screens/backup_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../routes/route_guard.dart';
import '../theme/colors.dart';

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
        builder: (context, state, child) {
          return ResponsiveShell(child: child);
        },
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
            builder: (context, state) =>
                DossierDetailScreen(dossierId: state.pathParameters['id']!),
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

class ResponsiveShell extends ConsumerStatefulWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ تحديث selectedIndex عند تغيير المسار
    final currentPath = GoRouterState.of(context).matchedLocation;
    _updateSelectedIndex(currentPath);
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
  }

  int _getMobileSelectedIndex(String path) {
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/dossiers')) return 1;
    if (path.startsWith('/alerts')) return 2;
    if (path.startsWith('/ai-assistant')) return 3;
    return 0;
  }

  void _navigateToMobileDestination(int index, BuildContext context) {
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
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // ✅ تحديث selectedIndex في كل بناء
    _updateSelectedIndex(currentPath);

    if (isDesktop) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _navigateToDestination(index, context);
            },
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('📊 Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder),
                label: Text('📋 Dossiers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning),
                label: Text('⚠️ Alertes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.swap_horiz),
                label: Text('🚑 Transferts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assistant),
                label: Text('🧠 AI'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.backup),
                label: Text('💾 Sauvegarde'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('⚙️ Paramètres'),
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
          currentIndex: _getMobileSelectedIndex(currentPath),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.medicalBlue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: '🏠 Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: '📋 Dossiers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning),
              label: '⚠️ Alertes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assistant),
              label: '🧠 AI',
            ),
          ],
          onTap: (index) {
            _navigateToMobileDestination(index, context);
          },
        ),
      );
    }
  }
}
