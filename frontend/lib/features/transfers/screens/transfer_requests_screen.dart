import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/transfer_provider.dart';
import '../../../shared/models/transfer_model.dart';

class TransferRequestsScreen extends ConsumerStatefulWidget {
  const TransferRequestsScreen({super.key});

  @override
  ConsumerState<TransferRequestsScreen> createState() =>
      _TransferRequestsScreenState();
}

class _TransferRequestsScreenState
    extends ConsumerState<TransferRequestsScreen> {
  int _selectedTab = 0; // 0: Pending, 1: Approved, 2: Rejected, 3: Completed
  String? _rejectionReason;

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(transferProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚑 Demandes de transfert'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (transferState.totalPending > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emergencyRed, AppColors.emergencyRed],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emergencyRed.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                '🔔 ${transferState.totalPending} en attente',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(transferState)
          : _buildMobileLayout(transferState),
    );
  }

  Widget _buildDesktopLayout(TransferState transferState) {
    return Row(
      children: [
        // Sidebar with tabs
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildTabButton(
                '⏳ En attente',
                0,
                transferState.totalPending,
                Icons.pending,
                AppColors.warningOrange,
              ),
              _buildTabButton(
                '✅ Approuvés',
                1,
                transferState.totalApproved,
                Icons.check_circle,
                AppColors.stableGreen,
              ),
              _buildTabButton(
                '❌ Refusés',
                2,
                transferState.totalRejected,
                Icons.cancel,
                AppColors.emergencyRed,
              ),
              _buildTabButton(
                '🏁 Terminés',
                3,
                transferState.totalCompleted,
                Icons.done_all,
                AppColors.medicalBlue,
              ),
            ],
          ),
        ),
        // Content area
        Expanded(child: _buildContent(transferState)),
      ],
    );
  }

  Widget _buildMobileLayout(TransferState transferState) {
    return DefaultTabController(
           length: 4,
            child: Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            labelColor: AppColors.medicalBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.medicalBlue,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(icon: Icon(Icons.pending), text: '⏳ En attente'),
              Tab(icon: Icon(Icons.check_circle), text: '✅ Approuvés'),
              Tab(icon: Icon(Icons.cancel), text: '❌ Refusés'),
              Tab(icon: Icon(Icons.done_all), text: '🏁 Terminés'),
            ],
          ),
        ),
        // Content
        Expanded(child: _buildContent(transferState)),
      ],
            ),
    //),
    );
  }

  Widget _buildTabButton(
    String title,
    int index,
    int count,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? color : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        tileColor: isSelected ? color.withValues(alpha: 0.1) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildContent(TransferState transferState) {
    if (transferState.isLoading && _getCurrentList(transferState).isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final transfers = _getCurrentList(transferState);

    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(), size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubMessage(),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildTransferCard(transfer),
        );
      },
    );
  }

  List<TransferModel> _getCurrentList(TransferState state) {
    switch (_selectedTab) {
      case 0:
        return state.pendingTransfers;
      case 1:
        return state.approvedTransfers;
      case 2:
        return state.rejectedTransfers;
      case 3:
        return state.completedTransfers;
      default:
        return state.pendingTransfers;
    }
  }

  String _getEmptyMessage() {
    switch (_selectedTab) {
      case 0:
        return 'Aucune demande en attente';
      case 1:
        return 'Aucun transfert approuvé';
      case 2:
        return 'Aucun transfert refusé';
      case 3:
        return 'Aucun transfert terminé';
      default:
        return 'Aucune demande';
    }
  }

  String _getEmptySubMessage() {
    switch (_selectedTab) {
      case 0:
        return 'Les nouvelles demandes apparaîtront ici';
      case 1:
        return 'Les transferts approuvés sont listés ici';
      case 2:
        return 'Aucun transfert n\'a été refusé';
      case 3:
        return 'Les transferts terminés sont archivés ici';
      default:
        return '';
    }
  }

  IconData _getEmptyIcon() {
    switch (_selectedTab) {
      case 0:
        return Icons.inbox;
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.cancel_outlined;
      case 3:
        return Icons.done_all;
      default:
        return Icons.folder_open;
    }
  }

  Widget _buildTransferCard(TransferModel transfer) {
    final statusColor = _getStatusColor(transfer.status);
    final statusEmoji = _getStatusEmoji(transfer.status);
    final statusLabel = _getStatusLabel(transfer.status);
    final isPending = transfer.status == AppConstants.transferStatusPending;

    return Card(
      elevation: isPending ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isPending
            ? const BorderSide(color: AppColors.warningOrange, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusColor, statusColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Text(statusEmoji, style: const TextStyle(fontSize: 22)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transfer.newbornName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '📁 Dossier: ${transfer.dossierNumber}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(statusEmoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '📅 ${DateFormat('dd/MM/yyyy', 'fr_FR').format(transfer.requestedAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  '👤 Demandé par',
                  transfer.requestedByName,
                  Icons.person,
                ),
                _buildInfoRow(
                  '🏥 Destination',
                  transfer.transferOption,
                  Icons.local_hospital,
                ),
                if (transfer.transferReason != null &&
                    transfer.transferReason!.isNotEmpty)
                  _buildInfoRow(
                    '📝 Motif',
                    transfer.transferReason!,
                    Icons.description,
                  ),
                if (transfer.status == AppConstants.transferStatusApproved &&
                    transfer.respondedAt != null)
                  _buildInfoRow(
                    '✅ Approuvé le',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                      'fr_FR',
                    ).format(transfer.respondedAt!),
                    Icons.check_circle,
                  ),
                if (transfer.status == AppConstants.transferStatusRejected &&
                    transfer.rejectionReason != null)
                  _buildInfoRow(
                    '❌ Raison du refus',
                    transfer.rejectionReason!,
                    Icons.cancel,
                    color: AppColors.emergencyRed,
                  ),
                const Divider(height: 24),
                if (transfer.status == AppConstants.transferStatusPending)
                  _buildPendingActions(transfer),
                if (transfer.status == AppConstants.transferStatusApproved)
                  _buildApprovedActions(transfer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Row(
              children: [
                Icon(icon, size: 16, color: color ?? Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color ?? Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(TransferModel transfer) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectDialog(transfer),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('❌ Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emergencyRed,
              side: const BorderSide(color: AppColors.emergencyRed),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveTransfer(transfer),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('✅ Approuver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stableGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedActions(TransferModel transfer) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewDossier(transfer.dossierId),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('👁️ Voir dossier'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _completeTransfer(transfer),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('🏁 Terminer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveTransfer(TransferModel transfer) async {
    final confirmed = await context.showConfirmationDialog(
      title: '✅ Approuver le transfert',
      message:
          'Êtes-vous sûr de vouloir approuver le transfert de ${transfer.newbornName} ?\n\n'
          '📋 Le dossier sera accessible dans votre liste.',
      confirmText: 'Approuver',
      confirmColor: AppColors.stableGreen,
    );

    if (confirmed != true) return;

    try {
      await ref.read(transferProvider.notifier).approveTransfer(transfer.id);
      if (mounted) {
        context.showSuccessSnackBar('✅ Transfert approuvé avec succès');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('❌ Erreur: ${e.toString()}');
      }
    }
  }

  void _showRejectDialog(TransferModel transfer) {
    _rejectionReason = null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.emergencyRed),
            SizedBox(width: 8),
            Text('❌ Refuser le transfert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du refus :'),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => _rejectionReason = value,
              decoration: const InputDecoration(
                hintText: 'Raison du refus...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_rejectionReason == null || _rejectionReason!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer une raison')),
                );
                return;
              }
              if (!mounted) return;
              final localContext = context;
              final messenger = ScaffoldMessenger.of(localContext);
              Navigator.pop(localContext);
              try {
                await ref
                    .read(transferProvider.notifier)
                    .rejectTransfer(transfer.id, _rejectionReason!);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('❌ Transfert refusé')),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('❌ Erreur: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
            ),
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTransfer(TransferModel transfer) async {
    final confirmed = await context.showConfirmationDialog(
      title: '🏁 Terminer le transfert',
      message:
          'Confirmez-vous que la prise en charge de ${transfer.newbornName} est terminée ?',
      confirmText: 'Terminer',
      confirmColor: AppColors.medicalBlue,
    );

    if (confirmed != true) return;

    try {
      await ref.read(transferProvider.notifier).completeTransfer(transfer.id);
      if (mounted) {
        context.showSuccessSnackBar('🏁 Transfert marqué comme terminé');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('❌ Erreur: ${e.toString()}');
      }
    }
  }

  void _viewDossier(String dossierId) {
    // ✅ تصحيح التنقل إلى dossier_detail باستخدام اسم المسار
    GoRouter.of(
      context,
    ).pushNamed('dossier_detail', pathParameters: {'id': dossierId});
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningOrange;
      case 'approved':
        return AppColors.stableGreen;
      case 'rejected':
        return AppColors.emergencyRed;
      case 'completed':
        return AppColors.medicalBlue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusEmoji(String status) {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      case 'completed':
        return '🏁';
      default:
        return '📋';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Refusé';
      case 'completed':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }
}
