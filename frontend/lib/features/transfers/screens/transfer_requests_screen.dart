import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/transfer_provider.dart';
import '../../../shared/models/transfer_model.dart';

class TransferRequestsScreen extends ConsumerStatefulWidget {
  const TransferRequestsScreen({super.key});

  @override
  ConsumerState<TransferRequestsScreen> createState() => _TransferRequestsScreenState();
}

class _TransferRequestsScreenState extends ConsumerState<TransferRequestsScreen> {
  int _selectedTab = 0; // 0: Pending, 1: Approved, 2: Rejected, 3: Completed
  TransferModel? _selectedTransfer;
  String? _rejectionReason;

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(transferProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de transfert'),
        backgroundColor: Colors.transparent,
        actions: [
          if (transferState.totalPending > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emergencyRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${transferState.totalPending} en attente',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout(transferState) : _buildMobileLayout(transferState),
    );
  }

  Widget _buildDesktopLayout(TransferState transferState) {
    return Row(
      children: [
        // Sidebar with tabs
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              _buildTabButton('En attente', 0, transferState.totalPending, Icons.pending),
              _buildTabButton('Approuvés', 1, transferState.totalApproved, Icons.check_circle),
              _buildTabButton('Refusés', 2, transferState.totalRejected, Icons.cancel),
              _buildTabButton('Terminés', 3, transferState.totalCompleted, Icons.done_all),
            ],
          ),
        ),
        // Content area
        Expanded(
          child: _buildContent(transferState),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(TransferState transferState) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            labelColor: AppColors.medicalBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.medicalBlue,
            tabs: const [
              Tab(text: 'En attente'),
              Tab(text: 'Approuvés'),
              Tab(text: 'Refusés'),
              Tab(text: 'Terminés'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _buildContent(transferState),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index, int count, IconData icon) {
    final isSelected = _selectedTab == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.medicalBlue : Colors.grey),
      title: Text(title, style: TextStyle(color: isSelected ? AppColors.medicalBlue : Colors.grey)),
      trailing: count > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.medicalBlue : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
      tileColor: isSelected ? AppColors.medicalBlue.withOpacity(0.05) : null,
      onTap: () => setState(() => _selectedTab = index),
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
              style: TextStyle(color: Colors.grey[600]),
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
        return _buildTransferCard(transfer);
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
    final statusIcon = _getStatusIcon(transfer.status);
    final statusLabel = _getStatusLabel(transfer.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: transfer.status == AppConstants.transferStatusPending
            ? BorderSide(color: AppColors.warningOrange, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transfer.newbornName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Dossier: ${transfer.dossierNumber}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, color: statusColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Demandé le ${DateFormat('dd/MM/yyyy', 'fr_FR').format(transfer.requestedAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Demandé par', transfer.requestedByName),
                _buildInfoRow('Destination', transfer.transferOption),
                if (transfer.transferReason != null && transfer.transferReason!.isNotEmpty)
                  _buildInfoRow('Motif', transfer.transferReason!),
                if (transfer.status == AppConstants.transferStatusApproved && transfer.respondedAt != null)
                  _buildInfoRow('Approuvé le', DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(transfer.respondedAt!)),
                if (transfer.status == AppConstants.transferStatusRejected && transfer.rejectionReason != null)
                  _buildInfoRow('Raison du refus', transfer.rejectionReason!),
                const Divider(),
                
                // Action buttons
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

  Widget _buildPendingActions(TransferModel transfer) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectDialog(transfer),
            icon: const Icon(Icons.close),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emergencyRed,
              side: const BorderSide(color: AppColors.emergencyRed),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approveTransfer(transfer),
            icon: const Icon(Icons.check),
            label: const Text('Approuver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stableGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            icon: const Icon(Icons.visibility),
            label: const Text('Voir le dossier'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _completeTransfer(transfer),
            icon: const Icon(Icons.check_circle),
            label: const Text('Marquer terminé'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveTransfer(TransferModel transfer) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Approuver le transfert',
      message: 'Êtes-vous sûr de vouloir approuver le transfert de ${transfer.newbornName} ?\n\n'
          'Le dossier sera accessible dans votre liste.',
      confirmText: 'Approuver',
      confirmColor: AppColors.stableGreen,
    );

    if (confirmed != true) return;

    try {
      await ref.read(transferProvider.notifier).approveTransfer(transfer.id);
      if (mounted) {
        context.showSuccessSnackBar('Transfert approuvé avec succès');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erreur: $e');
      }
    }
  }

  void _showRejectDialog(TransferModel transfer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le transfert'),
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
              Navigator.pop(context);
              try {
                await ref.read(transferProvider.notifier).rejectTransfer(transfer.id, _rejectionReason!);
                if (mounted) {
                  context.showSuccessSnackBar('Transfert refusé');
                }
              } catch (e) {
                if (mounted) {
                  context.showErrorSnackBar('Erreur: $e');
                }
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
      title: 'Terminer le transfert',
      message: 'Confirmez-vous que la prise en charge est terminée ?',
      confirmText: 'Terminer',
      confirmColor: AppColors.medicalBlue,
    );

    if (confirmed != true) return;

    try {
      await ref.read(transferProvider.notifier).completeTransfer(transfer.id);
      if (mounted) {
        context.showSuccessSnackBar('Transfert marqué comme terminé');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erreur: $e');
      }
    }
  }

  void _viewDossier(String dossierId) {
    Navigator.pushNamed(context, '/dossiers/$dossierId');
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
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