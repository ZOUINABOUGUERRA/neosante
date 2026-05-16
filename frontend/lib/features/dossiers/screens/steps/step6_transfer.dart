import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/extensions/string_ext.dart';
import '../../../../services/notification_service.dart';

/// Step 6: Transfer workflow
class Step6Transfer extends StatefulWidget {
  final String dossierId;
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic> initialData;

  const Step6Transfer({
    super.key,
    required this.dossierId,
    required this.onChanged,
    required this.initialData,
  });

  @override
  State<Step6Transfer> createState() => _Step6TransferState();
}

class _Step6TransferState extends State<Step6Transfer> {
  String _transferOption = 'Avec sa mère';
  String _doctorEmail = '';
  String _transferReason = '';
  String _transferStatus = 'none';
  bool _isSendingRequest = false;
  String? _requestMessage;
  late TextEditingController _doctorEmailController;
  late TextEditingController _transferReasonController;

  @override
  void initState() {
    super.initState();
    _doctorEmailController = TextEditingController();
    _transferReasonController = TextEditingController();
    _loadInitialData();
  }

  void _loadInitialData() {
    _transferOption = widget.initialData['transferOption'] ?? 'Avec sa mère';
    _doctorEmail = widget.initialData['transferDoctorEmail'] ?? '';
    _transferReason = widget.initialData['transferReason'] ?? '';
    _transferStatus = widget.initialData['transferStatus'] ?? 'none';
    _doctorEmailController.text = _doctorEmail;
    _transferReasonController.text = _transferReason;
  }

  void _notifyParent() {
    widget.onChanged({
      'transferOption': _transferOption,
      'transferDoctorEmail': _doctorEmail,
      'transferReason': _transferReason,
      'transferStatus': _transferStatus,
    });
  }

  Future<void> _sendTransferRequest() async {
    if (_transferOption == 'En néonatalogie') {
      if (_doctorEmail.isEmpty || !_doctorEmail.isValidEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un email valide')),
        );
        return;
      }
    }

    setState(() {
      _isSendingRequest = true;
      _requestMessage = null;
    });

    try {
      if (_transferOption == 'En néonatalogie') {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: _doctorEmail)
            .limit(1)
            .get();

        if (usersSnapshot.docs.isEmpty) {
          setState(() {
            _requestMessage = '❌ Aucun médecin trouvé avec cet email';
            _isSendingRequest = false;
          });
          return;
        }

        final doctor = usersSnapshot.docs.first;
        final doctorId = doctor.id;

        final transferRef = FirebaseFirestore.instance
            .collection(AppConstants.transfersCollection)
            .doc();

        await transferRef.set({
          'id': transferRef.id,
          'dossierId': widget.dossierId,
          'dossierNumber': widget.initialData['dossierNumber'],
          'newbornName': widget.initialData['newbornName'],
          'requestedBy': FirebaseAuth.instance.currentUser?.uid,
          'requestedByName': widget.initialData['sageFemmeName'],
          'requestedTo': doctorId,
          'requestedToEmail': _doctorEmail,
          'transferOption': _transferOption,
          'transferReason': _transferReason,
          'status': AppConstants.transferStatusPending,
          'requestedAt': FieldValue.serverTimestamp(),
        });

        await NotificationService.notifyTransferRequest(
          doctorId,
          widget.initialData['dossierNumber'] ?? 'N/A',
          widget.initialData['newbornName'] ?? 'Nouveau-né',
        );

        setState(() {
          _transferStatus = AppConstants.transferStatusPending;
          _requestMessage = '✅ Demande de transfert envoyée au médecin';
        });
      } else {
        setState(() {
          _transferStatus = AppConstants.transferStatusApproved;
          _requestMessage = '✅ Transfert enregistré avec succès';
        });
      }

