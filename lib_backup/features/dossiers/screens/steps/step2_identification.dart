import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
//import '../../../../shared/extensions/string_ext.dart';
import 'dart:io';
/// Step 2: Newborn identification and maternal information
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
        _birthDateTimeController.text =
            DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dateTime);
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_birthDateTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _birthDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _birthDateTimeController.text =
              DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(_birthDateTime!);
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
      // ✅ تحويل XFile إلى File
      final file = File(pickedFile.path);
      
      final ref = FirebaseStorage.instance.ref().child(
          'dossiers/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}');
      
      // ✅ رفع الملف
      await ref.putFile(file);
      
      final downloadUrl = await ref.getDownloadURL();
      setState(() {
        _imageUrls.add(downloadUrl);
      });
      _notifyParent();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du téléchargement de l\'image'),
        ),
      );
    } finally {
      setState(() => _isUploading = false);
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Newborn Information Section
            _buildSectionHeader('👶 Nouveau-né', Icons.baby_changing_station),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newbornNameController,
              label: 'Nom du nouveau-né',
              icon: Icons.person,
              validator: (value) =>
                  value?.isEmpty == true ? 'Champ requis' : null,
              onChanged: (_) => _notifyParent(),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              controller: _birthDateTimeController,
              label: 'Date et heure de naissance',
              icon: Icons.calendar_today,
              onTap: _selectBirthDateTime,
            ),
            const SizedBox(height: 16),

            // Maternal Information Section
            _buildSectionHeader('👩 Mère', Icons.woman),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),

            // Delivery Information Section
            _buildSectionHeader('🤱 Accouchement', Icons.local_hospital),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Mode d\'accouchement',
              value: _deliveryMethod,
              items: const [
                DropdownMenuItem(
                  value: AppConstants.deliveryVaginal,
                  child: Text('Voie basse'),
                ),
                DropdownMenuItem(
                  value: AppConstants.deliveryCesarean,
                  child: Text('Césarienne'),
                ),
                DropdownMenuItem(
                  value: 'autre',
                  child: Text('Autre'),
                ),
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
                DropdownMenuItem(value: 'clair', child: Text('Clair')),
                DropdownMenuItem(value: 'teinté', child: Text('Teinté')),
                DropdownMenuItem(value: 'méconial', child: Text('Méconial')),
                DropdownMenuItem(value: 'sanglant', child: Text('Sanglant')),
              ],
              onChanged: (value) {
                setState(() => _amnioticColor = value!);
                _notifyParent();
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _observationsController,
              label: 'Observations sage-femme',
              icon: Icons.note,
              maxLines: 3,
              onChanged: (_) => _notifyParent(),
            ),
            const SizedBox(height: 16),

            // Images Section
            _buildSectionHeader('📷 Documents et images', Icons.image),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: const Text('Ajouter une image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightBlue,
              ),
            ),
            const SizedBox(height: 16),
            if (_imageUrls.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_imageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16),
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
        ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 12),
          height: 2,
          width: 40,
          color: AppColors.medicalBlue,
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
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: IgnorePointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
