import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dashboard_provider.dart';
import '../../../theme/colors.dart';

import '../../../shared/models/alert_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/alert_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final recentDossiers = ref.watch(recentDossiersProvider);
    final recentAlerts = ref.watch(recentAlertsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text(
          '📊 Tableau de bord',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.pushNamed('notifications'),
              ),
              if (stats.unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${stats.unreadNotifications}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardProvider.notifier).loadStats(),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadStats(),
        color: AppColors.medicalBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(ref, user),
              const SizedBox(height: 20),

              _buildStats(stats),
              const SizedBox(height: 20),

              _buildQuickActions(context),
              const SizedBox(height: 24),

              _buildRecentDossiers(recentDossiers),
              const SizedBox(height: 24),

              _buildRecentAlerts(context, recentAlerts),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WELCOME CARD =================
  Widget _buildWelcomeCard(WidgetRef ref, UserModel? user) {
    final name = user?.firstName ?? 'Utilisateur';
    final stats = ref.watch(dashboardProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.medicalBlue, AppColors.lightBlue],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: AppColors.medicalBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dossiers actifs: ${stats.activeDossiers}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATS =================
  Widget _buildStats(DashboardStats stats) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _stat('Critique', stats.criticalAlerts, AppColors.emergencyRed),
        _stat('Surveillance', stats.warningAlerts, AppColors.warningOrange),
        _stat('Alerte', stats.mediumAlerts, AppColors.mediumYellow),
        _stat('Transfert', stats.pendingTransfers, AppColors.lightBlue),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _action(
            context,
            Icons.add,
            'Dossier',
            () => context.pushNamed('create_dossier'),
            AppColors.stableGreen,
          ),
          _action(
            context,
            Icons.swap_horiz,
            'Transfert',
            () => context.pushNamed('transfers'),
            AppColors.warningOrange,
          ),
          _action(
            context,
            Icons.backup,
            'Backup',
            () => context.pushNamed('backup'),
            AppColors.lightBlue,
          ),
          _action(
            context,
            Icons.smart_toy,
            'AI',
            () => context.pushNamed('ai_assistant'),
            AppColors.medicalBlue,
          ),
          _action(
            context,
            Icons.settings,
            'Settings',
            () => context.go('settings'),
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ================= DOSSIERS =================
  Widget _buildRecentDossiers(AsyncValue dossiers) {
    return dossiers.when(
      data: (list) => SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final d = list[i];

            return Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: AppColors.medicalBlue.withValues(alpha: 0.3), width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['newbornName'] ?? 'Nouveau-né',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Poids: ${d['birthWeight'] ?? '?'} g'),
                  Text('Semaine: ${d['gestationalAge'] ?? '?'}'),
                ],
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur: $e'),
    );
  }

  // ================= ALERTS =================
  Widget _buildRecentAlerts(
    BuildContext context,
    AsyncValue<List<AlertModel>> alerts,
  ) {
    return alerts.when(
      data: (list) => Column(
        children: list
            .take(5)
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlertCard(
                  message: a.message,
                  severity: a.severity,
                  onTap: () => context.pushNamed('alerts'),
                ),
              ),
            )
            .toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Erreur: $e'),
    );
  }
}
