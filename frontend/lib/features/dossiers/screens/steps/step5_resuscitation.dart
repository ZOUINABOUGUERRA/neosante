import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
//import '../../../../core/constants/app_constants.dart';

/// Step 5: Resuscitation workflow (Airway → Breathing → Circulation → Disability)
class Step5Resuscitation extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic> initialData;

  const Step5Resuscitation({
    super.key,
    required this.onChanged,
    required this.initialData,
  });

  @override
  State<Step5Resuscitation> createState() => _Step5ResuscitationState();
}

class _Step5ResuscitationState extends State<Step5Resuscitation> {
  // Airway
  String _airway = 'stable';
  bool _showBreathing = false;

  // Breathing
  String _breathing = 'VPP';
  bool _breathingStable = true;
  bool _showCirculation = false;

  // Circulation
  String _circulation = 'VPP + compression thoracique';
  bool _circulationStable = true;
  bool _showDisability = false;

  // Disability
  String _medications = '';
  String _doses = '';
  String _disabilityObservations = '';
  String _doctorName = '';
  String _sageFemmeName = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _airway = widget.initialData['airway'] ?? 'stable';
    _showBreathing = _airway == 'unstable';

    _breathing = widget.initialData['breathing'] ?? 'VPP';
    _breathingStable = widget.initialData['breathingStable'] ?? true;
    _showCirculation = !_breathingStable && _showBreathing;

    _circulation =
        widget.initialData['circulation'] ?? 'VPP + compression thoracique';
    _circulationStable = widget.initialData['circulationStable'] ?? true;
    _showDisability = !_circulationStable && _showCirculation;

