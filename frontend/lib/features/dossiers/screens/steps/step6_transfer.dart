import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/extensions/string_ext.dart';
import '../../../../services/notification_service.dart';

/// Step 6: Transfer workflow (to neonatology, with mother, or other)
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
        // Find doctor by email
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

        // Create transfer request
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

        // Send notification to doctor
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
        // Direct transfer without approval
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              '🚑 Transfert du nouveau-né', Icons.local_hospital),
          const SizedBox(height: 16),

          // Transfer options
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisissez la destination :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildTransferOption(
                    title: 'En néonatalogie',
                    subtitle: 'Transfert vers le service de néonatalogie',
                    value: 'En néonatalogie',
                    icon: Icons.local_hospital,
                    color: const Color(0xFF2B7A78),
                  ),
                  _buildTransferOption(
                    title: 'Avec sa mère',
                    subtitle: 'Retour à la chambre maternelle',
                    value: 'Avec sa mère',
                    icon: Icons.family_restroom,
                    color: AppColors.stableGreen,
                  ),
                  _buildTransferOption(
                    title: 'Autre',
                    subtitle: 'Transfert vers un autre service',
                    value: 'Autre',
                    icon: Icons.other_houses,
                    color: AppColors.warningOrange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Doctor email field (only for neonatology transfer)
          if (_transferOption == 'En néonatalogie') ...[
            _buildSectionHeader('👨‍⚕️ Médecin destinataire', Icons.email),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _doctorEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email du médecin',
                        prefixIcon: Icon(Icons.email),
                        hintText: 'medecin@hopital.fr',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        _doctorEmail = value;
                        _notifyParent();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _transferReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motif du transfert (optionnel)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        _transferReason = value;
                        _notifyParent();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Transfer reason for other options
          if (_transferOption == 'Autre') ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _transferReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Précisez la destination / motif',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _transferReason = value;
                    _notifyParent();
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Status display
          if (_transferStatus != 'none')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _transferStatus == AppConstants.transferStatusPending
                    ? Colors.orange.withOpacity(0.1)
                    : AppColors.stableGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                          ? 'Transfert en attente d\'approbation'
                          : 'Transfert approuvé - Dossier accessible au médecin',
                      style: TextStyle(
                        color: _transferStatus ==
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
              padding: const EdgeInsets.only(top: 12),
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

          // Send button
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
                      ? 'Envoyer la demande de transfert'
                      : 'Valider le transfert',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          // Info message for already transferred
          if (_transferStatus == AppConstants.transferStatusPending)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  'Le médecin recevra une notification',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
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

  Widget _buildTransferOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _transferOption == value;
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _transferOption,
      onChanged: (val) {
        setState(() {
          _transferOption = val!;
          if (_transferOption != 'En néonatalogie') {
            _transferStatus = 'none';
            _requestMessage = null;
          }
        });
        _notifyParent();
      },
      activeColor: color,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  void dispose() {
    _doctorEmailController.dispose();
    _transferReasonController.dispose();
    super.dispose();
  }
}
