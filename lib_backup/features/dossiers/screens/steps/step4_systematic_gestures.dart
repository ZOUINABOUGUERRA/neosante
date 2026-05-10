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

  // ✅ قوائم الخيارات لـ SegmentedButton
  final Set<String> _clampageOptions = {'immédiate', 'tardif'};
  final Set<String> _miseSousChaleurOptions = {
    'Incubateur préchauffé + bonnet',
    'lampe chauffante',
    'peau à peau',
    'sac',
    'autre',
  };

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
          // ✅ استخدام SegmentedButton بدلاً من Radio
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'immédiate', label: Text('Clampage immédiat')),
              ButtonSegment(value: 'tardif', label: Text('Clampage tardif (≥ 1 minute)')),
            ],
            selected: {_clampage},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _clampage = newSelection.first;
                _notifyParent();
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.medicalBlue;
                }
                return Colors.grey.shade200;
              }),
            ),
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
          // ✅ استخدام SegmentedButton بدلاً من Radio
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Incubateur préchauffé + bonnet', label: Text('Incubateur + bonnet')),
              ButtonSegment(value: 'lampe chauffante', label: Text('Lampe chauffante')),
              ButtonSegment(value: 'peau à peau', label: Text('Peau à peau')),
              ButtonSegment(value: 'sac', label: Text('Sac plastique')),
              ButtonSegment(value: 'autre', label: Text('Autre')),
            ],
            selected: {_miseSousChaleur},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _miseSousChaleur = newSelection.first;
                _notifyParent();
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.medicalBlue;
                }
                return Colors.grey.shade200;
              }),
            ),
          ),
          if (_miseSousChaleur == 'autre')
            Padding(
              padding: const EdgeInsets.only(top: 16),
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
}