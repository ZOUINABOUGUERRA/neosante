import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/pdf_service.dart';
import '../../../../shared/extensions/context_ext.dart';

class Step7Surveillance extends StatefulWidget {
  final String dossierId;
  final String dossierType;
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
  State<Step7Surveillance> createState() =>
      _Step7SurveillanceState();
}

class _Step7SurveillanceState extends State<Step7Surveillance>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _glucoseController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _medNameController = TextEditingController();
  final _medDoseController = TextEditingController();
  final _obsController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
  }

  // ================= STREAM =================

  Stream<QuerySnapshot> _stream(String type) {
    return FirebaseFirestore.instance
        .collection(AppConstants.surveillanceCollection)
        .where('dossierId', isEqualTo: widget.dossierId)
        .where('type', isEqualTo: type)
        .orderBy('recordedAt', descending: true)
        .snapshots();
  }

  // ================= ADD FUNCTIONS =================

  Future<void> _add(String type, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance
          .collection(AppConstants.surveillanceCollection)
          .add({
        'dossierId': widget.dossierId,
        'type': type,
        ...data,
        'recordedAt': FieldValue.serverTimestamp(),
        'recordedBy': uid,
      });

      context.showSuccessSnackBar("Ajouté avec succès");
    } catch (e) {
      context.showErrorSnackBar("Erreur: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.newbornName),
        backgroundColor: AppColors.medicalBlue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.science), text: "Glycémie"),
            Tab(icon: Icon(Icons.thermostat), text: "Temp"),
            Tab(icon: Icon(Icons.medication), text: "Médicaments"),
            Tab(icon: Icon(Icons.notes), text: "Obs"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlucose(),
          _buildTemperature(),
          _buildMedications(),
          _buildObservations(),
        ],
      ),

      bottomNavigationBar: _buildActions(),
    );
  }

  // ================= GLUCOSE =================

  Widget _buildGlucose() {
    return Column(
      children: [
        _inputCard(
          controller: _glucoseController,
          label: "Glycémie (mg/dL)",
          buttonText: "Ajouter",
          onAdd: () {
            final value = double.tryParse(_glucoseController.text);
            if (value == null) return;

            _add("glucose", {"value": value, "unit": "mg/dL"});
            _glucoseController.clear();
          },
        ),
        Expanded(
          child: StreamBuilder(
            stream: _stream("glucose"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final v = (d['value'] ?? 0).toDouble();

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.bloodtype,
                        color: _glucoseColor(v),
                      ),
                      title: Text("$v mg/dL"),
                      subtitle: Text(_format(d['recordedAt'])),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= TEMPERATURE =================

  Widget _buildTemperature() {
    return Column(
      children: [
        _inputCard(
          controller: _temperatureController,
          label: "Température (°C)",
          buttonText: "Ajouter",
          onAdd: () {
            final value = double.tryParse(_temperatureController.text);
            if (value == null) return;

            _add("temperature", {"value": value, "unit": "°C"});
            _temperatureController.clear();
          },
        ),
        Expanded(
          child: StreamBuilder(
            stream: _stream("temperature"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView(
                children: docs.map((d) {
                  final v = (d['value'] ?? 0).toDouble();

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.thermostat,
                        color: _tempColor(v),
                      ),
                      title: Text("$v °C"),
                      subtitle: Text(_format(d['recordedAt'])),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= MEDICATIONS =================

  Widget _buildMedications() {
    return Column(
      children: [
        _inputCard(
          controller: _medNameController,
          label: "Médicament",
          secondController: _medDoseController,
          secondLabel: "Dosage",
          buttonText: "Prescrire",
          onAdd: () {
            if (_medNameController.text.isEmpty ||
                _medDoseController.text.isEmpty) return;

            _add("medication", {
              "medicationName": _medNameController.text,
              "dosage": _medDoseController.text,
              "isAdministered": false,
            });

            _medNameController.clear();
            _medDoseController.clear();
          },
        ),
        Expanded(
          child: StreamBuilder(
            stream: _stream("medication"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView(
                children: docs.map((d) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.medication),
                      title: Text(d['medicationName'] ?? ''),
                      subtitle: Text(d['dosage'] ?? ''),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= OBSERVATIONS =================

  Widget _buildObservations() {
    return Column(
      children: [
        _inputCard(
          controller: _obsController,
          label: "Observation",
          buttonText: "Ajouter",
          maxLines: 3,
          onAdd: () {
            if (_obsController.text.isEmpty) return;

            _add("observation", {
              "content": _obsController.text,
            });

            _obsController.clear();
          },
        ),
        Expanded(
          child: StreamBuilder(
            stream: _stream("observation"),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView(
                children: docs.map((d) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.note),
                      title: Text(d['content'] ?? ''),
                      subtitle: Text(_format(d['recordedAt'])),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= INPUT CARD =================

  Widget _inputCard({
    required TextEditingController controller,
    required String label,
    TextEditingController? secondController,
    String? secondLabel,
    required String buttonText,
    int maxLines = 1,
    required VoidCallback onAdd,
  }) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label),
              maxLines: maxLines,
            ),
            if (secondController != null)
              TextField(
                controller: secondController,
                decoration: InputDecoration(labelText: secondLabel),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onAdd,
              child: Text(buttonText),
            )
          ],
        ),
      ),
    );
  }

  // ================= ACTIONS =================

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                PdfService.generateAndPrint(
                  widget.dossierId,
                  widget.dossierType,
                );
              },
              icon: const Icon(Icons.print),
              label: const Text("PDF"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {},
              icon: const Icon(Icons.close),
              label: const Text("Clôturer"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  String _format(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    return DateFormat('dd/MM HH:mm').format(d);
  }

  Color _glucoseColor(double v) =>
      v < 40 ? Colors.red : (v > 150 ? Colors.orange : Colors.green);

  Color _tempColor(double v) =>
      v < 36 ? Colors.orange : (v > 37.5 ? Colors.red : Colors.green);

  @override
  void dispose() {
    _tabController.dispose();
    _glucoseController.dispose();
    _temperatureController.dispose();
    _medNameController.dispose();
    _medDoseController.dispose();
    _obsController.dispose();
    super.dispose();
  }
}