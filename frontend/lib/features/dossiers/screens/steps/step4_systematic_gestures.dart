import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class Step4SystematicGestures extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic> initialData;

  const Step4SystematicGestures({
    super.key,
    required this.onChanged,
    required this.initialData,
  });

  @override
  State<Step4SystematicGestures> createState() =>
      _Step4SystematicGesturesState();
}

class _Step4SystematicGesturesState extends State<Step4SystematicGestures> {
  bool _prechauffe = false;
  bool _sechage = false;
  bool _stimulation = false;
  String _clampage = 'tardif';
  bool _verificationTonusRespiration = false;
  String _verificationOther = '';
  String _miseSousChaleur = 'Incubateur préchauffé + bonnet';
  String _miseSousChaleurOther = '';
  bool _vitamineK = false;
  bool _bracelet = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _prechauffe = widget.initialData['prechauffe'] ?? false;
    _sechage = widget.initialData['sechage'] ?? false;
    _stimulation = widget.initialData['stimulation'] ?? false;
    _clampage = widget.initialData['clampage'] ?? 'tardif';
    _verificationTonusRespiration =
        widget.initialData['verificationTonusRespiration'] ?? false;
    _verificationOther =
        widget.initialData['verificationTonusRespirationOther'] ?? '';
    _miseSousChaleur =
        widget.initialData['miseSousChaleur'] ??
        'Incubateur préchauffé + bonnet';
    _miseSousChaleurOther = widget.initialData['miseSousChaleurOther'] ?? '';
    _vitamineK = widget.initialData['vitamineK'] ?? false;
    _bracelet = widget.initialData['bracelet'] ?? false;
  }

  void _notifyParent() {
    widget.onChanged({
      'prechauffe': _prechauffe,
      'sechage': _sechage,
      'stimulation': _stimulation,
      'clampage': _clampage,
      'verificationTonusRespiration': _verificationTonusRespiration,
      'verificationTonusRespirationOther': _verificationOther,
      'miseSousChaleur': _miseSousChaleur == 'autre'
          ? _miseSousChaleurOther
          : _miseSousChaleur,
      'miseSousChaleurOther': _miseSousChaleurOther,
      'vitamineK': _vitamineK,
      'bracelet': _bracelet,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Soins immédiats
          _buildSectionCard(
            title: '🌡️ Soins immédiats',
            icon: Icons.thermostat,
            children: [
              _buildCheckboxTile(
                title: '✅ Préchauffé',
                subtitle: 'Préchauffage de la salle de naissance / incubateur',
                value: _prechauffe,
                onChanged: (value) {
                  setState(() => _prechauffe = value!);
                  _notifyParent();
                },
              ),
              _buildCheckboxTile(
                title: '✅ Séchage complet',
                subtitle: 'Séchage complet du nouveau-né',
                value: _sechage,
                onChanged: (value) {
                  setState(() => _sechage = value!);
                  _notifyParent();
                },
              ),
              _buildCheckboxTile(
                title: '✅ Stimulation',
                subtitle: 'Stimulation tactile si nécessaire',
                value: _stimulation,
                onChanged: (value) {
                  setState(() => _stimulation = value!);
                  _notifyParent();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ Clampage
          _buildSectionCard(
            title: '🔌 Clampage du cordon',
            icon: Icons.link,
            children: [
              _buildSegmentedButton(
                value: _clampage,
                segments: const [
                  ButtonSegment(
                    value: 'immédiate',
                    label: Text('⚡ Clampage immédiat'),
                  ),
                  ButtonSegment(
                    value: 'tardif',
                    label: Text('⏱️ Clampage tardif (≥ 1 min)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _clampage = value);
                  _notifyParent();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ Vérification
          _buildSectionCard(
            title: '🫁 Vérification',
            icon: Icons.healing,
            children: [
              _buildCheckboxTile(
                title: '✅ Vérification tonus et respiration',
                subtitle: 'Évaluation clinique systématique',
                value: _verificationTonusRespiration,
                onChanged: (value) {
                  setState(() => _verificationTonusRespiration = value!);
                  _notifyParent();
                },
              ),
              if (_verificationTonusRespiration)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 8),
                  child: _buildTextField(
                    controller: TextEditingController(text: _verificationOther),
                    label: 'Observations',
                    hint: 'Détails de la vérification...',
                    onChanged: (value) {
                      _verificationOther = value;
                      _notifyParent();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ Mise sous chaleur
          _buildSectionCard(
            title: '🔥 Mise sous chaleur',
            icon: Icons.wb_sunny,
            children: [
              _buildSegmentedButton(
                value: _miseSousChaleur,
                segments: const [
                  ButtonSegment(
                    value: 'Incubateur préchauffé + bonnet',
                    label: Text('🏥 Incubateur + bonnet'),
                  ),
                  ButtonSegment(
                    value: 'lampe chauffante',
                    label: Text('💡 Lampe chauffante'),
                  ),
                  ButtonSegment(
                    value: 'peau à peau',
                    label: Text('🤱 Peau à peau'),
                  ),
                  ButtonSegment(value: 'sac', label: Text('🛍️ Sac plastique')),
                  ButtonSegment(value: 'autre', label: Text('🔧 Autre')),
                ],
                onChanged: (value) {
                  setState(() => _miseSousChaleur = value);
                  _notifyParent();
                },
              ),
              if (_miseSousChaleur == 'autre')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildTextField(
                    controller: TextEditingController(
                      text: _miseSousChaleurOther,
                    ),
                    label: 'Précisez le dispositif',
                    hint: 'Ex: Matelas chauffant...',
                    onChanged: (value) {
                      _miseSousChaleurOther = value;
                      _notifyParent();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ Vitaminothérapie
          _buildSectionCard(
            title: '💊 Vitaminothérapie',
            icon: Icons.medical_services,
            children: [
              _buildCheckboxTile(
                title: '✅ Vitamine K administrée',
                subtitle: '1 mg IM ou 2 mg VO',
                value: _vitamineK,
                onChanged: (value) {
                  setState(() => _vitamineK = value!);
                  _notifyParent();
                },
              ),
              _buildCheckboxTile(
                title: '✅ Bracelet d\'identification posé',
                subtitle: 'Identification mère-enfant',
                value: _bracelet,
                onChanged: (value) {
                  setState(() => _bracelet = value!);
                  _notifyParent();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.medicalBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.medicalBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
    String? subtitle,
  }) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.stableGreen,
      contentPadding: EdgeInsets.zero,
      dense: false,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSegmentedButton({
    required String value,
    required List<ButtonSegment<String>> segments,
    required Function(String) onChanged,
  }) {
    return SegmentedButton<String>(
      segments: segments,
      selected: {value},
      onSelectionChanged: (Set<String> newSelection) {
        onChanged(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.medicalBlue;
          }
          return Colors.grey.shade100;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade700;
        }),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.medicalBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
