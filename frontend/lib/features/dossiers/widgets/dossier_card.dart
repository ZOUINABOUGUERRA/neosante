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
    final severity = dossier['alertSeverity']?.toString() ?? 'info';

    final borderColor = _getSeverityColor(severity);

    final isPremature =
        dossier['serviceType'] == AppConstants.servicePremature;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(
                            dossier['status']?.toString(),
                          ),
                          size: 12,
                          color: borderColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(
                            dossier['status']?.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: borderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPremature
                          ? Colors.purple.withValues(alpha: 0.15)
                          : AppColors.stableGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPremature ? '👶 Prématuré' : '🍼 À terme',
                      style: TextStyle(
                        fontSize: 10,
                        color: isPremature
                            ? Colors.purple
                            : AppColors.stableGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ================= INFOS =================

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.baby_changing_station,
                      size: 24,
                      color: AppColors.medicalBlue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dossier['newbornName']?.toString() ??
                              'Nouveau-né',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          '👩 Mère: ${dossier['motherName']?.toString() ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ================= DONNÉES =================

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dossier['gestationalAge'] ?? '?'} SA',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.monitor_weight,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dossier['birthWeight'] ?? '?'} g',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getTemperatureColor(
                          dossier['bodyTemperature'],
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.thermostat,
                            size: 16,
                            color: _getTemperatureColor(
                              dossier['bodyTemperature'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dossier['bodyTemperature'] ?? '?'} °C',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTemperatureColor(
                                dossier['bodyTemperature'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getGlucoseColor(
                          dossier['bloodGlucose'],
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.science,
                            size: 16,
                            color: _getGlucoseColor(
                              dossier['bloodGlucose'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dossier['bloodGlucose'] ?? '?'} mg/dL',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getGlucoseColor(
                                dossier['bloodGlucose'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ================= FOOTER =================

              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),

                  const SizedBox(width: 4),

                  Text(
                    DateFormatter.formatTimeAgo(
                      _parseDate(dossier['createdAt']) ??
                          DateTime.now(),
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),

                  const Spacer(),

                  if (severity != 'info')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(20),
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

  // ================= HELPERS =================

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ================= STATUS =================

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return Icons.fiber_manual_record;

      case 'transferred':
        return Icons.swap_horiz;

      case 'archived':
        return Icons.archive;

      default:
        return Icons.help;
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

  // ================= SEVERITY =================

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

  // ================= COLORS =================

  Color _getGlucoseColor(dynamic value) {
    if (value == null) return Colors.grey;

    final glucose = value is double
        ? value
        : double.tryParse(value.toString()) ?? 0;

    if (glucose < 40) {
      return AppColors.emergencyRed;
    }

    if (glucose < 45) {
      return AppColors.warningOrange;
    }

    if (glucose > 150) {
      return AppColors.mediumYellow;
    }

    return AppColors.stableGreen;
  }

  Color _getTemperatureColor(dynamic value) {
    if (value == null) return Colors.grey;

    final temp = value is double
        ? value
        : double.tryParse(value.toString()) ?? 0;

    if (temp < 32) {
      return AppColors.emergencyRed;
    }

    if (temp < 36) {
      return AppColors.warningOrange;
    }

    if (temp > 37.5) {
      return AppColors.emergencyRed;
    }

    return AppColors.stableGreen;
  }
}
