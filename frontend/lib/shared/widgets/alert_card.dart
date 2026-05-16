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
    final color = _getSeverityColor();
    final emoji = _getSeverityEmoji();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: color == AppColors.mediumYellow
                          ? AppColors.darkGray
                          : Colors.black87,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onDismiss,
                    tooltip: 'Ignorer',
                    splashRadius: 20,
                  ),
              ],
            ),
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

  // ✅ إزالة هذه الدالة إذا لم تستخدمها، أو احتفظ بها إذا احتجتها لاحقاً
  // IconData _getSeverityIcon() {
  //   switch (severity) {
  //     case AppConstants.alertSeverityCritical:
  //       return Icons.warning_rounded;
  //     case AppConstants.alertSeverityWarning:
  //       return Icons.info_rounded;
  //     case AppConstants.alertSeverityMedium:
  //       return Icons.notifications_active_rounded;
  //     default:
  //       return Icons.check_circle_rounded;
  //   }
  // }

  String _getSeverityEmoji() {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return '🚨';
      case AppConstants.alertSeverityWarning:
        return '⚠️';
      case AppConstants.alertSeverityMedium:
        return '🔔';
      default:
        return '✅';
    }
  }
}
