import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../shared/extensions/context_ext.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/alert_provider.dart';
import '../../../shared/models/alert_model.dart';
import 'dart:math';

class AlertCenterScreen extends ConsumerStatefulWidget {
  const AlertCenterScreen({super.key});

  @override
  ConsumerState<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends ConsumerState<AlertCenterScreen> {
  final List<String> _selectedAlertIds = [];
  bool _isSelectionMode = false;
  String _actionText = '';

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertProvider);
    final filteredAlerts = ref.watch(filteredAlertsProvider);
    final alertFilter = ref.watch(alertFilterProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Centre d\'alertes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedAlertIds.clear();
                });
              },
              child: const Text('❌ Annuler'),
            )
          else ...[
            // ✅ Filter button with badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: () => _showFilterDialog(),
                  tooltip: 'Filtrer',
                ),
                if (alertFilter != 'all')
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.emergencyRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (alertState.totalUnacknowledged > 0)
              IconButton(
                icon: const Icon(Icons.done_all_rounded),
                onPressed: () => _showBulkActionsDialog(),
                tooltip: 'Actions groupées',
              ),
          ],
        ],
        bottom: _isSelectionMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.medicalBlue, AppColors.lightBlue],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.medicalBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          '📌 ${_selectedAlertIds.length} sélectionnée(s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Traiter',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: _acknowledgeSelected,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          _buildSummaryCards(alertState),
          const SizedBox(height: 8),
          if (alertFilter != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                avatar: Icon(_getFilterIcon(alertFilter), size: 16),
                label: Text(_getFilterLabel(alertFilter)),
                onDeleted: () {
                  ref.read(alertFilterProvider.notifier).state = 'all';
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: _getFilterColor(
                  alertFilter,
                ).withValues(alpha: 0.1),
              ),
            ),
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔍 Filtrer les alertes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('📋 Toutes', 'all', Icons.list),
            _buildFilterOption(
              '📭 Non traitées',
              'unacknowledged',
              Icons.mark_email_unread,
            ),
            _buildFilterOption(
              '🔴 Urgences',
              AppConstants.alertSeverityCritical,
              Icons.warning,
            ),
            _buildFilterOption(
              '🟠 Surveillance',
              AppConstants.alertSeverityWarning,
              Icons.info,
            ),
            _buildFilterOption(
              '🟡 Attention',
              AppConstants.alertSeverityMedium,
              Icons.notifications_active,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = ref.read(alertFilterProvider) == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.medicalBlue : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.medicalBlue : Colors.grey,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.medicalBlue)
          : null,
      onTap: () {
        ref.read(alertFilterProvider.notifier).state = value;
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSummaryCards(AlertState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryCard(
            '🔴 URGENCE',
            state.criticalCount,
            AppColors.emergencyRed,
            AppConstants.alertSeverityCritical,
          ),
          const SizedBox(width: 10),
          _buildSummaryCard(
            '🟠 SURVEILLANCE',
            state.warningCount,
            AppColors.warningOrange,
            AppConstants.alertSeverityWarning,
          ),
          const SizedBox(width: 10),
          _buildSummaryCard(
            '🟡 ATTENTION',
            state.mediumCount,
            AppColors.mediumYellow,
            AppConstants.alertSeverityMedium,
          ),
          const SizedBox(width: 10),
          _buildSummaryCard(
            '🟢 INFO',
            state.infoCount,
            AppColors.stableGreen,
            AppConstants.alertSeverityInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    int count,
    Color color,
    String filterValue,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(alertFilterProvider.notifier).state = filterValue,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 26,
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

  Widget _buildDesktopTable(List<AlertModel> alerts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: DataTable(
        dataRowMinHeight: 70,
        dataRowMaxHeight: 90,
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.medicalBlue.withValues(alpha: 0.08),
        ),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
        columns: [
          if (_isSelectionMode) const DataColumn(label: Text('')),
          const DataColumn(label: Text('⚠️ Sévérité')),
          const DataColumn(label: Text('👶 Patient')),
          const DataColumn(label: Text('📊 Paramètre')),
          const DataColumn(label: Text('📈 Valeur')),
          const DataColumn(label: Text('📅 Date')),
          const DataColumn(label: Text('✅ Statut')),
          const DataColumn(label: Text('🛠️ Actions')),
        ],
        rows: alerts
            .map(
              (alert) => DataRow(
                selected: _selectedAlertIds.contains(alert.id),
                onSelectChanged: _isSelectionMode
                    ? (selected) {
                        setState(() {
                          if (!_selectedAlertIds.contains(alert.id)) {
                               _selectedAlertIds.add(alert.id);
                              } else {
                            _selectedAlertIds.remove(alert.id);
                          }
                        });
                      }
                    : null,
                color: WidgetStateProperty.resolveWith((states) {
                  if (!alert.isAcknowledged &&
                      alert.requiresImmediateAttention) {
                    return AppColors.emergencyRed.withValues(alpha: 0.08);
                  }
                  return null;
                }),
                cells: [
                  if (_isSelectionMode)
                    DataCell(
                      SizedBox(
                        width: 24,
                        child: Checkbox(
                          value: _selectedAlertIds.contains(alert.id),
                          onChanged: (selected) {
                            setState(() {
                              if (!_selectedAlertIds.contains(alert.id)) {
                                     _selectedAlertIds.add(alert.id);
                              } else {
                                _selectedAlertIds.remove(alert.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  DataCell(_buildSeverityChip(alert.severity)),
                  DataCell(
                    Text(
                      alert.newbornName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(Text(_getParameterLabel(alert.parameter))),
                  DataCell(
                    Text(
                      '${alert.value} ${_getParameterUnit(alert.parameter)}',
                    ),
                  ),
                  DataCell(
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                        'fr_FR',
                      ).format(alert.timestamp),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  DataCell(_buildStatusChip(alert.isAcknowledged)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!alert.isAcknowledged)
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.stableGreen,
                            ),
                            onPressed: () => _acknowledgeAlert(alert),
                            tooltip: 'Traiter',
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_rounded,
                            color: AppColors.medicalBlue,
                          ),
                          onPressed: () => _showAlertDetails(alert),
                          tooltip: 'Détails',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileList(List<AlertModel> alerts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildAlertCard(alerts[index]),
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final isUnacknowledged = !alert.isAcknowledged;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, severityColor.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isUnacknowledged && alert.requiresImmediateAttention
                ? severityColor.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isUnacknowledged && alert.requiresImmediateAttention
                ? 12
                : 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: isUnacknowledged && alert.requiresImmediateAttention
              ? 1.5
              : 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAlertDetails(alert),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSeverityIcon(alert.severity),
                            size: 14,
                            color: severityColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getSeverityLabel(alert.severity),
                            style: TextStyle(
                              fontSize: 11,
                              color: severityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isUnacknowledged)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⏳ Non traité',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warningOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.baby_changing_station,
                        size: 22,
                        color: AppColors.medicalBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.newbornName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '📁 Dossier: ${alert.dossierNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: severityColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                        'fr_FR',
                      ).format(alert.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (isUnacknowledged)
                      TextButton.icon(
                        onPressed: () => _acknowledgeAlert(alert),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
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
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String emoji;
    String message;
    if (filter == 'unacknowledged') {
      emoji = '📭';
      message = 'Aucune alerte non traitée';
    } else if (filter == AppConstants.alertSeverityCritical) {
      emoji = '✅';
      message = 'Aucune urgence';
    } else {
      emoji = '🔔';
      message = 'Aucune alerte';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                ref.read(alertFilterProvider.notifier).state = 'all',
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Voir toutes les alertes'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getSeverityIcon(severity), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _getSeverityLabel(severity),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isAcknowledged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAcknowledged
            ? AppColors.stableGreen.withValues(alpha: 0.15)
            : AppColors.warningOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAcknowledged ? '✅ Traité' : '⏳ En attente',
        style: TextStyle(
          fontSize: 11,
          color: isAcknowledged
              ? AppColors.stableGreen
              : AppColors.warningOrange,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(AlertModel alert) async {
  _actionText = '';

  final action = await _showActionDialog(alert);

  if (!mounted) return;

  await ref
      .read(alertProvider.notifier)
      .acknowledgeAlert(
        alert.id,
        actionTaken: action,
      );

  if (!mounted) return;

  context.showSuccessSnackBar(
    '✅ Alerte marquée comme traitée',
  );
}

  Future<void> _acknowledgeSelected() async {
    if (_selectedAlertIds.isEmpty) return;
    final confirmed = await context.showConfirmationDialog(
      title: '✅ Traiter les alertes',
      message: 'Marquer ${_selectedAlertIds.length} alerte(s) comme traitées ?',
      confirmText: 'Confirmer',
    );
    if (confirmed != true) return;
    await ref
        .read(alertProvider.notifier)
        .acknowledgeMultipleAlerts(_selectedAlertIds);
    setState(() {
      _isSelectionMode = false;
      _selectedAlertIds.clear();
    });
    if (mounted) {
      context.showSuccessSnackBar('✅ Alertes traitées');
    }
  }

  void _showBulkActionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚡ Actions groupées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBulkOption(
              icon: Icons.select_all_rounded,
              title: 'Sélection multiple',
              color: AppColors.medicalBlue,
              onTap: () {
                Navigator.pop(context);
                setState(() => _isSelectionMode = true);
              },
            ),
            _buildBulkOption(
              icon: Icons.warning_rounded,
              title: 'Toutes les urgences',
              color: AppColors.emergencyRed,
              onTap: () {
                Navigator.pop(context);
                _acknowledgeAllBySeverity(AppConstants.alertSeverityCritical);
              },
            ),
            _buildBulkOption(
              icon: Icons.info_rounded,
              title: 'Toutes les surveillances',
              color: AppColors.warningOrange,
              onTap: () {
                Navigator.pop(context);
                _acknowledgeAllBySeverity(AppConstants.alertSeverityWarning);
              },
            ),
            _buildBulkOption(
              icon: Icons.done_all_rounded,
              title: 'Toutes les alertes non traitées',
              color: AppColors.stableGreen,
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

  Widget _buildBulkOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _acknowledgeAllBySeverity(String severity) async {
    final confirmed = await context.showConfirmationDialog(
      title: '✅ Traiter toutes les alertes',
      message:
          'Marquer toutes les alertes "${_getSeverityLabel(severity)}" comme traitées ?',
      confirmText: 'Confirmer',
    );
    if (confirmed != true) return;
    await ref
        .read(alertProvider.notifier)
        .acknowledgeAllAlertsBySeverity(severity);
    if (mounted) context.showSuccessSnackBar('✅ Alertes traitées');
  }

  Future<void> _acknowledgeAllUnacknowledged() async {
    final confirmed = await context.showConfirmationDialog(
      title: '✅ Traiter toutes les alertes',
      message: 'Marquer toutes les alertes non traitées comme traitées ?',
      confirmText: 'Confirmer',
    );
    if (confirmed != true) return;
    final unacknowledgedAlerts = ref
        .read(alertProvider)
        .alerts
        .where((a) => !a.isAcknowledged)
        .map((a) => a.id)
        .toList();
    await ref
        .read(alertProvider.notifier)
        .acknowledgeMultipleAlerts(unacknowledgedAlerts);
    if (mounted)
      context.showSuccessSnackBar('✅ Toutes les alertes ont été traitées');
  }

  Future<String?> _showActionDialog(AlertModel alert) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Action effectuée'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stableGreen,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
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
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                      'fr_FR',
                    ).format(alert.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSeverityColor(
                    alert.severity,
                  ).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: _getSeverityColor(alert.severity),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow('👶 Patient', alert.newbornName),
              _buildDetailRow('📁 Numéro dossier', alert.dossierNumber),
              _buildDetailRow(
                '📊 Paramètre',
                _getParameterLabel(alert.parameter),
              ),
              _buildDetailRow(
                '📈 Valeur',
                '${alert.value} ${_getParameterUnit(alert.parameter)}',
              ),
              _buildDetailRow(
                '✅ Statut',
                alert.isAcknowledged ? 'Traité' : 'En attente',
              ),
              if (alert.acknowledgedBy != null)
                _buildDetailRow('👤 Traité par', alert.acknowledgedBy!),
              if (alert.acknowledgedAt != null)
                _buildDetailRow(
                  '📅 Date traitement',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                    'fr_FR',
                  ).format(alert.acknowledgedAt!),
                ),
              if (alert.actionTaken != null && alert.actionTaken!.isNotEmpty)
                _buildDetailRow('📝 Action', alert.actionTaken!),
              const SizedBox(height: 24),
              if (!alert.isAcknowledged)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _acknowledgeAlert(alert);
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Marquer comme traité'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.stableGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'unacknowledged':
        return '📭 Non traitées';
      case AppConstants.alertSeverityCritical:
        return '🔴 Urgences';
      case AppConstants.alertSeverityWarning:
        return '🟠 Surveillance';
      case AppConstants.alertSeverityMedium:
        return '🟡 Attention';
      default:
        return '📋 Toutes';
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'unacknowledged':
        return Icons.mark_email_unread;
      case AppConstants.alertSeverityCritical:
        return Icons.warning;
      case AppConstants.alertSeverityWarning:
        return Icons.info;
      case AppConstants.alertSeverityMedium:
        return Icons.notifications_active;
      default:
        return Icons.list;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case AppConstants.alertSeverityCritical:
        return AppColors.emergencyRed;
      case AppConstants.alertSeverityWarning:
        return AppColors.warningOrange;
      case AppConstants.alertSeverityMedium:
        return AppColors.mediumYellow;
      default:
        return AppColors.medicalBlue;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return AppColors.emergencyRed;
      case AppConstants.alertSeverityWarning:
        return AppColors.warningOrange;
      case AppConstants.alertSeverityMedium:
        return AppColors.mediumYellow;
      default:
        return AppColors.stableGreen;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return Icons.warning_rounded;
      case AppConstants.alertSeverityWarning:
        return Icons.info_rounded;
      case AppConstants.alertSeverityMedium:
        return Icons.notifications_active_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return 'Urgence';
      case AppConstants.alertSeverityWarning:
        return 'Surveillance';
      case AppConstants.alertSeverityMedium:
        return 'Attention';
      default:
        return 'Information';
    }
  }

  String _getParameterLabel(String parameter) {
    switch (parameter) {
      case 'glucose':
        return 'Glycémie';
      case 'temperature':
        return 'Température';
      case 'apgar':
        return 'APGAR';
      case 'respiration':
        return 'Respiration';
      case 'cri':
        return 'Cri';
      case 'tonus':
        return 'Tonus';
      default:
        return parameter;
    }
  }

  String _getParameterUnit(String parameter) {
    switch (parameter) {
      case 'glucose':
        return 'mg/dL';
      case 'temperature':
        return '°C';
      case 'apgar':
        return '/10';
      default:
        return '';
    }
  }
}
