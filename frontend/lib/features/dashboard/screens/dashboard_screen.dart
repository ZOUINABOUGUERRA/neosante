import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../theme/colors.dart';
//import '../../../shared/extensions/context_ext.dart';
//import '../../../shared/widgets/alert_card.dart';
//import '../../../core/constants/app_constants.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/user_model.dart';
//import '../../../services/auth_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
// أضف هذا الاستيراد في بداية ملف dashboard_screen.dart
import '../../../shared/widgets/alert_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final recentDossiers = ref.watch(recentDossiersProvider);
    final recentAlerts = ref.watch(recentAlertsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => GoRouter.of(context).pushNamed('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardProvider.notifier).loadStats(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadStats(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              _buildWelcomeCard(context, ref, user),
              const SizedBox(height: 20),

              // Stats cards row
              _buildStatsRow(context, stats),
              const SizedBox(height: 20),

              // Quick actions
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // Recent dossiers
              _buildRecentDossiersSection(context, recentDossiers),
              const SizedBox(height: 20),

              // Recent alerts
              _buildRecentAlertsSection(context, recentAlerts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, WidgetRef ref, UserModel? user) {
    final userName = user?.firstName ?? 'Sage-Femme';
    final dashboardStats = ref.read(dashboardProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.medicalBlue.withValues(alpha: 0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '👤',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, $userName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aujourd\'hui: ${_formatDate(DateTime.now())}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.medicalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder,
                      size: 16, color: AppColors.medicalBlue),
                  const SizedBox(width: 8),
                  Text(
                    '${dashboardStats.activeDossiers} dossiers actifs',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '🔴 URGENCE',
            stats.criticalAlerts,
            AppColors.emergencyRed,
            onTap: () => _goToAlerts(context, 'critical'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🟠 SURVEILLANCE',
            stats.warningAlerts,
            AppColors.warningOrange,
            onTap: () => _goToAlerts(context, 'warning'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🟡 MOYEN',
            stats.mediumAlerts,
            AppColors.mediumYellow,
            onTap: () => _goToAlerts(context, 'medium'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🔄 TRANSFERTS',
            stats.pendingTransfers,
            AppColors.lightBlue,
            onTap: () => GoRouter.of(context).pushNamed('/transfers'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.add,
                  label: 'Nouveau dossier',
                  onTap: () => GoRouter.of(context).pushNamed('/dossiers/create'),
                  color: AppColors.stableGreen,
                ),
                _buildActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Transferts',
                  onTap: () => GoRouter.of(context).pushNamed('/transfers'),
                  color: AppColors.warningOrange,
                ),
                _buildActionButton(
                  icon: Icons.backup,
                  label: 'Sauvegarde',
                  onTap: () => GoRouter.of(context).pushNamed('/backup'),
                  color: AppColors.lightBlue,
                ),
                _buildActionButton(
                  icon: Icons.assistant,
                  label: 'AI Assistant',
                  onTap: () => GoRouter.of(context).pushNamed('/ai-assistant'),
                  color: AppColors.medicalBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentDossiersSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> recentDossiers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Dossiers récents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        recentDossiers.when(
          data: (dossiers) {
            if (dossiers.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Aucun dossier récent')),
                ),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dossiers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final dossier = dossiers[index];
                  return _buildDossierCard(dossier);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Erreur: $error')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDossierCard(Map<String, dynamic> dossier) {
    final severity = dossier['alertSeverity'] ?? 'info';
    Color borderColor;
    switch (severity) {
      case 'critical':
        borderColor = AppColors.emergencyRed;
        break;
      case 'warning':
        borderColor = AppColors.warningOrange;
        break;
      case 'medium':
        borderColor = AppColors.mediumYellow;
        break;
      default:
        borderColor = AppColors.stableGreen;
    }

    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dossier['newbornName'] ?? 'Nouveau-né',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${dossier['gestationalAge'] ?? '?'} SA',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Poids: ${dossier['birthWeight'] ?? '?'} g',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Glycémie: ${dossier['bloodGlucose'] ?? '?'} mg/dL',
                style: TextStyle(
                  fontSize: 12,
                  color: borderColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection(
    BuildContext context,
    AsyncValue<List<AlertModel>> recentAlerts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ Alertes récentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        recentAlerts.when(
          data: (alerts) {
            if (alerts.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Aucune alerte récente')),
                ),
              );
            }
            return Column(
              children: alerts.take(5).map((alert) {
                return AlertCard(
                  message: alert.message,
                  severity: alert.severity,
                  onTap: () => GoRouter.of(context).pushNamed('/alerts'),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Erreur: $error')),
            ),
          ),
        ),
      ],
    );
  }

  void _goToAlerts(BuildContext context, String severity) {
    GoRouter.of(context).pushNamed('/alerts', extra: {'filter': severity});
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}