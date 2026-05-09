import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/alert_provider.dart';
import '../../../shared/models/alert_model.dart';

class AlertCenterScreen extends ConsumerStatefulWidget {
  const AlertCenterScreen({super.key});

  @override
  ConsumerState<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends ConsumerState<AlertCenterScreen> {
  List<String> _selectedAlertIds = [];
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertProvider);
    final filteredAlerts = ref.watch(filteredAlertsProvider);
    final alertFilter = ref.watch(alertFilterProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'alertes'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedAlertIds.clear();
                });
              },
              child: const Text('Annuler'),
            )
          else ...[
            // Filter button
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                ref.read(alertFilterProvider.notifier).state = value;
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Toutes les alertes')),
                const PopupMenuItem(value: 'unacknowledged', child: Text('Non traitées')),
                const PopupMenuItem(value: AppConstants.alertSeverityCritical, child: Text('Urgences')),
                const PopupMenuItem(value: AppConstants.alertSeverityWarning, child: Text('Surveillance')),
                const PopupMenuItem(value: AppConstants.alertSeverityMedium, child: Text('Attention')),
              ],
            ),
            // Bulk actions
            if (alertState.totalUnacknowledged > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: () => _showBulkActionsDialog(),
                tooltip: 'Actions groupées',
              ),
          ],
        ],
        bottom: _isSelectionMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: AppColors.medicalBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedAlertIds.length} sélectionnée(s)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        onPressed: () => _acknowledgeSelected(),
                        tooltip: 'Marquer comme traitées',
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Summary cards
          _buildSummaryCards(alertState),
          const SizedBox(height: 8),
          // Active filter indicator
          if (alertFilter != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text(_getFilterLabel(alertFilter)),
                onDeleted: () {
                  ref.read(alertFilterProvider.notifier).state = 'all';
                },
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ),
          // Alert list
          Expanded(
            child: alertState.isLoading && filteredAlerts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredAlerts.isEmpty
                    ? _buildEmptyState(alertFilter)
                    : isDesktop
                        ? _buildDesktopTable(filteredAlerts)
                        : _buildMobileList(filteredAlerts),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AlertState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'URGENCE',
              state.criticalCount,
              AppColors.emergencyRed,
              onTap: () => ref.read(alertFilterProvider.notifier).state = AppConstants.alertSeverityCritical,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'SURVEILLANCE',
              state.warningCount,
              AppColors.warningOrange,
              onTap: () => ref.read(alertFilterProvider.notifier).state = AppConstants.alertSeverityWarning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'ATTENTION',
              state.mediumCount,
              AppColors.mediumYellow,
              onTap: () => ref.read(alertFilterProvider.notifier).state = AppConstants.alertSeverityMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'INFORMATION',
              state.infoCount,
              AppColors.stableGreen,
              onTap: () => ref.read(alertFilterProvider.notifier).state = AppConstants.alertSeverityInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<AlertModel> alerts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey.shade100),
        columns: [
          if (_isSelectionMode)
            const DataColumn(label: Text('')),
          const DataColumn(label: Text('Sévérité', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Paramètre', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Valeur', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
          const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: alerts.map((alert) => DataRow(
          selected: _selectedAlertIds.contains(alert.id),
          onSelectChanged: _isSelectionMode
              ? (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedAlertIds.add(alert.id);
                    } else {
                      _selectedAlertIds.remove(alert.id);
                    }
                  });
                }
              : null,
          color: WidgetStateProperty.resolveWith((states) {
            if (!alert.isAcknowledged && alert.requiresImmediateAttention) {
              return AppColors.emergencyRed.withOpacity(0.05);
            }
            return null;
          }),
          cells: [
            if (_isSelectionMode)
              DataCell(SizedBox(
                width: 24,
                child: Checkbox(
                  value: _selectedAlertIds.contains(alert.id),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedAlertIds.add(alert.id);
                      } else {
                        _selectedAlertIds.remove(alert.id);
                      }
                    });
                  },
                ),
              )),
            DataCell(_buildSeverityChip(alert.severity)),
            DataCell(Text(alert.newbornName, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(_getParameterLabel(alert.parameter))),
            DataCell(Text('${alert.value} ${_getParameterUnit(alert.parameter)}')),
            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(alert.timestamp))),
            DataCell(_buildStatusChip(alert.isAcknowledged)),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!alert.isAcknowledged)
                  IconButton(
                    icon: const Icon(Icons.done, size: 20, color: AppColors.stableGreen),
                    onPressed: () => _acknowledgeAlert(alert),
                    tooltip: 'Marquer comme traité',
                  ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _showAlertDetails(alert),
                  tooltip: 'Détails',
                ),
              ],
            )),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<AlertModel> alerts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    final severityColor = _getSeverityColor(alert.severity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.requiresImmediateAttention && !alert.isAcknowledged ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: alert.requiresImmediateAttention && !alert.isAcknowledged
            ? BorderSide(color: severityColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getSeverityIcon(alert.severity), size: 14, color: severityColor),
                        const SizedBox(width: 4),
                        Text(
                          _getSeverityLabel(alert.severity),
                          style: TextStyle(fontSize: 10, color: severityColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!alert.isAcknowledged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Non traité',
                        style: TextStyle(fontSize: 10, color: AppColors.warningOrange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Patient info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: severityColor.withOpacity(0.2),
                    child: const Icon(Icons.baby_changing_station, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.newbornName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Dossier: ${alert.dossierNumber}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Alert message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(alert.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (!alert.isAcknowledged)
                    TextButton.icon(
                      onPressed: () => _acknowledgeAlert(alert),
                      icon: const Icon(Icons.done, size: 18),
                      label: const Text('Traiter'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.stableGreen,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _getEmptyMessage(filter),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(alertFilterProvider.notifier).state = 'all';
            },
            child: const Text('Voir toutes les alertes'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSeverityIcon(severity), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getSeverityLabel(severity),
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isAcknowledged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAcknowledged ? AppColors.stableGreen.withOpacity(0.2) : AppColors.warningOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAcknowledged ? 'Traité' : 'En attente',
        style: TextStyle(
          fontSize: 11,
          color: isAcknowledged ? AppColors.stableGreen : AppColors.warningOrange,
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(AlertModel alert) async {
    final action = await _showActionDialog(alert);
    
    await ref.read(alertProvider.notifier).acknowledgeAlert(
      alert.id,
      actionTaken: action,
    );
    
    if (mounted) {
      context.showSuccessSnackBar('Alerte marquée comme traitée');
    }
  }

  Future<void> _acknowledgeSelected() async {
    if (_selectedAlertIds.isEmpty) return;
    
    final confirmed = await context.showConfirmationDialog(
      title: 'Traiter les alertes',
      message: 'Marquer ${_selectedAlertIds.length} alerte(s) comme traitées ?',
      confirmText: 'Confirmer',
    );
    
    if (confirmed != true) return;
    
    await ref.read(alertProvider.notifier).acknowledgeMultipleAlerts(_selectedAlertIds);
    
    setState(() {
      _isSelectionMode = false;
      _selectedAlertIds.clear();
    });
    
    if (mounted) {
      context.showSuccessSnackBar('Alertes traitées');
    }
  }

  void _showBulkActionsDialog() {
    final state = ref.read(alertProvider);
    
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
              'Actions groupées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Activer la sélection multiple'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _isSelectionMode = true);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.warning, color: AppColors.emergencyRed),
              title: const Text('Toutes les urgences'),
              onTap: () {
                Navigator.pop(context);
                _acknowledgeAllBySeverity(AppConstants.alertSeverityCritical);
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: AppColors.warningOrange),
              title: const Text('Toutes les surveillances'),
              onTap: () {
                Navigator.pop(context);
                _acknowledgeAllBySeverity(AppConstants.alertSeverityWarning);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Toutes les alertes non traitées'),
              onTap: () {
                Navigator.pop(context);
                _acknowledgeAllUnacknowledged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledgeAllBySeverity(String severity) async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Traiter toutes les alertes',
      message: 'Marquer toutes les alertes de type "${_getSeverityLabel(severity)}" comme traitées ?',
      confirmText: 'Confirmer',
    );
    
    if (confirmed != true) return;
    
    await ref.read(alertProvider.notifier).acknowledgeAllAlertsBySeverity(severity);
    
    if (mounted) {
      context.showSuccessSnackBar('Alertes traitées');
    }
  }

  Future<void> _acknowledgeAllUnacknowledged() async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Traiter toutes les alertes',
      message: 'Marquer toutes les alertes non traitées comme traitées ?',
      confirmText: 'Confirmer',
    );
    
    if (confirmed != true) return;
    
    final unacknowledgedAlerts = ref.read(alertProvider).alerts
        .where((a) => !a.isAcknowledged)
        .map((a) => a.id)
        .toList();
    
    await ref.read(alertProvider.notifier).acknowledgeMultipleAlerts(unacknowledgedAlerts);
    
    if (mounted) {
      context.showSuccessSnackBar('Toutes les alertes ont été traitées');
    }
  }

  Future<String?> _showActionDialog(AlertModel alert) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action effectuée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Décrivez l\'action entreprise :'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Ex: Administration de glucose, Réchauffement...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _actionText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Ignorer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _actionText),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
  String _actionText = '';

  void _showAlertDetails(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildSeverityChip(alert.severity),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(alert.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                alert.message,
                style: TextStyle(
                  fontSize: 16,
                  color: _getSeverityColor(alert.severity),
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow('Patient', alert.newbornName),
              _buildDetailRow('Numéro dossier', alert.dossierNumber),
              _buildDetailRow('Paramètre', _getParameterLabel(alert.parameter)),
              _buildDetailRow('Valeur', '${alert.value} ${_getParameterUnit(alert.parameter)}'),
              _buildDetailRow('Statut', alert.isAcknowledged ? 'Traité' : 'En attente'),
              if (alert.acknowledgedBy != null)
                _buildDetailRow('Traité par', alert.acknowledgedBy!),
              if (alert.acknowledgedAt != null)
                _buildDetailRow('Date traitement', 
                  DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(alert.acknowledgedAt!)),
              if (alert.actionTaken != null && alert.actionTaken!.isNotEmpty)
                _buildDetailRow('Action entreprise', alert.actionTaken!),
              const SizedBox(height: 24),
              if (!alert.isAcknowledged)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _acknowledgeAlert(alert);
                    },
                    icon: const Icon(Icons.done),
                    label: const Text('Marquer comme traité'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stableGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'unacknowledged':
        return 'Alertes non traitées';
      case 'critical':
        return 'Urgences';
      case 'warning':
        return 'Surveillance';
      case 'medium':
        return 'Attention';
      case 'info':
        return 'Information';
      default:
        return 'Toutes';
    }
  }

  String _getEmptyMessage(String filter) {
    if (filter == 'unacknowledged') {
      return 'Aucune alerte non traitée';
    }
    if (filter == 'critical') {
      return 'Aucune urgence';
    }
    if (filter == 'all') {
      return 'Aucune alerte';
    }
    return 'Aucune alerte pour ce filtre';
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical: return AppColors.emergencyRed;
      case AppConstants.alertSeverityWarning: return AppColors.warningOrange;
      case AppConstants.alertSeverityMedium: return AppColors.mediumYellow;
      default: return AppColors.stableGreen;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical: return Icons.warning;
      case AppConstants.alertSeverityWarning: return Icons.info;
      case AppConstants.alertSeverityMedium: return Icons.notifications_active;
      default: return Icons.check_circle;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical: return 'Urgence';
      case AppConstants.alertSeverityWarning: return 'Surveillance';
      case AppConstants.alertSeverityMedium: return 'Attention';
      default: return 'Information';
    }
  }

  String _getParameterLabel(String parameter) {
    switch (parameter) {
      case 'glucose': return 'Glycémie';
      case 'temperature': return 'Température';
      case 'apgar': return 'APGAR';
      case 'respiration': return 'Respiration';
      case 'cri': return 'Cri';
      case 'tonus': return 'Tonus';
      default: return parameter;
    }
  }

  String _getParameterUnit(String parameter) {
    switch (parameter) {
      case 'glucose': return 'mg/dL';
      case 'temperature': return '°C';
      case 'apgar': return '/10';
      default: return '';
    }
  }
}