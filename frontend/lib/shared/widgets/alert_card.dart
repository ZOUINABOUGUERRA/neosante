// frontend/lib/shared/widgets/alert_card.dart

import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../core/constants/app_constants.dart';

class AlertCard extends StatelessWidget {
  final String message;
  final String severity;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.message,
    required this.severity,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getSeverityColor(),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSeverityColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getSeverityIcon(),
                  color: _getSeverityColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  tooltip: 'Ignorer',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor() {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return AppColors.emergencyRed;
      case AppConstants.alertSeverityWarning:
        return AppColors.warningOrange;
      case AppConstants.alertSeverityMedium:
        return AppColors.mediumYellow;
      default:
        return AppColors.stableGreen;
    }
  }

  IconData _getSeverityIcon() {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return Icons.warning;
      case AppConstants.alertSeverityWarning:
        return Icons.info;
      case AppConstants.alertSeverityMedium:
        return Icons.notifications_active;
      default:
        return Icons.check_circle;
    }
  }
}