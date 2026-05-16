import 'app_constants.dart';

/// Medical thresholds and alert evaluation logic for the neonatal monitoring system.
/// This class provides pure functions to determine alert severity based on
/// clinical parameters without any UI or Firebase dependencies.
class AlertThresholds {
  AlertThresholds._(); // Private constructor

  // ==================== GLUCOSE EVALUATION ====================
  /// Evaluates glucose level and returns alert severity and message.
  /// Returns a tuple: (severity, message)
  static (String severity, String message) evaluateGlucose(double? glucoseMgDL) {
    if (glucoseMgDL == null) {
      return (AppConstants.alertSeverityInfo, '📊 Glycémie non mesurée');
    }
    
    if (glucoseMgDL < AppConstants.glucoseCriticalLow) {
      return (
        AppConstants.alertSeverityCritical,
        '🔴 GLUCOSE CRITIQUE: ${glucoseMgDL.toStringAsFixed(1)} mg/dL - <40 mg/dL - Urgence immédiate'
      );
    } else if (glucoseMgDL < AppConstants.glucoseWarningLow) {
      return (
        AppConstants.alertSeverityWarning,
        '🟠 GLUCOSE BASSE: ${glucoseMgDL.toStringAsFixed(1)} mg/dL - 40-45 mg/dL - Surveillance rapprochée'
      );
    } else if (glucoseMgDL > AppConstants.glucoseHigh) {
      return (
        AppConstants.alertSeverityMedium,
        '🟡 GLUCOSE ÉLEVÉE: ${glucoseMgDL.toStringAsFixed(1)} mg/dL - >150 mg/dL - Contrôle nécessaire'
      );
    }
    
    return (AppConstants.alertSeverityInfo, '✅ Glycémie normale: ${glucoseMgDL.toStringAsFixed(1)} mg/dL');
  }

  // ==================== TEMPERATURE EVALUATION ====================
  /// Evaluates body temperature and returns alert severity and message.
  static (String severity, String message) evaluateTemperature(double? tempCelsius) {
    if (tempCelsius == null) {
      return (AppConstants.alertSeverityInfo, '📊 Température non mesurée');
    }
    
    if (tempCelsius < AppConstants.temperatureEmergency) {
      return (
        AppConstants.alertSeverityCritical,
        '🔴 TEMPÉRATURE CRITIQUE: ${tempCelsius.toStringAsFixed(1)}°C - <32°C - Hypothermie sévère - Urgence'
      );
    } else if (tempCelsius < AppConstants.temperatureHypothermia) {
      return (
        AppConstants.alertSeverityWarning,
        '🟠 HYPOTHERMIE: ${tempCelsius.toStringAsFixed(1)}°C - 32-35.9°C - Réchauffement nécessaire'
      );
    } else if (tempCelsius > AppConstants.temperatureFever) {
      return (
        AppConstants.alertSeverityCritical,
        '🔴 RISQUE INFECTIEUX: ${tempCelsius.toStringAsFixed(1)}°C - >37.5°C - Évaluation urgente'
      );
    }
    
    return (AppConstants.alertSeverityInfo, '✅ Température normale: ${tempCelsius.toStringAsFixed(1)}°C');
  }

  // ==================== APGAR EVALUATION ====================
  /// Evaluates APGAR score and returns alert severity and message.
  static (String severity, String message) evaluateApgar(int? apgarScore) {
    if (apgarScore == null) {
      return (AppConstants.alertSeverityInfo, '📊 APGAR non mesuré');
    }
    
    if (apgarScore < AppConstants.apgarEmergency) {
      return (
        AppConstants.alertSeverityCritical,
        '🔴 APGAR CRITIQUE: $apgarScore/10 - <3 - Réanimation immédiate'
      );
    } else if (apgarScore < AppConstants.apgarWarning) {
      return (
        AppConstants.alertSeverityWarning,
        '🟠 APGAR BAS: $apgarScore/10 - 4-6 - Surveillance étroite'
      );
    }
    
    return (AppConstants.alertSeverityInfo, '✅ APGAR normal: $apgarScore/10');
  }

