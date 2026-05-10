import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/alert_service.dart';
import '../../../shared/models/dossier_model.dart';
import 'steps/step1_service.dart';
import 'steps/step2_identification.dart';
import 'steps/step3_birth_data.dart';
import 'steps/step4_systematic_gestures.dart';
import 'steps/step5_resuscitation.dart';
import 'steps/step6_transfer.dart';
import '../../../shared/extensions/context_ext.dart';

/// Create Dossier Screen - 7-step wizard for creating a new neonatal dossier
class CreateDossierScreen extends ConsumerStatefulWidget {
  const CreateDossierScreen({super.key});

  @override
  ConsumerState<CreateDossierScreen> createState() =>
      _CreateDossierScreenState();
}

class _CreateDossierScreenState extends ConsumerState<CreateDossierScreen> {
  int _currentStep = 0;
  final Map<String, dynamic> _formData = {};
  String _dossierId = '';
  String _serviceType = '';
  bool _isSaving = false;

  final List<StepWidget> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializeSteps();
  }

  void _initializeSteps() {
    _steps.clear();
    _steps.add(StepWidget(
      title: 'Service',
      subtitle: 'Prématuré ou à terme',
      widget: Step1Service(
        onServiceSelected: (value) {
          setState(() {
            _serviceType = value;
            _formData['serviceType'] = value;
          });
        },
        initialValue: _serviceType,
      ),
    ));
    _steps.add(StepWidget(
      title: 'Identification',
      subtitle: 'Nouveau-né et mère',
      widget: Step2Identification(
        onChanged: (data) => _formData.addAll(data),
        initialData: _formData,
      ),
    ));
    _steps.add(StepWidget(
      title: 'Données naissance',
      subtitle: 'Poids, température, APGAR',
      widget: Step3BirthData(
        onChanged: (data) => _formData.addAll(data),
        initialData: _formData,
      ),
    ));
    _steps.add(StepWidget(
      title: 'Gestes systématiques',
      subtitle: 'Soins immédiats',
      widget: Step4SystematicGestures(
        onChanged: (data) => _formData.addAll(data),
        initialData: _formData,
      ),
    ));
    _steps.add(StepWidget(
      title: 'Réanimation',
      subtitle: 'Si nécessaire',
      widget: Step5Resuscitation(
        onChanged: (data) => _formData.addAll(data),
        initialData: _formData,
      ),
    ));
    _steps.add(StepWidget(
      title: 'Transfert',
      subtitle: 'Destination',
      widget: Step6Transfer(
        dossierId: _dossierId,
        onChanged: (data) => _formData.addAll(data),
        initialData: _formData,
      ),
    ));
  }

  Future<void> _saveDossier() async {
    if (_serviceType.isEmpty) {
      context.showErrorSnackBar('Veuillez sélectionner un service');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final collection = _serviceType == AppConstants.servicePremature
          ? AppConstants.dossiersPrematuresCollection
          : AppConstants.dossiersATermeCollection;

      // Generate dossier number
      final timestamp = DateTime.now();
      final dateStr =
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
      final sequence = DateTime.now().millisecondsSinceEpoch % 1000;
      final dossierNumber =
          'DOS-$dateStr-${sequence.toString().padLeft(3, '0')}';
      _formData['dossierNumber'] = dossierNumber;
      _formData['createdAt'] = FieldValue.serverTimestamp();
      _formData['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
      _formData['status'] = AppConstants.dossierStatusActive;

      final docRef = await FirebaseFirestore.instance
          .collection(collection)
          .add(_formData);

      _dossierId = docRef.id;

      // Generate alerts based on initial data
      final dossierModel = DossierModel.fromJson(_formData, _dossierId);
      await AlertService().evaluateAndGenerateAlerts(dossierModel);

      if (mounted) {
        context.showSuccessSnackBar('Dossier créé avec succès');
        // ✅ Correction: utiliser GoRouter.of(context) au lieu de context directement
        GoRouter.of(context).pushReplacementNamed('/dossiers/$_dossierId');
      }
    } catch (e) {
      context.showErrorSnackBar('Erreur lors de la création: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau dossier médical'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Précédent'),
            ),
          if (_currentStep < _steps.length - 1)
            TextButton.icon(
              onPressed: () => setState(() => _currentStep++),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Suivant'),
            ),
          if (_currentStep == _steps.length - 1)
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveDossier,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Créer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stableGreen,
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator sidebar
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return _buildStepIndicator(
                  number: index + 1,
                  title: step.title,
                  subtitle: step.subtitle,
                  isActive: isActive,
                  isCompleted: isCompleted,
                  onTap: () => setState(() => _currentStep = index),
                );
              }),
            ],
          ),
        ),
        // Step content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _steps[_currentStep].widget,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Step indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentStep = index),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.stableGreen
                              : (isActive
                                  ? AppColors.medicalBlue
                                  : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _steps[index].title,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.medicalBlue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        // Step content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _steps[_currentStep].widget,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator({
    required int number,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.medicalBlue.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isActive ? Border.all(color: AppColors.medicalBlue) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.stableGreen
                        : (isActive
                            ? AppColors.medicalBlue
                            : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            number.toString(),
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? AppColors.medicalBlue
                              : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StepWidget {
  final String title;
  final String subtitle;
  final Widget widget;

  StepWidget({
    required this.title,
    required this.subtitle,
    required this.widget,
  });
}