      _notifyParent();
    } catch (e) {
      setState(() {
        _requestMessage = '❌ Erreur: ${e.toString()}';
      });
    } finally {
      setState(() => _isSendingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ التنسيق الرئيسي
          _buildSectionCard(
            title: '🚑 Transfert du nouveau-né',
            icon: Icons.local_hospital,
            children: [
              const Text(
                'Choisissez la destination :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildTransferOption(
                emoji: '🏥',
                title: 'Service Néonatalogie',
                subtitle: 'Transfert vers le service de néonatalogie',
                value: 'En néonatalogie',
                color: const Color(0xFF2B7A78),
              ),
              const SizedBox(height: 8),
              _buildTransferOption(
                emoji: '👩‍👧',
                title: 'Retour à la maternité',
                subtitle: 'Retour à la chambre maternelle',
                value: 'Avec sa mère',
                color: AppColors.stableGreen,
              ),
              const SizedBox(height: 8),
              _buildTransferOption(
                emoji: '🏥',
                title: 'Autre service',
                subtitle: 'Transfert vers un autre service',
                value: 'Autre',
                color: AppColors.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ Formulaire selon l'option
          if (_transferOption == 'En néonatalogie')
            _buildSectionCard(
              title: '👨‍⚕️ Médecin destinataire',
              icon: Icons.email,
              children: [
                _buildTextField(
                  controller: _doctorEmailController,
                  label: 'Email du médecin',
                  icon: Icons.email,
                  hint: 'medecin@hopital.fr',
                  onChanged: (value) {
                    _doctorEmail = value;
                    _notifyParent();
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _transferReasonController,
                  label: 'Motif du transfert (optionnel)',
                  icon: Icons.description,
                  maxLines: 2,
                  onChanged: (value) {
                    _transferReason = value;
                    _notifyParent();
                  },
                ),
              ],
            ),

          if (_transferOption == 'Autre')
            _buildSectionCard(
              title: '📝 Détails',
              icon: Icons.description,
              children: [
                _buildTextField(
                  controller: _transferReasonController,
                  label: 'Précisez la destination / motif',
                  icon: Icons.location_on,
                  maxLines: 2,
                  onChanged: (value) {
                    _transferReason = value;
                    _notifyParent();
                  },
                ),
              ],
            ),

          // ✅ حالة الطلب
          if (_transferStatus != 'none')
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _transferStatus == AppConstants.transferStatusPending
                    ? Colors.orange.withValues(alpha: 0.1)
                    : AppColors.stableGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _transferStatus == AppConstants.transferStatusPending
                      ? Colors.orange
                      : AppColors.stableGreen,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _transferStatus == AppConstants.transferStatusPending
                        ? Icons.pending
                        : Icons.check_circle,
                    color: _transferStatus == AppConstants.transferStatusPending
                        ? Colors.orange
                        : AppColors.stableGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _transferStatus == AppConstants.transferStatusPending
                          ? '⏳ Transfert en attente d\'approbation'
                          : '✓ Transfert approuvé - Dossier accessible au médecin',
                      style: TextStyle(
                        color:
                            _transferStatus ==
                                AppConstants.transferStatusPending
                            ? Colors.orange
                            : AppColors.stableGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_requestMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _requestMessage!,
                style: TextStyle(
                  color: _requestMessage!.contains('✅')
                      ? AppColors.stableGreen
                      : Colors.red,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ✅ زر الإرسال
          if (_transferStatus == 'none' ||
              _transferStatus == AppConstants.transferStatusRejected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSendingRequest ? null : _sendTransferRequest,
                icon: _isSendingRequest
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _transferOption == 'En néonatalogie'
                      ? '📤 Envoyer la demande de transfert'
                      : '✅ Valider le transfert',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          if (_transferStatus == AppConstants.transferStatusPending)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  '🔔 Le médecin recevra une notification',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
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

  Widget _buildTransferOption({
    required String emoji,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    final isSelected = _transferOption == value;
    return InkWell(
      onTap: () {
        setState(() {
          _transferOption = value;
          if (_transferOption != 'En néonatalogie') {
            _transferStatus = 'none';
            _requestMessage = null;
          }
        });
        _notifyParent();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _doctorEmailController.dispose();
    _transferReasonController.dispose();
    super.dispose();
  }
}
