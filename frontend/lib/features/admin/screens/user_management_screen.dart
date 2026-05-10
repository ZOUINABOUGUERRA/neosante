// frontend/lib/features/admin/screens/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_card.dart';
import 'add_user_screen.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../theme/colors.dart';
import '../../../shared/models/user_model.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminUsersProvider);
    final adminNotifier = ref.read(adminUsersProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: Colors.transparent,
        actions: [
          // ✅ Bouton Rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => adminNotifier.refresh(),
            tooltip: 'Rafraîchir',
          ),
          // ✅ Bouton Ajouter un utilisateur (demandé)
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddUserDialog(),
            tooltip: 'Ajouter un utilisateur',
          ),
        ],
      ),
      body: adminState.isLoading
          ? const LoadingWidget(message: 'Chargement des utilisateurs...')
          : adminState.error != null
              ? CustomErrorWidget(
                  message: adminState.error!,
                  onRetry: () => adminNotifier.refresh(),
                )
              : adminState.users.isEmpty
                  ? const Center(child: Text('Aucun utilisateur trouvé'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: adminState.users.length,
                      itemBuilder: (context, index) {
                        final user = adminState.users[index];
                        return UserCard(
                          user: user,
                          onEdit: () => _showEditUserDialog(user),
                          onToggleStatus: () => _toggleUserStatus(adminNotifier, user),
                          onResetPassword: () => _resetPassword(adminNotifier, user),
                          onDelete: () => _deleteUser(adminNotifier, user),
                        );
                      },
                    ),
    );
  }

  // Affiche le dialogue d'ajout d'utilisateur
  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddUserScreen(),
    ).then((_) {
      // Rafraîchit la liste après la fermeture du dialogue
      ref.read(adminUsersProvider.notifier).refresh();
    });
  }

  // Affiche le dialogue de modification du rôle
  void _showEditUserDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Modifier le rôle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Sage-femme'),
              leading: Radio<String>(
                value: 'sage-femme',
                groupValue: user.role,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await ref.read(adminUsersProvider.notifier).updateUserRole(user.id, value!);
                  if (mounted) context.showSuccessSnackBar('Rôle modifié');
                },
              ),
            ),
            ListTile(
              title: const Text('Administrateur'),
              leading: Radio<String>(
                value: 'admin',
                groupValue: user.role,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await ref.read(adminUsersProvider.notifier).updateUserRole(user.id, value!);
                  if (mounted) context.showSuccessSnackBar('Rôle modifié');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Activer / Désactiver un compte
  Future<void> _toggleUserStatus(AdminUsersNotifier notifier, UserModel user) async {
    final confirmed = await context.showConfirmationDialog(
      title: user.isActive ? 'Désactiver le compte' : 'Activer le compte',
      message: user.isActive
          ? 'Êtes-vous sûr de vouloir désactiver le compte de ${user.fullName} ?'
          : 'Êtes-vous sûr de vouloir réactiver le compte de ${user.fullName} ?',
      confirmText: user.isActive ? 'Désactiver' : 'Activer',
    );
    if (confirmed != true) return;

    final success = await notifier.toggleUserStatus(user.id, !user.isActive);
    if (mounted && success) {
      context.showSuccessSnackBar(
        user.isActive ? 'Compte désactivé' : 'Compte activé',
      );
    }
  }

  // Envoyer un email de réinitialisation du mot de passe
  Future<void> _resetPassword(AdminUsersNotifier notifier, UserModel user) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Réinitialiser le mot de passe',
      message: 'Un email de réinitialisation sera envoyé à ${user.email}. Continuer ?',
      confirmText: 'Envoyer',
    );
    if (confirmed != true) return;

    final success = await notifier.resetPassword(user.email);
    if (mounted && success) {
      context.showSuccessSnackBar('Email envoyé à ${user.email}');
    }
  }

  // Supprimer définitivement un compte (uniquement pour les non‑admin)
  Future<void> _deleteUser(AdminUsersNotifier notifier, UserModel user) async {
    if (user.isAdmin) {
      context.showErrorSnackBar('Impossible de supprimer le compte administrateur principal');
      return;
    }

    final confirmed = await context.showConfirmationDialog(
      title: 'Supprimer le compte',
      message: '⚠️ Cette action est irréversible.\n\nSupprimer définitivement le compte de ${user.fullName} ?',
      confirmText: 'Supprimer',
      confirmColor: AppColors.emergencyRed,
    );
    if (confirmed != true) return;

    final success = await notifier.deleteUser(user.id);
    if (mounted && success) {
      context.showSuccessSnackBar('Compte supprimé');
    }
  }
}