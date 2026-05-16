import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

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
  // ✅ استخدام bool بدلاً من String لـ Oui/Non
  bool _airwayStable = true;
  bool _showBreathing = false;

  bool _breathingStable = true;
  bool _showCirculation = false;
  String _breathingType = 'VPP';

  bool _circulationStable = true;
  bool _showDisability = false;
  String _circulationType = 'VPP + compression thoracique';

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
    _airwayStable = widget.initialData['airwayStable'] ?? true;
    _showBreathing = !_airwayStable;

    _breathingStable = widget.initialData['breathingStable'] ?? true;
    _breathingType = widget.initialData['breathingType'] ?? 'VPP';
    _showCirculation = !_breathingStable && _showBreathing;

    _circulationStable = widget.initialData['circulationStable'] ?? true;
    _circulationType =
        widget.initialData['circulationType'] ?? 'VPP + compression thoracique';
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
      'airwayStable': _airwayStable,
      'breathingStable': _breathingStable,
      'breathingType': _breathingType,
      'circulationStable': _circulationStable,
      'circulationType': _circulationType,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. AIRWAY
          _buildStepCard(
            number: '1',
            title: 'AIRWAY',
            subtitle: 'Voies aériennes',
            color: const Color(0xFFFF3B3B),
            child: Column(
              children: [
                _buildYesNoCard(
                  question: 'Les voies aériennes sont-elles stables ?',
                  value: _airwayStable,
                  onChanged: (value) {
                    setState(() {
                      _airwayStable = value;
                      _showBreathing = !value;
                      if (_airwayStable) {
                        _showCirculation = false;
                        _showDisability = false;
                      }
                    });
                    _notifyParent();
                  },
                ),
              ],
            ),
          ),

          if (_showBreathing) ...[
            const SizedBox(height: 20),

            // 2. BREATHING
            _buildStepCard(
              number: '2',
              title: 'BREATHING',
              subtitle: 'Ventilation',
              color: const Color(0xFFFFA500),
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'Type de support',
                    value: _breathingType,
                    items: const [
                      DropdownMenuItem(
                        value: 'VPP',
                        child: Text('VPP (Ventilation au masque)'),
                      ),
                      DropdownMenuItem(value: 'CPAP', child: Text('CPAP')),
                      DropdownMenuItem(
                        value: 'Ajuster O2',
                        child: Text('Ajuster O2'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _breathingType = value!);
                      _notifyParent();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildYesNoCard(
                    question: 'État stabilisé après intervention ?',
                    value: _breathingStable,
                    onChanged: (value) {
                      setState(() {
                        _breathingStable = value;
                        _showCirculation = !value;
                      });
                      _notifyParent();
                    },
                  ),
                ],
              ),
            ),
          ],

          if (_showCirculation) ...[
            const SizedBox(height: 20),

            // 3. CIRCULATION
            _buildStepCard(
              number: '3',
              title: 'CIRCULATION',
              subtitle: 'Circulation',
              color: const Color(0xFFFF3B3B),
              child: Column(
                children: [
                  _buildDropdown(
                    label: 'Intervention',
                    value: _circulationType,
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
                      setState(() => _circulationType = value!);
                      _notifyParent();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildYesNoCard(
                    question: 'État stabilisé après intervention ?',
                    value: _circulationStable,
                    onChanged: (value) {
                      setState(() {
                        _circulationStable = value;
                        _showDisability = !value;
                      });
                      _notifyParent();
                    },
                  ),
                ],
              ),
            ),
          ],

          if (_showDisability) ...[
            const SizedBox(height: 20),

            // 4. DISABILITY
            _buildStepCard(
              number: '4',
              title: 'DISABILITY',
              subtitle: 'Médicaments',
              color: const Color(0xFFFFD700),
              child: Column(
                children: [
                  _buildTextField(
                    controller: TextEditingController(text: _medications),
                    label: 'Médicaments administrés',
                    icon: Icons.medication,
                    hint: 'Ex: Adrénaline, Naloxone...',
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
                    controller: TextEditingController(
                      text: _disabilityObservations,
                    ),
                    label: 'Observations',
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

          const SizedBox(height: 20),

          // Personnel présent
          _buildStepCard(
            number: '👥',
            title: 'PERSONNEL',
            subtitle: 'Intervenants',
            color: AppColors.medicalBlue,
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

  Widget _buildStepCard({
    required String number,
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoCard({
    required String question,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildYesNoButton(
                label: 'Oui',
                isSelected: value == true,
                color: AppColors.stableGreen,
                onTap: () => onChanged(true),
              ),
              const SizedBox(width: 20),
              _buildYesNoButton(
                label: 'Non',
                isSelected: value == false,
                color: AppColors.emergencyRed,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.medicalBlue)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.medicalBlue, width: 2),
        ),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
