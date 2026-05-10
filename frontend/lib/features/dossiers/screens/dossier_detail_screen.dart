import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/extensions/context_ext.dart';

class DossierDetailScreen extends ConsumerStatefulWidget {
  final String dossierId;

  const DossierDetailScreen({
    super.key,
    required this.dossierId,
  });

  @override
  ConsumerState<DossierDetailScreen> createState() => _DossierDetailScreenState();
}

class _DossierDetailScreenState extends ConsumerState<DossierDetailScreen> {
  Map<String, dynamic>? _dossierData;
  String _dossierType = '';
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadDossier();
  }

  Future<void> _loadDossier() async {
    setState(() => _isLoading = true);

    try {
      // Try to find in premature collection
      var doc = await FirebaseFirestore.instance
          .collection(AppConstants.dossiersPrematuresCollection)
          .doc(widget.dossierId)
          .get();

      if (doc.exists) {
        _dossierType = AppConstants.dossiersPrematuresCollection;
        _dossierData = doc.data();
        if (_dossierData != null) {
          _dossierData!['id'] = doc.id;
        }
      } else {
        // Try full-term collection
        doc = await FirebaseFirestore.instance
            .collection(AppConstants.dossiersATermeCollection)
            .doc(widget.dossierId)
            .get();
        if (doc.exists) {
          _dossierType = AppConstants.dossiersATermeCollection;
          _dossierData = doc.data();
          if (_dossierData != null) {
            _dossierData!['id'] = doc.id;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading dossier: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _archiveDossier() async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Archiver le dossier',
      message: 'Êtes-vous sûr de vouloir archiver ce dossier ?',
      confirmText: 'Archiver',
      confirmColor: AppColors.warningOrange,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // Copy to archives
      await FirebaseFirestore.instance
          .collection(AppConstants.archivesCollection)
          .doc(widget.dossierId)
          .set({
        ..._dossierData!,
        'archivedAt': FieldValue.serverTimestamp(),
        'originalCollection': _dossierType,
      });

      // Delete from original
      await FirebaseFirestore.instance
          .collection(_dossierType)
          .doc(widget.dossierId)
          .delete();

      if (mounted) {
        context.showSuccessSnackBar('Dossier archivé avec succès');
        // ✅ Correction: utiliser Navigator.of(context).pop()
        Navigator.of(context).pop();
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dossierData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dossier non trouvé')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Dossier introuvable'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_dossierData!['newbornName'] ?? 'Dossier médical'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.generateAndShare(
              widget.dossierId,
              _dossierType,
            ),
            tooltip: 'Exporter PDF',
          ),
          if (_dossierData!['status'] != AppConstants.dossierStatusArchived)
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: _archiveDossier,
              tooltip: 'Archiver',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => PdfService.generateAndShare(
              widget.dossierId,
              _dossierType,
            ),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            // ✅ Correction: withOpacity → withValues
            color: _getStatusColor(_dossierData!['status']).withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(_dossierData!['status']),
                  color: _getStatusColor(_dossierData!['status']),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusLabel(_dossierData!['status']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_dossierData!['status']),
                  ),
                ),
                const Spacer(),
                Text(
                  'N° ${_dossierData!['dossierNumber']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              onTap: (index) => setState(() => _selectedTab = index),
              labelColor: AppColors.medicalBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.medicalBlue,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Informations'),
                Tab(icon: Icon(Icons.health_and_safety), text: 'Données'),
                Tab(icon: Icon(Icons.medical_services), text: 'Soins'),
                Tab(icon: Icon(Icons.timeline), text: 'Surveillance'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildInfoTab(),
                _buildBirthDataTab(),
                _buildCareTab(),
                _buildSurveillanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final data = _dossierData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('👶 Nouveau-né', Icons.baby_changing_station),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Nom', data['newbornName'] ?? 'N/A'),
                  _buildInfoRow('Date naissance', data['birthDateTime'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                          .format((data['birthDateTime'] as Timestamp).toDate())
                      : 'N/A'),
                  _buildInfoRow('Âge gestationnel',
                      '${data['gestationalAge'] ?? '?'} SA'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('👩 Mère', Icons.woman),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Nom de la mère', data['motherName'] ?? 'N/A'),
                  _buildInfoRow('Mode d\'accouchement', data['deliveryMethod'] ?? 'N/A'),
                  _buildInfoRow('ATCD', data['atcd'] ?? 'Aucun'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('📁 Métadonnées', Icons.folder),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Créé par', data['createdBy'] ?? 'N/A'),
                  _buildInfoRow('Créé le', data['createdAt'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                          .format((data['createdAt'] as Timestamp).toDate())
                      : 'N/A'),
                  _buildInfoRow('Dernière mise à jour', data['updatedAt'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                          .format((data['updatedAt'] as Timestamp).toDate())
                      : 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDataTab() {
    final data = _dossierData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📏 Mensurations', Icons.straighten),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Poids de naissance',
                      '${data['birthWeight'] ?? '?'} g'),
                  _buildInfoRow('Température',
                      '${data['bodyTemperature'] ?? '?'} °C'),
                  _buildInfoRow('Glycémie', '${data['bloodGlucose'] ?? '?'} mg/dL'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('📊 APGAR', Icons.assessment),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('APGAR 1 minute', '${data['apgar1'] ?? '?'}/10'),
                  _buildInfoRow('APGAR 5 minutes', '${data['apgar5'] ?? '?'}/10'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('🩺 Évaluation clinique', Icons.medical_information),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Coloration', data['coloration'] ?? 'N/A'),
                  _buildInfoRow('Respiration', data['respiration'] ?? 'N/A'),
                  _buildInfoRow('Cri', data['cry'] ?? 'N/A'),
                  _buildInfoRow('Tonus', data['tonus'] ?? 'N/A'),
                  if (data['malformations']?.isNotEmpty ?? false)
                    _buildInfoRow('Malformations', data['malformations']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTab() {
    final data = _dossierData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🔧 Gestes systématiques', Icons.cleaning_services),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCheckRow('Préchauffé', data['prechauffe'] ?? false),
                  _buildCheckRow('Séchage', data['sechage'] ?? false),
                  _buildCheckRow('Stimulation', data['stimulation'] ?? false),
                  _buildInfoRow('Clampage', data['clampage'] ?? 'N/A'),
                  _buildCheckRow('Vitamine K', data['vitamineK'] ?? false),
                  _buildCheckRow('Bracelet', data['bracelet'] ?? false),
                  _buildInfoRow('Mise sous chaleur', data['miseSousChaleur'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('🫀 Réanimation', Icons.emergency),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Airway', data['airway'] ?? 'N/A'),
                  if (data['breathing']?.isNotEmpty ?? false)
                    _buildInfoRow('Breathing', data['breathing']),
                  if (data['circulation']?.isNotEmpty ?? false)
                    _buildInfoRow('Circulation', data['circulation']),
                  if (data['disabilityMedications']?.isNotEmpty ?? false)
                    _buildInfoRow('Médicaments', data['disabilityMedications']),
                  if (data['doctorName']?.isNotEmpty ?? false)
                    _buildInfoRow('Médecin', data['doctorName']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveillanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .where('dossierId', isEqualTo: widget.dossierId)
          .orderBy('recordedAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;
        final glucose = documents.where((d) => d['type'] == 'glucose').toList();
        final temps = documents.where((d) => d['type'] == 'temperature').toList();
        final meds = documents.where((d) => d['type'] == 'medication').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('📈 Dernières mesures', Icons.timeline),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (glucose.isNotEmpty)
                        _buildInfoRow(
                          'Dernière glycémie',
                          '${glucose.first['value']} mg/dL',
                          subtitle: glucose.first['recordedAt'] != null
                              ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                                  .format((glucose.first['recordedAt'] as Timestamp).toDate())
                              : null,
                        ),
                      if (temps.isNotEmpty)
                        _buildInfoRow(
                          'Dernière température',
                          '${temps.first['value']} °C',
                          subtitle: temps.first['recordedAt'] != null
                              ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                                  .format((temps.first['recordedAt'] as Timestamp).toDate())
                              : null,
                        ),
                      if (glucose.isEmpty && temps.isEmpty)
                        const Text('Aucune mesure enregistrée'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('💊 Prescriptions actives', Icons.medication),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: meds.isEmpty
                      ? const Text('Aucune prescription active')
                      : Column(
                          children: meds.map((med) => ListTile(
                            title: Text(med['medicationName']),
                            subtitle: Text(med['dosage']),
                            trailing: Chip(
                              label: Text(
                                med['isAdministered'] == true ? 'Administré' : 'En attente',
                              ),
                              // ✅ Correction: withOpacity → withValues
                              backgroundColor: med['isAdministered'] == true
                                  ? AppColors.stableGreen.withValues(alpha: 0.2)
                                  : AppColors.warningOrange.withValues(alpha: 0.2),
                            ),
                          )).toList(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.medicalBlue, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? AppColors.stableGreen : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.stableGreen;
      case 'transferred':
        return AppColors.warningOrange;
      case 'archived':
        return Colors.grey;
      default:
        return AppColors.medicalBlue;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'transferred':
        return Icons.swap_horiz;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Dossier actif';
      case 'transferred':
        return 'Transféré';
      case 'archived':
        return 'Archivé';
      default:
        return 'Statut inconnu';
    }
  }
}