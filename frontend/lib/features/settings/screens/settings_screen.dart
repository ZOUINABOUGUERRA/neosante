import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../services/auth_service.dart';
import '../providers/settings_provider.dart';
import '../../../shared/models/user_model.dart';

/// Provider for current user model
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          return isDesktop
              ? _buildDesktopLayout(settings, user)
              : _buildMobileLayout(settings, user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('❌ Erreur chargement utilisateur: ${e.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserModelProvider),
                child: const Text('🔄 Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(SettingsState settings, UserModel? user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Sidebar navigation (desktop)
        Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              _buildProfileCard(user),
              const SizedBox(height: 24),
              _buildSidebarItem('👤 Profil', Icons.person, 0, isSelected: true),
              _buildSidebarItem('🎨 Apparence', Icons.palette, 1),
              _buildSidebarItem('🔔 Notifications', Icons.notifications, 2),
              if (user?.isAdmin == true)
                _buildSidebarItem(
                  '🛡️ Administration',
                  Icons.admin_panel_settings,
                  3,
                ),
              _buildSidebarItem(
                '⚠️ Sécurité',
                Icons.warning,
                4,
                color: AppColors.emergencyRed,
              ),
            ],
          ),
        ),
        // ✅ Content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildSettingsSection(settings, user)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(SettingsState settings, UserModel? user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileCard(user),
        const SizedBox(height: 16),
        _buildSettingsSection(settings, user),
      ],
    );
  }

  Widget _buildProfileCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.medicalBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.medicalBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.medicalBlue,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.isAdmin == true
                        ? '👑 Administrateur'
                        : '👩‍⚕️ Sage-Femme',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon,
    int index, {
    bool isSelected = false,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.medicalBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? itemColor : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? itemColor : Colors.grey.shade700,
          ),
        ),
        tileColor: isSelected ? itemColor.withValues(alpha: 0.1) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {},
      ),
    );
  }

  Widget _buildSettingsSection(SettingsState settings, UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎨 Apparence Section
        _buildSectionCard(
          title: '🎨 Apparence',
          icon: Icons.palette,
          children: [
            _buildModernSwitchTile(
              title: '🌙 Mode sombre',
              subtitle: 'Activer le thème sombre',
              icon: Icons.dark_mode,
              value: settings.isDarkMode,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).toggleDarkMode(value),
            ),
            const Divider(height: 1),
            _buildModernDropdownTile(
              title: '🔤 Taille du texte',
              subtitle: 'Ajuster la taille de la police',
              icon: Icons.text_fields,
              value: settings.fontSize,
              items: const [
                DropdownMenuItem(value: 'small', child: Text('📘 Petite')),
                DropdownMenuItem(value: 'medium', child: Text('📙 Moyenne')),
                DropdownMenuItem(value: 'large', child: Text('📕 Grande')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFontSize(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 🔔 Notifications Section
        _buildSectionCard(
          title: '🔔 Notifications',
          icon: Icons.notifications,
          children: [
            _buildModernSwitchTile(
              title: '📱 Notifications push',
              subtitle: 'Recevoir des notifications',
              icon: Icons.notifications_active,
              value: settings.notificationsEnabled,
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .toggleNotifications(value),
            ),
            const Divider(height: 1),
            _buildModernSwitchTile(
              title: '🚨 Alertes médicales',
              subtitle: 'Recevoir les alertes critiques',
              icon: Icons.warning,
              value: settings.medicalAlertsEnabled,
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .toggleMedicalAlerts(value),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 💾 Backup Section
        _buildSectionCard(
          title: '💾 Sauvegarde',
          icon: Icons.backup,
          children: [
            _buildModernSwitchTile(
              title: '☁️ Sauvegarde automatique',
              subtitle: 'Sauvegarder automatiquement les données',
              icon: Icons.cloud_upload,
              value: settings.autoBackupEnabled,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).toggleAutoBackup(value),
            ),
            if (settings.autoBackupEnabled) ...[
              const Divider(height: 1),
              _buildModernDropdownTile(
                title: '📅 Fréquence',
                subtitle: 'Intervalle entre les sauvegardes',
                icon: Icons.calendar_today,
                value: settings.autoBackupFrequency,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('📆 Chaque semaine')),
                  DropdownMenuItem(value: 14, child: Text('📆 14 jours')),
                  DropdownMenuItem(value: 30, child: Text('📆 Chaque mois')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setAutoBackupFrequency(value);
                  }
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // 📡 Offline Section
        _buildSectionCard(
          title: '📡 Mode hors ligne',
          icon: Icons.offline_bolt,
          children: [
            _buildModernSwitchTile(
              title: '📱 Mode hors ligne',
              subtitle: 'Accéder aux données sans connexion',
              icon: Icons.cloud_off,
              value: settings.offlineModeEnabled,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).toggleOfflineMode(value),
            ),
            const Divider(height: 1),
            _buildModernSwitchTile(
              title: '📶 Synchronisation Wi-Fi uniquement',
              subtitle: 'Économiser les données mobiles',
              icon: Icons.wifi,
              value: settings.syncOnlyOnWifi,
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .toggleSyncOnlyOnWifi(value),
            ),
          ],
        ),

        // 🛡️ Admin Section (if user is admin)
        if (user?.isAdmin == true) ...[
          const SizedBox(height: 20),
          _buildSectionCard(
            title: '🛡️ Administration',
            icon: Icons.admin_panel_settings,
            color: AppColors.medicalBlue,
            children: [
              _buildModernActionTile(
                title: '👥 Gestion des utilisateurs',
                subtitle: 'Ajouter, modifier, supprimer des comptes',
                icon: Icons.people,
                onTap: () => GoRouter.of(context).pushNamed('/admin/users'),
              ),
              const Divider(height: 1),
              _buildModernActionTile(
                title: '📦 Archives complètes',
                subtitle: 'Voir toutes les archives du système',
                icon: Icons.archive,
                onTap: () => GoRouter.of(context).pushNamed('/admin/archives'),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // ⚠️ Danger Zone
        _buildSectionCard(
          title: '⚠️ Zone de sécurité',
          icon: Icons.warning,
          color: AppColors.emergencyRed,
          children: [
            _buildModernActionTile(
              title: '🚪 Déconnexion',
              subtitle: 'Se déconnecter de l\'application',
              icon: Icons.logout,
              color: AppColors.emergencyRed,
              isLoading: _isLoggingOut,
              onTap: _logout,
            ),
            const Divider(height: 1),
            _buildModernActionTile(
              title: '🔄 Réinitialiser les paramètres',
              subtitle: 'Restaurer tous les paramètres par défaut',
              icon: Icons.restore,
              color: AppColors.warningOrange,
              onTap: _resetSettings,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color? color,
    required List<Widget> children,
  }) {
    final sectionColor = color ?? AppColors.medicalBlue;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: sectionColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: sectionColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.medicalBlue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.medicalBlue, size: 20),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.medicalBlue,
    );
  }

  Widget _buildModernDropdownTile<T>({
    required String title,
    required String subtitle,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.medicalBlue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.medicalBlue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox(),
        style: const TextStyle(color: AppColors.medicalBlue),
      ),
    );
  }

  Widget _buildModernActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? color,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final tileColor = color ?? AppColors.medicalBlue;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tileColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: tileColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: tileColor),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: isLoading ? null : onTap,
    );
  }

  /// Logout function
  Future<void> _logout() async {
    final confirmed = await context.showConfirmationDialog(
      title: '🚪 Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
      confirmText: 'Se déconnecter',
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signOut();

      if (mounted) {
  context.go('/login');
}
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('❌ Erreur lors de la déconnexion');
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  /// Reset settings to defaults
  Future<void> _resetSettings() async {
    final confirmed = await context.showConfirmationDialog(
      title: '🔄 Réinitialisation',
      message: 'Êtes-vous sûr de vouloir réinitialiser tous les paramètres ?',
      confirmText: 'Réinitialiser',
      confirmColor: AppColors.warningOrange,
    );

    if (confirmed != true) return;

    await ref.read(settingsProvider.notifier).resetToDefaults();
    if (mounted) {
      context.showSuccessSnackBar('✅ Paramètres réinitialisés');
    }
  }
}