  // ==================== RESPIRATION EVALUATION ====================
  /// Evaluates respiration status.
  static (String severity, String message) evaluateRespiration(String? respiration) {
    switch (respiration) {
      case 'absente':
        return (AppConstants.alertSeverityCritical, '🔴 RESPIRATION ABSENTE - Réanimation immédiate');
      case 'faible irrégulière':
        return (AppConstants.alertSeverityWarning, '🟠 RESPIRATION FAIBLE/IRRÉGULIÈRE - Assistance respiratoire');
      default:
        return (AppConstants.alertSeverityInfo, '✅ Respiration normale');
    }
  }

  // ==================== CRY EVALUATION ====================
  /// Evaluates cry/vocalization.
  static (String severity, String message) evaluateCry(String? cry) {
    switch (cry) {
      case 'absent':
        return (AppConstants.alertSeverityCritical, '🔴 CRI ABSENT - Réanimation respiratoire');
      case 'irrégulier':
        return (AppConstants.alertSeverityWarning, '🟠 CRI IRRÉGULIER - Surveillance');
      default:
        return (AppConstants.alertSeverityInfo, '✅ Cri normal');
    }
  }

  // ==================== TONUS EVALUATION ====================
  /// Evaluates muscle tone.
  static (String severity, String message) evaluateTonus(String? tonus) {
    switch (tonus) {
      case 'flasque':
        return (AppConstants.alertSeverityWarning, '🟠 TONUS FLASQUE - Évaluation neurologique urgente');
      case 'faible':
        return (AppConstants.alertSeverityMedium, '🟡 TONUS FAIBLE - Surveillance');
      default:
        return (AppConstants.alertSeverityInfo, '✅ Tonus normal');
    }
  }

  // ==================== COMBINED ALERT EVALUATION ====================
  /// Evaluates all parameters and returns the highest severity alert.
  /// Returns: (highestSeverity, listOfAllMessages)
  static (String highestSeverity, List<String> messages) evaluateAllAlerts({
    double? glucose,
    double? temperature,
    int? apgar1,
    int? apgar5,
    String? respiration,
    String? cry,
    String? tonus,
  }) {
    final List<(String severity, String message)> results = [];
    
    if (glucose != null) results.add(evaluateGlucose(glucose));
    if (temperature != null) results.add(evaluateTemperature(temperature));
    if (apgar1 != null) results.add(evaluateApgar(apgar1));
    if (respiration != null) results.add(evaluateRespiration(respiration));
    if (cry != null) results.add(evaluateCry(cry));
    if (tonus != null) results.add(evaluateTonus(tonus));
    
    // Determine highest severity (priority: critical > warning > medium > info)
    String highestSeverity = AppConstants.alertSeverityInfo;
    final List<String> messages = [];
    
    for (final result in results) {
      messages.add(result.$2);
      
      if (result.$1 == AppConstants.alertSeverityCritical) {
        highestSeverity = AppConstants.alertSeverityCritical;
      } else if (result.$1 == AppConstants.alertSeverityWarning && 
                 highestSeverity != AppConstants.alertSeverityCritical) {
        highestSeverity = AppConstants.alertSeverityWarning;
      } else if (result.$1 == AppConstants.alertSeverityMedium && 
                 highestSeverity != AppConstants.alertSeverityCritical &&
                 highestSeverity != AppConstants.alertSeverityWarning) {
        highestSeverity = AppConstants.alertSeverityMedium;
      }
    }
    
    return (highestSeverity, messages);
  }

  // ==================== UTILITY FUNCTIONS ====================
  /// Returns the color code for a given severity (used for UI theming).
  static int getSeverityColor(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return 0xFFFF3B3B; // emergencyRed
      case AppConstants.alertSeverityWarning:
        return 0xFFFFA500; // warningOrange
      case AppConstants.alertSeverityMedium:
        return 0xFFFFD700; // mediumYellow
      default:
        return 0xFF4CAF50; // stableGreen
    }
  }

  /// Returns true if the severity requires immediate attention.
  static bool requiresImmediateAttention(String severity) {
    return severity == AppConstants.alertSeverityCritical;
  }

  /// Returns the priority level (1 = highest, 4 = lowest).
  static int getSeverityPriority(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical: return 1;
      case AppConstants.alertSeverityWarning: return 2;
      case AppConstants.alertSeverityMedium: return 3;
      default: return 4;
    }
  }

  /// Returns the display label for a severity.
  static String getSeverityLabel(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical: return '🔴 Urgence';
      case AppConstants.alertSeverityWarning: return '🟠 Surveillance';
      case AppConstants.alertSeverityMedium: return '🟡 Attention';
      default: return '🟢 Stable';
    }
  }
}