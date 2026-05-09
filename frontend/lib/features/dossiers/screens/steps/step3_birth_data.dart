import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:neosante/shared/widgets/alert_card.dart';
import '../../../../core/utils/glucose_calculator.dart';
import '../../../../core/utils/apgar_evaluator.dart';

/// Step 3: Birth data (weight, temperature, glucose, APGAR, etc.)
class Step3BirthData extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic> initialData;

  const Step3BirthData({
    super.key,
    required this.onChanged,
    required this.initialData,
  });

  @override
  State<Step3BirthData> createState() => _Step3BirthDataState();
}

class _Step3BirthDataState extends State<Step3BirthData> {
  late TextEditingController _weightController;
  late TextEditingController _temperatureController;
  late TextEditingController _glucoseController;
  late TextEditingController _apgar1Controller;
  late TextEditingController _apgar5Controller;
  late TextEditingController _malformationsController;

  String _coloration = 'tout rose';
  String _respiration = 'régulière';
  String _cry = 'fort';
  String _tonus = 'bon';

  List<String> _activeAlerts = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _weightController = TextEditingController();
    _temperatureController = TextEditingController();
    _glucoseController = TextEditingController();
    _apgar1Controller = TextEditingController();
    _apgar5Controller = TextEditingController();
    _malformationsController = TextEditingController();
  }

  void _loadInitialData() {
    _weightController.text =
        widget.initialData['birthWeight']?.toString() ?? '';
    _temperatureController.text =
        widget.initialData['bodyTemperature']?.toString() ?? '';
    _glucoseController.text =
        widget.initialData['bloodGlucose']?.toString() ?? '';
    _apgar1Controller.text = widget.initialData['apgar1']?.toString() ?? '';
    _apgar5Controller.text = widget.initialData['apgar5']?.toString() ?? '';
    _malformationsController.text = widget.initialData['malformations'] ?? '';
    _coloration = widget.initialData['coloration'] ?? 'tout rose';
    _respiration = widget.initialData['respiration'] ?? 'régulière';
    _cry = widget.initialData['cry'] ?? 'fort';
    _tonus = widget.initialData['tonus'] ?? 'bon';

    _evaluateAlerts();
  }

  void _notifyParent() {
    widget.onChanged({
      'birthWeight': double.tryParse(_weightController.text) ?? 0,
      'bodyTemperature': double.tryParse(_temperatureController.text) ?? 0,
      'bloodGlucose': double.tryParse(_glucoseController.text) ?? 0,
      'apgar1': int.tryParse(_apgar1Controller.text) ?? 0,
      'apgar5': int.tryParse(_apgar5Controller.text) ?? 0,
      'coloration': _coloration,
      'respiration': _respiration,
      'cry': _cry,
      'tonus': _tonus,
      'malformations': _malformationsController.text.trim(),
    });
  }

  void _evaluateAlerts() {
    final List<String> alerts = [];

    // Evaluate glucose
    final glucose = double.tryParse(_glucoseController.text);
    if (glucose != null) {
      final evaluation = GlucoseCalculator.evaluateGlucose(glucose);
      if (evaluation.severity != AppConstants.alertSeverityInfo) {
        alerts.add(evaluation.message);
      }
    }

    // Evaluate temperature
    final temp = double.tryParse(_temperatureController.text);
    if (temp != null) {
      if (temp < AppConstants.temperatureEmergency) {
        alerts.add(
            '🔴 TEMPÉRATURE CRITIQUE: ${temp.toStringAsFixed(1)}°C - Hypothermie sévère');
      } else if (temp < AppConstants.temperatureHypothermia) {
        alerts.add(
            '🟠 HYPOTHERMIE: ${temp.toStringAsFixed(1)}°C - Réchauffement nécessaire');
      } else if (temp > AppConstants.temperatureFever) {
        alerts.add(
            '🔴 RISQUE INFECTIEUX: ${temp.toStringAsFixed(1)}°C - Évaluation urgente');
      }
    }

    // Evaluate APGAR
    final apgar1 = int.tryParse(_apgar1Controller.text);
    if (apgar1 != null) {
      final evaluation = ApgarEvaluator.evaluateApgar(apgar1, minute: 1);
      if (evaluation.severity != AppConstants.alertSeverityInfo) {
        alerts.add(evaluation.message);
      }
    }

    // Evaluate other parameters
    if (_respiration == 'absente') {
      alerts.add('🔴 RESPIRATION ABSENTE - Réanimation immédiate');
    } else if (_respiration == 'faible irrégulière') {
      alerts.add('🟠 RESPIRATION FAIBLE/IRRÉGULIÈRE - Assistance respiratoire');
    }

    if (_cry == 'absent') {
      alerts.add('🔴 CRI ABSENT - Réanimation respiratoire');
    }

    if (_tonus == 'flasque') {
      alerts.add('🟠 TONUS FLASQUE - Évaluation neurologique urgente');
    }

    setState(() {
      _activeAlerts = alerts;
    });
  }

  void _onFieldChanged(String _) {
    _evaluateAlerts();
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alerts Section
          if (_activeAlerts.isNotEmpty) ...[
            const Text(
              '⚠️ Alertes détectées',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._activeAlerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AlertCard(
                      message: alert, severity: _getAlertSeverity(alert)),
                )),
            const SizedBox(height: 24),
          ],

          // Anthropometric Data
          _buildSectionHeader('📏 Mensurations', Icons.straighten),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _weightController,
                  label: 'Poids de naissance (g)',
                  icon: Icons.monitor_weight,
                  suffix: 'g',
                  onChanged: _onFieldChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  controller: _temperatureController,
                  label: 'Température (°C)',
                  icon: Icons.thermostat,
                  suffix: '°C',
                  decimal: true,
                  onChanged: _onFieldChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _glucoseController,
            label: 'Glycémie (mg/dL)',
            icon: Icons.science,
            suffix: 'mg/dL',
            decimal: true,
            onChanged: _onFieldChanged,
          ),
          const SizedBox(height: 24),

          // APGAR Scores
          _buildSectionHeader('📊 Score APGAR', Icons.assessment),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _apgar1Controller,
                  label: 'APGAR 1 minute',
                  icon: Icons.timer,
                  suffix: '/10',
                  onChanged: _onFieldChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  controller: _apgar5Controller,
                  label: 'APGAR 5 minutes',
                  icon: Icons.timer,
                  suffix: '/10',
                  onChanged: _onFieldChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Clinical Evaluation
          _buildSectionHeader(
              '🩺 Évaluation clinique', Icons.medical_information),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Coloration',
            value: _coloration,
            items: const [
              DropdownMenuItem(value: 'bleu/pâle', child: Text('Bleu / Pâle')),
              DropdownMenuItem(
                value: 'corps rose extrémités bleues',
                child: Text('Corps rose, extrémités bleues'),
              ),
              DropdownMenuItem(value: 'tout rose', child: Text('Tout rose')),
            ],
            onChanged: (value) {
              setState(() => _coloration = value!);
              _evaluateAlerts();
              _notifyParent();
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Respiration',
            value: _respiration,
            items: const [
              DropdownMenuItem(value: 'absente', child: Text('Absente')),
              DropdownMenuItem(
                  value: 'faible irrégulière',
                  child: Text('Faible / Irrégulière')),
              DropdownMenuItem(value: 'régulière', child: Text('Régulière')),
            ],
            onChanged: (value) {
              setState(() => _respiration = value!);
              _evaluateAlerts();
              _notifyParent();
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Cri',
            value: _cry,
            items: const [
              DropdownMenuItem(value: 'absent', child: Text('Absent')),
              DropdownMenuItem(value: 'irrégulier', child: Text('Irrégulier')),
              DropdownMenuItem(value: 'fort', child: Text('Fort')),
            ],
            onChanged: (value) {
              setState(() => _cry = value!);
              _evaluateAlerts();
              _notifyParent();
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Tonus',
            value: _tonus,
            items: const [
              DropdownMenuItem(value: 'flasque', child: Text('Flasque')),
              DropdownMenuItem(value: 'faible', child: Text('Faible')),
              DropdownMenuItem(value: 'bon', child: Text('Bon')),
            ],
            onChanged: (value) {
              setState(() => _tonus = value!);
              _evaluateAlerts();
              _notifyParent();
            },
          ),
          const SizedBox(height: 24),

          // Malformations
          _buildSectionHeader('🔍 Malformations', Icons.warning),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _malformationsController,
            label: 'Malformations / Problèmes médicaux',
            icon: Icons.healing,
            maxLines: 3,
            onChanged: (_) => _notifyParent(),
          ),
        ],
      ),
    );
  }

  String _getAlertSeverity(String alert) {
    if (alert.contains('🔴') || alert.contains('CRITIQUE')) {
      return 'critical';
    } else if (alert.contains('🟠')) {
      return 'warning';
    } else if (alert.contains('🟡')) {
      return 'medium';
    }
    return 'info';
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.medicalBlue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required String suffix,
    bool decimal = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: decimal
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _temperatureController.dispose();
    _glucoseController.dispose();
    _apgar1Controller.dispose();
    _apgar5Controller.dispose();
    _malformationsController.dispose();
    super.dispose();
  }
}
