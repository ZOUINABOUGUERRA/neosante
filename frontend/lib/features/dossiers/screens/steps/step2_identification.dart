import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';

class Step2Identification extends StatefulWidget {
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic> initialData;

  const Step2Identification({
    super.key,
    required this.onChanged,
    required this.initialData,
  });

  @override
  State<Step2Identification> createState() => _Step2IdentificationState();
}

class _Step2IdentificationState extends State<Step2Identification> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _newbornNameController;
  late TextEditingController _birthDateTimeController;
  late TextEditingController _motherNameController;
  late TextEditingController _gestationalAgeController;
  late TextEditingController _atcdController;
  late TextEditingController _previousChildrenController;
  late TextEditingController _deliveryOtherController;
  late TextEditingController _observationsController;

  String _deliveryMethod = AppConstants.deliveryVaginal;
  String _amnioticColor = 'clair';
  List<String> _imageUrls = [];
  bool _isUploading = false;
  DateTime? _birthDateTime;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _newbornNameController = TextEditingController();
    _birthDateTimeController = TextEditingController();
    _motherNameController = TextEditingController();
    _gestationalAgeController = TextEditingController();
    _atcdController = TextEditingController();
    _previousChildrenController = TextEditingController();
    _deliveryOtherController = TextEditingController();
    _observationsController = TextEditingController();
  }

  void _loadInitialData() {
    _newbornNameController.text = widget.initialData['newbornName'] ?? '';
    _motherNameController.text = widget.initialData['motherName'] ?? '';
    _gestationalAgeController.text =
        widget.initialData['gestationalAge']?.toString() ?? '';
    _atcdController.text = widget.initialData['atcd'] ?? '';
    _previousChildrenController.text =
        widget.initialData['previousChildrenHistory'] ?? '';
    _deliveryMethod =
        widget.initialData['deliveryMethod'] ?? AppConstants.deliveryVaginal;
    _amnioticColor = widget.initialData['amnioticFluidColor'] ?? 'clair';
    _observationsController.text =
        widget.initialData['sageFemmeObservations'] ?? '';
    _imageUrls = List<String>.from(widget.initialData['imageUrls'] ?? []);

    if (widget.initialData['birthDateTime'] != null) {
      final dateTime = widget.initialData['birthDateTime'];
      if (dateTime is DateTime) {
        _birthDateTime = dateTime;
        _birthDateTimeController.text = DateFormat(
          'dd/MM/yyyy HH:mm',
          'fr_FR',
        ).format(dateTime);
      }
    }
  }

  void _notifyParent() {
    widget.onChanged({
      'newbornName': _newbornNameController.text.trim(),
      'birthDateTime': _birthDateTime,
      'motherName': _motherNameController.text.trim(),
      'gestationalAge': int.tryParse(_gestationalAgeController.text) ?? 0,
      'atcd': _atcdController.text.trim(),
      'previousChildrenHistory': _previousChildrenController.text.trim(),
      'deliveryMethod': _deliveryMethod == 'autre'
          ? _deliveryOtherController.text.trim()
          : _deliveryMethod,
      'amnioticFluidColor': _amnioticColor,
      'sageFemmeObservations': _observationsController.text.trim(),
      'imageUrls': _imageUrls,
    });
  }

  Future<void> _selectBirthDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _birthDateTime ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_birthDateTime ?? now),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _birthDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _birthDateTimeController.text = DateFormat(
            'dd/MM/yyyy HH:mm',
            'fr_FR',
          ).format(_birthDateTime!);
        });
        _notifyParent();
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(pickedFile.path);
        final ref = FirebaseStorage.instance.ref().child(
          'dossiers/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}',
        );
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        setState(() {
          _imageUrls.add(downloadUrl);
        });
        _notifyParent();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors du téléchargement')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: '👶 Nouveau-né',
              icon: Icons.baby_changing_station,
              children: [
                _buildTextField(
                  controller: _newbornNameController,
                  label: 'Nom du nouveau-né',
                  icon: Icons.person,
                  required: true,
                  onChanged: (_) => _notifyParent(),
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  controller: _birthDateTimeController,
                  label: 'Date et heure de naissance',
                  icon: Icons.calendar_today,
                  onTap: _selectBirthDateTime,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: '👩 Mère',
              icon: Icons.woman,
              children: [
                _buildTextField(
                  controller: _motherNameController,
                  label: 'Nom de la mère',
                  icon: Icons.female,
                  onChanged: (_) => _notifyParent(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _gestationalAgeController,
                        label: 'Âge gestationnel (SA)',
                        icon: Icons.timer,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _notifyParent(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _previousChildrenController,
                        label: 'Parité',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _notifyParent(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _atcdController,
                  label: 'ATCD (Antécédents)',
                  icon: Icons.history,
                  maxLines: 2,
                  onChanged: (_) => _notifyParent(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: '🤱 Accouchement',
              icon: Icons.local_hospital,
              children: [
                _buildDropdown(
                  label: 'Mode d\'accouchement',
                  value: _deliveryMethod,
                  items: const [
                    DropdownMenuItem(
                      value: 'voie basse',
                      child: Text(' Voie basse'),
                    ),
                    DropdownMenuItem(
                      value: 'césarienne',
                      child: Text(' Césarienne'),
                    ),
                    DropdownMenuItem(value: 'autre', child: Text('📝 Autre')),
                  ],
                  onChanged: (value) {
                    setState(() => _deliveryMethod = value!);
                    _notifyParent();
                  },
                ),
                if (_deliveryMethod == 'autre')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildTextField(
                      controller: _deliveryOtherController,
                      label: 'Précisez',
                      icon: Icons.edit,
                      onChanged: (_) => _notifyParent(),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Couleur du liquide amniotique',
                  value: _amnioticColor,
                  items: const [
                    DropdownMenuItem(value: 'clair', child: Text('💧 Clair')),
                    DropdownMenuItem(value: 'teinté', child: Text('🟤 Teinté')),
                    DropdownMenuItem(
                      value: 'méconial',
                      child: Text('🟢 Méconial'),
                    ),
                    DropdownMenuItem(
                      value: 'sanglant',
                      child: Text('🔴 Sanglant'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _amnioticColor = value!);
                    _notifyParent();
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _observationsController,
                  label: 'Observations',
                  icon: Icons.note,
                  maxLines: 3,
                  hint: 'Notes cliniques de la sage-femme...',
                  onChanged: (_) => _notifyParent(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: '📷 Documents et images',
              icon: Icons.image,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate),
                  label: const Text('📸 Ajouter une image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(_imageUrls[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 14),
                                  color: Colors.white,
                                  onPressed: () => _removeImage(index),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    String? hint,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (value) => value?.isEmpty == true ? 'Champ requis' : null
          : null,
      onChanged: onChanged,
    );
  }

  // ✅ دالة حقل التاريخ المصححة
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.medicalBlue),
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.medicalBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ دالة القائمة المنسدلة المصححة
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

  @override
  void dispose() {
    _newbornNameController.dispose();
    _birthDateTimeController.dispose();
    _motherNameController.dispose();
    _gestationalAgeController.dispose();
    _atcdController.dispose();
    _previousChildrenController.dispose();
    _deliveryOtherController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
}
