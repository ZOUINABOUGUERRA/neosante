//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/pdf_service.dart';
// import '../../../../services/backup_service.dart'; // ❌ تم إزالة الاستيراد غير المستخدم
import '../../../../shared/extensions/context_ext.dart';

/// Step 7: Surveillance monitoring (glucose, temperature, medications, observations)
class Step7Surveillance extends StatefulWidget {
  final String dossierId;
  final String dossierType; // 'dossiers_prematures' or 'dossiers_a_terme'
  final String dossierNumber;
  final String newbornName;

  const Step7Surveillance({
    super.key,
    required this.dossierId,
    required this.dossierType,
    required this.dossierNumber,
    required this.newbornName,
  });

  @override
  State<Step7Surveillance> createState() => _Step7SurveillanceState();
}

class _Step7SurveillanceState extends State<Step7Surveillance>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data lists
  List<Map<String, dynamic>> _glucoseReadings = [];
  List<Map<String, dynamic>> _temperatureReadings = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _observations = [];

  // Form controllers
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _medicationNameController =
      TextEditingController();
  final TextEditingController _medicationDosageController =
      TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSurveillanceData();
  }

  Future<void> _loadSurveillanceData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .where('dossierId', isEqualTo: widget.dossierId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'];
        if (type == 'glucose') {
          _glucoseReadings.add({'id': doc.id, ...data});
        } else if (type == 'temperature') {
          _temperatureReadings.add({'id': doc.id, ...data});
        } else if (type == 'medication') {
          _medications.add({'id': doc.id, ...data});
        } else if (type == 'observation') {
          _observations.add({'id': doc.id, ...data});
        }
      }

      // Sort by date
      _glucoseReadings
          .sort((a, b) => b['recordedAt'].compareTo(a['recordedAt']));
      _temperatureReadings
          .sort((a, b) => b['recordedAt'].compareTo(a['recordedAt']));
      _medications
          .sort((a, b) => b['prescribedAt'].compareTo(a['prescribedAt']));
      _observations.sort((a, b) => b['recordedAt'].compareTo(a['recordedAt']));
    } catch (e) {
      debugPrint('Error loading surveillance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addGlucose() async {
    final value = double.tryParse(_glucoseController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une valeur valide')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .doc();

      await docRef.set({
        'id': docRef.id,
        'dossierId': widget.dossierId,
        'type': 'glucose',
        'value': value,
        'unit': 'mg/dL',
        'recordedAt': FieldValue.serverTimestamp(),
        'recordedBy': currentUser?.uid,
      });

      _glucoseReadings.insert(0, {
        'id': docRef.id,
        'value': value,
        'recordedAt': DateTime.now(),
      });
      _glucoseController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTemperature() async {
    final value = double.tryParse(_temperatureController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une valeur valide')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .doc();

      await docRef.set({
        'id': docRef.id,
        'dossierId': widget.dossierId,
        'type': 'temperature',
        'value': value,
        'unit': '°C',
        'recordedAt': FieldValue.serverTimestamp(),
        'recordedBy': currentUser?.uid,
      });

      _temperatureReadings.insert(0, {
        'id': docRef.id,
        'value': value,
        'recordedAt': DateTime.now(),
      });
      _temperatureController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMedication() async {
    final name = _medicationNameController.text.trim();
    final dosage = _medicationDosageController.text.trim();

    if (name.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .doc();

      await docRef.set({
        'id': docRef.id,
        'dossierId': widget.dossierId,
        'type': 'medication',
        'medicationName': name,
        'dosage': dosage,
        'prescribedAt': FieldValue.serverTimestamp(),
        'prescribedBy': currentUser?.uid,
        'isAdministered': false,
      });

      _medications.insert(0, {
        'id': docRef.id,
        'medicationName': name,
        'dosage': dosage,
        'prescribedAt': DateTime.now(),
        'isAdministered': false,
      });
      _medicationNameController.clear();
      _medicationDosageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addObservation() async {
    final content = _observationController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une observation')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .doc();

      await docRef.set({
        'id': docRef.id,
        'dossierId': widget.dossierId,
        'type': 'observation',
        'content': content,
        'recordedAt': FieldValue.serverTimestamp(),
        'recordedBy': currentUser?.uid,
      });

      _observations.insert(0, {
        'id': docRef.id,
        'content': content,
        'recordedAt': DateTime.now(),
      });
      _observationController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _endCase() async {
    final confirmed = await context.showConfirmationDialog(
      title: 'Clôturer le dossier',
      message: 'Êtes-vous sûr de vouloir clôturer ce dossier ?\n\n'
          '⚠️ Cette action va :\n'
          '- Archiver le dossier\n'
          '- Générer un PDF récapitulatif\n'
          '- Le retirer des dossiers actifs',
      confirmText: 'Clôturer',
      confirmColor: AppColors.emergencyRed,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // Update dossier status to archived
      await FirebaseFirestore.instance
          .collection(widget.dossierType)
          .doc(widget.dossierId)
          .update({
        'status': AppConstants.dossierStatusArchived,
        'archivedAt': FieldValue.serverTimestamp(),
      });

      // ✅ PDF generation is now implemented
      await PdfService.generateAndSave(widget.dossierId, widget.dossierType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dossier clôturé et archivé avec succès'),
            backgroundColor: AppColors.stableGreen,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.medicalBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.medicalBlue,
              tabs: const [
                Tab(icon: Icon(Icons.science), text: 'Glycémie'),
                Tab(icon: Icon(Icons.thermostat), text: 'Température'),
                Tab(icon: Icon(Icons.medication), text: 'Médicaments'),
                Tab(icon: Icon(Icons.note), text: 'Observations'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGlucoseTab(),
                      _buildTemperatureTab(),
                      _buildMedicationsTab(),
                      _buildObservationsTab(),
                    ],
                  ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PdfService.generateAndPrint(
                      widget.dossierId,
                      widget.dossierType,
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimer PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _endCase,
                    icon: const Icon(Icons.archive),
                    label: const Text('Clôturer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
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

  Widget _buildGlucoseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajouter une mesure',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _glucoseController,
                        decoration: const InputDecoration(
                          labelText: 'Glycémie',
                          suffixText: 'mg/dL',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addGlucose,
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_glucoseReadings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucune mesure de glycémie'),
            ),
          )
        else
          ..._glucoseReadings.map((reading) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getGlucoseColor(reading['value']),
                    child: Text(
                      reading['value'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('Glycémie: ${reading['value']} mg/dL'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(
                      (reading['recordedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    ),
                  ),
                  trailing: Icon(
                    _getGlucoseStatusIcon(reading['value']),
                    color: _getGlucoseColor(reading['value']),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildTemperatureTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajouter une mesure',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _temperatureController,
                        decoration: const InputDecoration(
                          labelText: 'Température',
                          suffixText: '°C',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addTemperature,
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_temperatureReadings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucune mesure de température'),
            ),
          )
        else
          ..._temperatureReadings.map((reading) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTemperatureColor(reading['value']),
                    child: Text(
                      '${reading['value'].toStringAsFixed(1)}°',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('Température: ${reading['value']} °C'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(
                      (reading['recordedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    ),
                  ),
                  trailing: Icon(
                    _getTemperatureStatusIcon(reading['value']),
                    color: _getTemperatureColor(reading['value']),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildMedicationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prescrire un médicament',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _medicationNameController,
                  decoration: const InputDecoration(
                    labelText: 'Médicament',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _medicationDosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage / Voie',
                    hintText: 'Ex: 0.1 mg/kg IV',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _addMedication,
                  child: const Text('Prescrire'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_medications.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucune prescription'),
            ),
          )
        else
          ..._medications.map((med) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: med['isAdministered'] == true
                        ? AppColors.stableGreen
                        : AppColors.warningOrange,
                    child: Icon(
                      med['isAdministered'] == true
                          ? Icons.check
                          : Icons.pending,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(med['medicationName']),
                  subtitle: Text('${med['dosage']}'),
                  trailing: Text(
                    DateFormat('dd/MM/yyyy', 'fr_FR').format(
                      (med['prescribedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildObservationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajouter une observation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _observationController,
                  decoration: const InputDecoration(
                    labelText: 'Observation clinique',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _addObservation,
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_observations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucune observation'),
            ),
          )
        else
          ..._observations.map((obs) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.medicalBlue,
                    child: Icon(Icons.note, color: Colors.white),
                  ),
                  title: Text(obs['content']),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(
                      (obs['recordedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Color _getGlucoseColor(double value) {
    if (value < 40) return AppColors.emergencyRed;
    if (value < 45) return AppColors.warningOrange;
    if (value > 150) return AppColors.mediumYellow;
    return AppColors.stableGreen;
  }

  IconData _getGlucoseStatusIcon(double value) {
    if (value < 40) return Icons.warning;
    if (value < 45) return Icons.info;
    if (value > 150) return Icons.warning;
    return Icons.check_circle;
  }

  Color _getTemperatureColor(double value) {
    if (value < 32) return AppColors.emergencyRed;
    if (value < 36) return AppColors.warningOrange;
    if (value > 37.5) return AppColors.emergencyRed;
    return AppColors.stableGreen;
  }

  IconData _getTemperatureStatusIcon(double value) {
    if (value < 32) return Icons.warning;
    if (value < 36) return Icons.thermostat;
    if (value > 37.5) return Icons.sick;
    return Icons.check_circle;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glucoseController.dispose();
    _temperatureController.dispose();
    _medicationNameController.dispose();
    _medicationDosageController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}