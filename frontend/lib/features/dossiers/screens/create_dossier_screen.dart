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
import 'steps/step7_surveillance.dart';

import '../../../shared/extensions/context_ext.dart';

class CreateDossierScreen extends ConsumerStatefulWidget {
  const CreateDossierScreen({super.key});

  @override
  ConsumerState<CreateDossierScreen> createState() =>
      _CreateDossierScreenState();
}

class _CreateDossierScreenState
    extends ConsumerState<CreateDossierScreen> {
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

    _steps.add(
      StepWidget(
        title: '🏥 Service',
        subtitle: 'Prématuré ou à terme',
        widget: Step1Service(
          onServiceSelected: (value) {
            setState(() {
              _serviceType = value;
              _formData['serviceType'] = value;

              _initializeSteps();
            });
          },
          initialValue: _serviceType,
          isTransferMode: false,
        ),
      ),
    );

    _steps.add(
      StepWidget(
        title: '👶 Identification',
        subtitle: 'Nouveau-né et mère',
        widget: Step2Identification(
          onChanged: (data) => _formData.addAll(data),
          initialData: _formData,
        ),
      ),
    );

    _steps.add(
      StepWidget(
        title: '📊 Données',
        subtitle: 'Poids, température, APGAR',
        widget: Step3BirthData(
          onChanged: (data) => _formData.addAll(data),
          initialData: _formData,
        ),
      ),
    );

    _steps.add(
      StepWidget(
        title: '🔧 Gestes',
        subtitle: 'Soins immédiats',
        widget: Step4SystematicGestures(
          onChanged: (data) => _formData.addAll(data),
          initialData: _formData,
        ),
      ),
    );

    _steps.add(
      StepWidget(
        title: '🫀 Réanimation',
        subtitle: 'Si nécessaire',
        widget: Step5Resuscitation(
          onChanged: (data) => _formData.addAll(data),
          initialData: _formData,
        ),
      ),
    );

    _steps.add(
      StepWidget(
        title: '🚑 Transfert',
        subtitle: 'Destination',
        widget: Step6Transfer(
          dossierId: _dossierId,
          onChanged: (data) => _formData.addAll(data),
          initialData: _formData,
        ),
      ),
    );

    if (_dossierId.isNotEmpty) {
      _steps.add(
        StepWidget(
          title: '📈 Surveillance',
          subtitle: 'Glycémie, température',
          widget: Step7Surveillance(
            dossierId: _dossierId,
            dossierType:
                _serviceType ==
                        AppConstants.servicePremature
                    ? AppConstants
                        .dossiersPrematuresCollection
                    : AppConstants
                        .dossiersATermeCollection,
            dossierNumber:
                _formData['dossierNumber'] ?? '',
            newbornName:
                _formData['newbornName'] ?? '',
          ),
        ),
      );
    }
  }

  void _updateStep7WithDossierInfo() {
    setState(() {
      _initializeSteps();
    });
  }

  Future<void> _saveDossier() async {
    if (_serviceType.isEmpty) {
      context.showErrorSnackBar(
        'Veuillez sélectionner un service',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final collection =
          _serviceType ==
                  AppConstants.servicePremature
              ? AppConstants
                  .dossiersPrematuresCollection
              : AppConstants
                  .dossiersATermeCollection;

      final timestamp = DateTime.now();

      final dateStr =
          '${timestamp.year}'
          '${timestamp.month.toString().padLeft(2, '0')}'
          '${timestamp.day.toString().padLeft(2, '0')}';

      final sequence =
          DateTime.now().millisecondsSinceEpoch % 1000;

      final dossierNumber =
          'DOS-$dateStr-${sequence.toString().padLeft(3, '0')}';

      _formData['dossierNumber'] = dossierNumber;

      final now = DateTime.now();

      _formData['createdAt'] = now;
      _formData['createdBy'] =
          FirebaseAuth.instance.currentUser?.uid;
      _formData['status'] =
          AppConstants.dossierStatusActive;

      final docRef = await FirebaseFirestore.instance
          .collection(collection)
          .add(_formData);

      _dossierId = docRef.id;

      debugPrint(
        '🟢 Dossier créé avec ID: $_dossierId',
      );

      _updateStep7WithDossierInfo();

      final dossierModel = DossierModel.fromJson(
        _formData,
        _dossierId,
      );

      await AlertService()
          .evaluateAndGenerateAlerts(dossierModel);

      if (!mounted) return;

      context.showSuccessSnackBar(
        '✅ Dossier créé avec succès',
      );

      GoRouter.of(context).goNamed(
        'dossier_detail',
        pathParameters: {'id': _dossierId},
      );
    } catch (e) {
      if (!mounted) return;

      context.showErrorSnackBar(
        '❌ Erreur: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width > 800;

    if (_steps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📝 Nouveau dossier médical',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentStep == _steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed:
                    _isSaving ? null : _saveDossier,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('💾 Créer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.stableGreen,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isDesktop
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
          ),

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
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                    label: const Text(
                      '◀ Précédent',
                    ),
                  )
                else
                  const SizedBox(width: 100),

                if (_currentStep <
                    _steps.length - 1)
                  ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(
                      Icons.arrow_forward,
                    ),
                    label: const Text(
                      'Suivant ▶',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.medicalBlue,
                      foregroundColor:
                          Colors.white,
                    ),
                  )
                else
                  const SizedBox(width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
          ),
          child: ListView.builder(
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              final step = _steps[index];

              return _buildStepIndicator(
                number: index + 1,
                title: step.title,
                subtitle: step.subtitle,
                isActive: index == _currentStep,
                isCompleted: index < _currentStep,
                onTap: () {
                  setState(() {
                    _currentStep = index;
                  });
                },
              );
            },
          ),
        ),

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
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.medicalBlue.withOpacity(
                    0.08,
                  )
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(16),
            border: isActive
                ? Border.all(
                    color: AppColors.medicalBlue,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.stableGreen
                      : isActive
                      ? AppColors.medicalBlue
                      : Colors.grey.shade300,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : Text(
                          number.toString(),
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.grey
                                    .shade700,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.medicalBlue
                            : Colors.grey.shade700,
                      ),
                    ),

                    Text(
                      subtitle,
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