import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../services/auth_service.dart';
import '../providers/settings_provider.dart';
import '../../../shared/models/user_model.dart';

/// ==========================
/// 🔥 PROVIDER USER MODEL
/// ==========================
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final auth = ref.read(authServiceProvider);
  return auth.getCurrentUserModel();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
      ),

      /// ==========================
      /// 🔥 FIX IMPORTANT
      /// ==========================
      body: userAsync.when(
        data: (user) {
          return ListView(
            children: [
              _buildProfileSection(user),
              const SizedBox(height: 8),
              _buildSectionHeader('Apparence', Icons.palette),
              _buildSwitchTile(
                title: 'Mode sombre',
                subtitle: 'Activer le thème sombre',
                icon: Icons.dark_mode,
                value: settings.isDarkMode,
                onChanged: (value) =>
                    ref.read(settingsProvider.notifier).toggleDarkMode(value),
              ),
              _buildDropdownTile(
                title: 'Taille du texte',
                subtitle: 'Ajuster la taille de la police',
                icon: Icons.text_fields,
                value: settings.fontSize,
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Petite')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'large', child: Text('Grande')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setFontSize(value);
                  }
                },
              ),
              const Divider(height: 32),
              _buildSectionHeader('Notifications', Icons.notifications),
              _buildSwitchTile(
                title: 'Notifications push',
                subtitle: 'Recevoir des notifications',
                icon: Icons.notifications_active,
                value: settings.notificationsEnabled,
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .toggleNotifications(value),
              ),
              const Divider(height: 32),
              _buildSectionHeader('Zone danger', Icons.warning,
                  color: AppColors.emergencyRed),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.emergencyRed),
                title: const Text('Déconnexion',
                    style: TextStyle(color: AppColors.emergencyRed)),
                trailing: _isLoggingOut
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Icon(Icons.logout, color: AppColors.emergencyRed),
                onTap: _logout,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Erreur chargement utilisateur')),
      ),
    );
  }

  /// ==========================
  /// PROFILE SECTION (FIX SAFE)
  /// ==========================
  Widget _buildProfileSection(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.medicalBlue.withValues(alpha: 0.05),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.medicalBlue,
            child: Text(
              user?.initials ?? '?',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Utilisateur',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(user?.email ?? ''),
                Text(
                  user?.isAdmin == true ? 'Administrateur' : 'Sage-Femme',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {Color color = AppColors.medicalBlue}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  /// ==========================
  /// LOGOUT FIX
  /// ==========================
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signOut();

      if (mounted) context.go('/login');
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de la déconnexion');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }
}
