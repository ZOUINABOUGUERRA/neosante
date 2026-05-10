import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'config/firebase_options.dart';  // ✅ إضافة استيراد إعدادات Firebase
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dossiers/screens/dossier_list_screen.dart';
import 'features/dossiers/screens/create_dossier_screen.dart';
import 'features/dossiers/screens/dossier_detail_screen.dart';
import 'features/alerts/screens/alert_center_screen.dart';
import 'features/transfers/screens/transfer_requests_screen.dart';
import 'features/ai_assistant/screens/ai_assistant_screen.dart';
import 'features/backup/screens/backup_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'routes/route_guard.dart';
import 'routes/responsive_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase مع الإعدادات الصحيحة
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveOfflineBox);
  await Hive.openBox(AppConstants.hiveSyncQueueBox);

  runApp(const ProviderScope(child: NeoSanteApp()));
}

class NeoSanteApp extends ConsumerStatefulWidget {
  const NeoSanteApp({super.key});

  @override
  ConsumerState<NeoSanteApp> createState() => _NeoSanteAppState();
}

class _NeoSanteAppState extends ConsumerState<NeoSanteApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
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
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NéoSanté',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B7A78)),
      ),
      routerConfig: _router,
    );
  }
}