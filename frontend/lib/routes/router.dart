import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_guard.dart';
import 'responsive_shell.dart';

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
import '../features/archives/screens/archive_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authGuard = ref.read(authGuardProvider);

  return GoRouter(
    initialLocation: '/login',

    // ✅ مهم: منع loop بين redirect و login
    redirect: (context, state) {
      return authGuard.redirect(state);
    },

    routes: [
      // ================= PUBLIC =================
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

      // ================= SHELL =================
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveShell(child: child);
        },
        routes: [

          // ========= DASHBOARD =========
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ========= DOSSIERS =========
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
            builder: (context, state) {
              final id = state.pathParameters['id'];
              if (id == null) {
                return const Scaffold(
                  body: Center(child: Text('Invalid dossier ID')),
                );
              }
              return DossierDetailScreen(dossierId: id);
            },
          ),

          // ========= ALERTS =========
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (context, state) => const AlertCenterScreen(),
          ),

          // ========= TRANSFERS =========
          GoRoute(
            path: '/transfers',
            name: 'transfers',
            builder: (context, state) => const TransferRequestsScreen(),
          ),

          // ========= AI =========
          GoRoute(
            path: '/ai-assistant',
            name: 'ai_assistant',
            builder: (context, state) => const AIAssistantScreen(),
          ),

          // ========= BACKUP =========
          GoRoute(
            path: '/backup',
            name: 'backup',
            builder: (context, state) => const BackupScreen(),
          ),

          // ========= SETTINGS =========
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // ========= NOTIFICATIONS =========
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationScreen(),
          ),

          // ========= ARCHIVES =========
          GoRoute(
            path: '/archives',
            name: 'archives',
            builder: (context, state) => const ArchiveScreen(),
          ),

          // ========= ADMIN =========
          GoRoute(
            path: '/admin',
            redirect: (context, state) => '/admin/dashboard',
          ),

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