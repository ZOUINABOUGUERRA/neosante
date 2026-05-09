import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

/// Step 4: Systematic gestures (préchauffé, séchage, stimulation, clampage, etc.)
class Step4SystematicGestures extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic> initialData;

  const Step4SystematicGestures({
    super.key,
    required this.onChanged,
    required this.initialData,
  });

  @override
  State<Step4SystematicGestures> createState() => _Step4SystematicGesturesState();
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
    _verificationTonusRespiration = widget.initialData['verificationTonusRespiration'] ?? false;
    _verificationOther = widget.initialData['verificationTonusRespirationOther'] ?? '';
    _miseSousChaleur = widget.initialData['miseSousChaleur'] ?? 'Incubateur préchauffé + bonnet';
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
      'miseSousChaleur': _miseSousChaleur == 'autre' ? _miseSousChaleurOther : _miseSousChaleur,
      'miseSousChaleurOther': _miseSousChaleurOther,
      'vitamineK': _vitamineK,
      'bracelet': _bracelet,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🌡️ Préparation et soins immédiats', Icons.thermostat),
          const SizedBox(height: 16),
          _buildCheckboxTile(
            title: 'Préchauffé',
            value: _prechauffe,
            onChanged: (value) {
              setState(() => _prechauffe = value!);
              _notifyParent();
            },
            subtitle: 'Préchauffage de la salle de naissance / incubateur',
          ),
          _buildCheckboxTile(
            title: 'Séchage',
            value: _sechage,
            onChanged: (value) {
              setState(() => _sechage = value!);
              _notifyParent();
            },
            subtitle: 'Séchage complet du nouveau-né',
          ),
          _buildCheckboxTile(
            title: 'Stimulation',
            value: _stimulation,
            onChanged: (value) {
              setState(() => _stimulation = value!);
              _notifyParent();
            },
            subtitle: 'Stimulation tactile si nécessaire',
          ),
          const Divider(height: 32),
          
          _buildSectionHeader('🔌 Clampage du cordon', Icons.link),
          const SizedBox(height: 16),
          _buildRadioTile(
            title: 'Clampage immédiat',
            value: 'immédiate',
            groupValue: _clampage,
            onChanged: (value) {
              setState(() => _clampage = value!);
              _notifyParent();
            },
          ),
          _buildRadioTile(
            title: 'Clampage tardif (≥ 1 minute)',
            value: 'tardif',
            groupValue: _clampage,
            onChanged: (value) {
              setState(() => _clampage = value!);
              _notifyParent();
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('🫁 Vérification tonus et respiration', Icons.healing),
          const SizedBox(height: 16),
          _buildCheckboxTile(
            title: 'Vérification effectuée',
            value: _verificationTonusRespiration,
            onChanged: (value) {
              setState(() => _verificationTonusRespiration = value!);
              _notifyParent();
            },
          ),
          if (_verificationTonusRespiration)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Observations complémentaires',
                  hintText: 'Détails sur la vérification...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  _verificationOther = value;
                  _notifyParent();
                },
              ),
            ),
          const Divider(height: 32),

          _buildSectionHeader('🔥 Mise sous chaleur', Icons.wb_sunny),
          const SizedBox(height: 16),
          _buildRadioTile(
            title: 'Incubateur préchauffé + bonnet',
            value: 'Incubateur préchauffé + bonnet',
            groupValue: _miseSousChaleur,
            onChanged: (value) {
              setState(() => _miseSousChaleur = value!);
              _notifyParent();
            },
          ),
          _buildRadioTile(
            title: 'Lampe chauffante',
            value: 'lampe chauffante',
            groupValue: _miseSousChaleur,
            onChanged: (value) {
              setState(() => _miseSousChaleur = value!);
              _notifyParent();
            },
          ),
          _buildRadioTile(
            title: 'Peau à peau (mère)',
            value: 'peau à peau',
            groupValue: _miseSousChaleur,
            onChanged: (value) {
              setState(() => _miseSousChaleur = value!);
              _notifyParent();
            },
          ),
          _buildRadioTile(
            title: 'Sac plastique thermique',
            value: 'sac',
            groupValue: _miseSousChaleur,
            onChanged: (value) {
              setState(() => _miseSousChaleur = value!);
              _notifyParent();
            },
          ),
          _buildRadioTile(
            title: 'Autre',
            value: 'autre',
            groupValue: _miseSousChaleur,
            onChanged: (value) {
              setState(() => _miseSousChaleur = value!);
              _notifyParent();
            },
          ),
          if (_miseSousChaleur == 'autre')
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Précisez le dispositif',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  _miseSousChaleurOther = value;
                  _notifyParent();
                },
              ),
            ),
          const Divider(height: 32),

          _buildSectionHeader('💊 Vitaminothérapie et identification', Icons.medical_services),
          const SizedBox(height: 16),
          _buildCheckboxTile(
            title: 'Vitamine K administrée',
            value: _vitamineK,
            onChanged: (value) {
              setState(() => _vitamineK = value!);
              _notifyParent();
            },
            subtitle: '1 mg IM ou 2 mg VO',
          ),
          _buildCheckboxTile(
            title: 'Bracelet d\'identification posé',
            value: _bracelet,
            onChanged: (value) {
              setState(() => _bracelet = value!);
              _notifyParent();
            },
            subtitle: 'Identification mère-enfant',
          ),
        ],
      ),
    );
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

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
    String? subtitle,
  }) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.medicalBlue,
      contentPadding: EdgeInsets.zero,
      dense: false,
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.medicalBlue,
      contentPadding: EdgeInsets.zero,
      dense: false,
    );
  }
}