    _medications = widget.initialData['disabilityMedications'] ?? '';
    _doses = widget.initialData['disabilityDoses'] ?? '';
    _disabilityObservations =
        widget.initialData['disabilityObservations'] ?? '';
    _doctorName = widget.initialData['doctorName'] ?? '';
    _sageFemmeName = widget.initialData['sageFemmeName'] ?? '';
  }

  void _notifyParent() {
    widget.onChanged({
      'airway': _airway,
      'breathing': _breathing,
      'breathingStable': _breathingStable,
      'circulation': _circulation,
      'circulationStable': _circulationStable,
      'disabilityMedications': _medications,
      'disabilityDoses': _doses,
      'disabilityObservations': _disabilityObservations,
      'doctorName': _doctorName,
      'sageFemmeName': _sageFemmeName,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Airway Section
          _buildSectionHeader('1. AIRWAY (Voies aériennes)', Icons.air,
              const Color(0xFFFF3B3B)),
          const SizedBox(height: 8),
          _buildWorkflowCard(
            title: 'Évaluation des voies aériennes',
            child: Column(
              children: [
                _buildRadioTile(
                  title: '✅ Stable - Respiration spontanée efficace',
                  value: 'stable',
                  groupValue: _airway,
                  onChanged: (value) {
                    setState(() {
                      _airway = value!;
                      _showBreathing = false;
                      _showCirculation = false;
                      _showDisability = false;
                    });
                    _notifyParent();
                  },
                  color: AppColors.stableGreen,
                ),
                const SizedBox(height: 8),
                _buildRadioTile(
                  title: '⚠️ Instable - Obstruction / Apnée',
                  value: 'unstable',
                  groupValue: _airway,
                  onChanged: (value) {
                    setState(() {
                      _airway = value!;
                      _showBreathing = true;
                    });
                    _notifyParent();
                  },
                  color: AppColors.emergencyRed,
                ),
              ],
            ),
          ),

          if (_showBreathing) ...[
            const SizedBox(height: 24),

            // Breathing Section
            _buildSectionHeader('2. BREATHING (Ventilation)', Icons.air,
                const Color(0xFFFFA500)),
            const SizedBox(height: 8),
            _buildWorkflowCard(
              title: 'Support ventilatoire',
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'Type de support',
                    value: _breathing,
                    items: const [
                      DropdownMenuItem(
                          value: 'VPP',
                          child: Text('VPP (Ventilation au masque)')),
                      DropdownMenuItem(
                          value: 'CPAP',
                          child: Text('CPAP (Pression positive continue)')),
                      DropdownMenuItem(
                          value: 'Ajuster O2',
                          child: Text('Ajuster O2 (Oxygénothérapie)')),
                    ],
                    onChanged: (value) {
                      setState(() => _breathing = value!);
                      _notifyParent();
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'État après intervention :',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRadioTile(
                          title: '✅ Stabilisé',
                          value: true,
                          groupValue: _breathingStable,
                          onChanged: (value) {
                            setState(() {
                              _breathingStable = value!;
                              _showCirculation = false;
                              _showDisability = false;
                            });
                            _notifyParent();
                          },
                          color: AppColors.stableGreen,
                        ),
                      ),
                      Expanded(
                        child: _buildRadioTile(
                          title: '⚠️ Instable',
                          value: false,
                          groupValue: _breathingStable,
                          onChanged: (value) {
                            setState(() {
                              _breathingStable = value!;
                              _showCirculation = true;
                            });
                            _notifyParent();
                          },
                          color: AppColors.emergencyRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (_showCirculation) ...[
            const SizedBox(height: 24),

            // Circulation Section
            _buildSectionHeader('3. CIRCULATION (Circulation)', Icons.favorite,
                const Color(0xFFFF3B3B)),
            const SizedBox(height: 8),
            _buildWorkflowCard(
              title: 'Support circulatoire',
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'Intervention',
                    value: _circulation,
                    items: const [
                      DropdownMenuItem(
                        value: 'VPP + compression thoracique',
                        child: Text('VPP + Compression thoracique'),
                      ),
                      DropdownMenuItem(
                        value: 'intubation',
                        child: Text('Intubation trachéale'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _circulation = value!);
                      _notifyParent();
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'État après intervention :',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRadioTile(
                          title: '✅ Stabilisé',
                          value: true,
                          groupValue: _circulationStable,
                          onChanged: (value) {
                            setState(() {
                              _circulationStable = value!;
                              _showDisability = false;
                            });
                            _notifyParent();
                          },
                          color: AppColors.stableGreen,
                        ),
                      ),
                      Expanded(
                        child: _buildRadioTile(
                          title: '⚠️ Instable',
                          value: false,
                          groupValue: _circulationStable,
                          onChanged: (value) {
                            setState(() {
                              _circulationStable = value!;
                              _showDisability = true;
                            });
                            _notifyParent();
                          },
                          color: AppColors.emergencyRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (_showDisability) ...[
            const SizedBox(height: 24),

            // Disability Section
            _buildSectionHeader('4. DISABILITY (Médicaments)', Icons.medication,
                const Color(0xFFFFD700)),
            const SizedBox(height: 8),
            _buildWorkflowCard(
              title: 'Interventions médicamenteuses',
              child: Column(
                children: [
                  _buildTextField(
                    controller: TextEditingController(text: _medications),
                    label: 'Médicaments administrés',
                    icon: Icons.medication,
                    hint: 'Ex: Adrénaline, Naloxone, Bicarbonate...',
                    maxLines: 2,
                    onChanged: (value) {
                      _medications = value;
                      _notifyParent();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: TextEditingController(text: _doses),
                    label: 'Dosages',
                    icon: Icons.science,
                    hint: 'Ex: Adrénaline 0.01 mg/kg IV',
                    onChanged: (value) {
                      _doses = value;
                      _notifyParent();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller:
                        TextEditingController(text: _disabilityObservations),
                    label: 'Observations cliniques',
                    icon: Icons.note,
                    hint: 'Évolution, réponse au traitement...',
                    maxLines: 3,
                    onChanged: (value) {
                      _disabilityObservations = value;
                      _notifyParent();
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          _buildSectionHeader(
              '👨‍⚕️ Personnel présent', Icons.people, AppColors.medicalBlue),
          const SizedBox(height: 8),
          _buildWorkflowCard(
            title: 'Médecins et sages-femmes intervenants',
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: TextEditingController(text: _doctorName),
                    label: 'Nom du médecin',
                    icon: Icons.medical_information,
                    onChanged: (value) {
                      _doctorName = value;
                      _notifyParent();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: TextEditingController(text: _sageFemmeName),
                    label: 'Nom de la sage-femme',
                    icon: Icons.person,
                    onChanged: (value) {
                      _sageFemmeName = value;
                      _notifyParent();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required dynamic value,
    required dynamic groupValue,
    required Function(dynamic) onChanged,
    required Color color,
  }) {
    return RadioListTile<dynamic>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: color,
      contentPadding: EdgeInsets.zero,
      dense: true,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
