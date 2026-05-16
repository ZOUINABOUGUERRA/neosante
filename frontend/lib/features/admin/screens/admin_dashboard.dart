import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/colors.dart';
import '../../../services/auth_service.dart';

final adminUsersCountProvider = FutureProvider<int>((ref) async {
  final auth = ref.read(authServiceProvider);
  final users = await auth.getAllUsers();
  return users.length;
});

final adminArchivesCountProvider = FutureProvider<int>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('archives').count().get();
  return snapshot.count ?? 0;
});

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersCount = ref.watch(adminUsersCountProvider);
    final archivesCount = ref.watch(adminArchivesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('👑 Tableau de bord administrateur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.medicalBlue.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Carte de bienvenue
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.medicalBlue, AppColors.lightBlue],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bonjour, Administrateur 👋',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Aperçu général du système',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Statistiques rapides
              const Text(
                '📊 Statistiques rapides',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      title: 'Utilisateurs',
                      count: usersCount,
                      icon: Icons.people,
                      color: AppColors.medicalBlue,
                      onTap: () => context.pushNamed('admin_users'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniCard(
                      title: 'Archives',
                      count: archivesCount,
                      icon: Icons.archive,
                      color: AppColors.warningOrange,
                      onTap: () => context.pushNamed('admin_archives'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      title: 'Sauvegarde',
                      count: const AsyncValue.data(0),
                      icon: Icons.backup,
                      color: AppColors.stableGreen,
                      onTap: () => context.pushNamed('backup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniCard(
                      title: 'Paramètres',
                      count: const AsyncValue.data(0),
                      icon: Icons.settings,
                      color: AppColors.lightBlue,
                      onTap: () => context.go('settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ✅ Actions rapides
              const Text(
                '⚡ Actions rapides',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildActionChip(
                    label: 'Ajouter un utilisateur',
                    icon: Icons.person_add,
                    color: AppColors.medicalBlue,
                    onTap: () => context.pushNamed('admin_users'),
                  ),
                  _buildActionChip(
                    label: 'Créer une sauvegarde',
                    icon: Icons.backup,
                    color: AppColors.stableGreen,
                    onTap: () => context.pushNamed('backup'),
                  ),
                  _buildActionChip(
                    label: 'Voir les archives',
                    icon: Icons.archive,
                    color: AppColors.warningOrange,
                    onTap: () => context.pushNamed('admin_archives'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Carte miniature
  Widget _buildMiniCard({
    required String title,
    required AsyncValue<int> count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            count.when(
              data: (value) => Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) =>
                  const Text('Erreur', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Action Chip
  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: color),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
