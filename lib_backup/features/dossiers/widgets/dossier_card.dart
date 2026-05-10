import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import 'package:neosante/core/utils/date_formatter.dart';

class DossierCard extends StatelessWidget {
  final Map<String, dynamic> dossier;
  final VoidCallback onTap;

  const DossierCard({
    super.key,
    required this.dossier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severity = dossier['alertSeverity'] ?? 'info';
    final borderColor = _getSeverityColor(severity);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
  color: borderColor.withValues(alpha: 0.2),
  borderRadius: BorderRadius.circular(12),
),
                    child: Text(
                      _getStatusLabel(dossier['status']),
                      style: TextStyle(
                        fontSize: 10,
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (dossier['serviceType'] == AppConstants.servicePremature)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Prématuré',
                        style: TextStyle(fontSize: 10, color: Colors.purple),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Newborn name
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.medicalBlue.withValues(alpha: .1),
                    child:const Icon(
                      Icons.baby_changing_station,
                      color: AppColors.medicalBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dossier['newbornName'] ?? 'Nouveau-né',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Mère: ${dossier['motherName'] ?? 'N/A'}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Medical info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.calendar_today,
                      '${dossier['gestationalAge'] ?? '?'} SA',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.monitor_weight,
                      '${dossier['birthWeight'] ?? '?'} g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.thermostat,
                      '${dossier['bodyTemperature'] ?? '?'} °C',
                      color: _getTemperatureColor(dossier['bodyTemperature']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.science,
                      '${dossier['bloodGlucose'] ?? '?'} mg/dL',
                      color: _getGlucoseColor(dossier['bloodGlucose']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatTimeAgo(
                      (dossier['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    ),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  if (severity != 'info')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSeverityLabel(severity),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.medicalBlue).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.medicalBlue),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.darkGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.emergencyRed;
      case 'warning':
        return AppColors.warningOrange;
      case 'medium':
        return AppColors.mediumYellow;
      default:
        return AppColors.stableGreen;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return 'URGENCE';
      case 'warning':
        return 'SURVEILLANCE';
      case 'medium':
        return 'ATTENTION';
      default:
        return 'STABLE';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'transferred':
        return 'Transféré';
      case 'archived':
        return 'Archivé';
      default:
        return 'En cours';
    }
  }

  Color _getGlucoseColor(dynamic value) {
    if (value == null) return Colors.grey;
    final glucose =
        value is double ? value : double.tryParse(value.toString()) ?? 0;
    if (glucose < 40) return AppColors.emergencyRed;
    if (glucose < 45) return AppColors.warningOrange;
    if (glucose > 150) return AppColors.mediumYellow;
    return AppColors.stableGreen;
  }

  Color _getTemperatureColor(dynamic value) {
    if (value == null) return Colors.grey;
    final temp =
        value is double ? value : double.tryParse(value.toString()) ?? 0;
    if (temp < 32) return AppColors.emergencyRed;
    if (temp < 36) return AppColors.warningOrange;
    if (temp > 37.5) return AppColors.emergencyRed;
    return AppColors.stableGreen;
  }
}
