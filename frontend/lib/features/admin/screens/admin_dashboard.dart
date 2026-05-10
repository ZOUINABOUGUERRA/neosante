// lib/features/admin/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../services/auth_service.dart';
import '../widgets/admin_stats_card.dart';

final adminUsersCountProvider = FutureProvider<int>((ref) async {
  final auth = ref.read(authServiceProvider);
  final users = await auth.getAllUsers();
  return users.length;
});

final adminArchivesCountProvider = FutureProvider<int>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('archives').count().get();
  return snapshot.count;
});

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersCount = ref.watch(adminUsersCountProvider);
    final archivesCount = ref.watch(adminArchivesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord - Admin'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue, Administrateur',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gestion du système',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                AdminStatsCard(
                  title: 'Utilisateurs',
                  count: usersCount,
                  icon: Icons.people,
                  color: AppColors.medicalBlue,
                  onTap: () => context.pushNamed('/admin/users'),
                ),
                AdminStatsCard(
                  title: 'Archives',
                  count: archivesCount,
                  icon: Icons.archive,
                  color: AppColors.warningOrange,
                  onTap: () => context.pushNamed('/admin/archives'),
                ),
                AdminStatsCard(
                  title: 'Sauvegarde',
                  count: const AsyncValue.data(0),
                  icon: Icons.backup,
                  color: AppColors.stableGreen,
                  onTap: () => context.pushNamed('/backup'),
                ),
                AdminStatsCard(
                  title: 'Paramètres',
                  count: const AsyncValue.data(0),
                  icon: Icons.settings,
                  color: AppColors.lightBlue,
                  onTap: () => context.pushNamed('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}