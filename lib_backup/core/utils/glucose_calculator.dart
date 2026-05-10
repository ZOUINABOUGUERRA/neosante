import '../constants/app_constants.dart';

/// Glucose calculator utility for converting between units and evaluating levels.
class GlucoseCalculator {
  GlucoseCalculator._(); // Private constructor

  /// Converts mg/dL to mmol/L (divide by 18)
  static double mgPerDlToMmolPerL(double mgPerDl) {
    return mgPerDl / 18.0;
  }

  /// Converts mmol/L to mg/dL (multiply by 18)
  static double mmolPerLToMgPerDl(double mmolPerL) {
    return mmolPerL * 18.0;
  }

  /// Evaluates glucose level and returns a severity and message.
  static ({String severity, String message, bool isCritical}) evaluateGlucose(double? valueMgPerDl) {
    if (valueMgPerDl == null) {
      return (
        severity: AppConstants.alertSeverityInfo,
        message: 'Glycémie non mesurée',
        isCritical: false,
      );
    }

    if (valueMgPerDl < AppConstants.glucoseCriticalLow) {
      return (
        severity: AppConstants.alertSeverityCritical,
        message: '🔴 GLUCOSE CRITIQUE: ${valueMgPerDl.toStringAsFixed(1)} mg/dL - Urgence immédiate',
        isCritical: true,
      );
    } else if (valueMgPerDl < AppConstants.glucoseWarningLow) {
      return (
        severity: AppConstants.alertSeverityWarning,
        message: '🟠 GLUCOSE BASSE: ${valueMgPerDl.toStringAsFixed(1)} mg/dL - Surveillance rapprochée',
        isCritical: false,
      );
    } else if (valueMgPerDl > AppConstants.glucoseHigh) {
      return (
        severity: AppConstants.alertSeverityMedium,
        message: '🟡 GLUCOSE ÉLEVÉE: ${valueMgPerDl.toStringAsFixed(1)} mg/dL - Contrôle nécessaire',
        isCritical: false,
      );
    }

    return (
      severity: AppConstants.alertSeverityInfo,
      message: 'Glycémie normale: ${valueMgPerDl.toStringAsFixed(1)} mg/dL',
      isCritical: false,
    );
  }

  /// Calculates the required glucose infusion rate (GIR) in mg/kg/min
  /// Formula: GIR = (glucose concentration (%) * infusion rate (mL/h)) / (6 * weight (kg))
  static double calculateGIR({
    required double glucoseConcentrationPercent, // e.g., 10% = 10
    required double infusionRateMlPerHour,
    required double weightKg,
  }) {
    return (glucoseConcentrationPercent * infusionRateMlPerHour) / (6 * weightKg);
  }

  /// Calculates the volume of dextrose needed to achieve target glucose
  static double calculateDextroseVolume({
    required double currentGlucoseMgPerDl,
    required double targetGlucoseMgPerDl,
    required double weightKg,
    required double dextroseConcentrationPercent, // e.g., 10% = 0.1
  }) {
    final glucoseDeficit = targetGlucoseMgPerDl - currentGlucoseMgPerDl;
    // 0.6 = distribution volume for neonates (L/kg)
    final volumeLiters = (glucoseDeficit * 0.6 * weightKg) / (dextroseConcentrationPercent * 1000);
    return volumeLiters * 1000; // return in mL
  }

  /// Returns the glucose status text for display
  static String getGlucoseStatus(double valueMgPerDl) {
    if (valueMgPerDl < AppConstants.glucoseCriticalLow) {
      return 'Hypoglycémie sévère';
    } else if (valueMgPerDl < AppConstants.glucoseWarningLow) {
      return 'Hypoglycémie modérée';
    } else if (valueMgPerDl > AppConstants.glucoseHigh) {
      return 'Hyperglycémie';
    }
    return 'Normoglycémie';
  }

  /// Returns the color code for glucose status
  static int getGlucoseStatusColor(double valueMgPerDl) {
    if (valueMgPerDl < AppConstants.glucoseCriticalLow) {
      return 0xFFFF3B3B; // emergencyRed
    } else if (valueMgPerDl < AppConstants.glucoseWarningLow) {
      return 0xFFFFA500; // warningOrange
    } else if (valueMgPerDl > AppConstants.glucoseHigh) {
      return 0xFFFFD700; // mediumYellow
    }
    return 0xFF4CAF50; // stableGreen
  }

  /// Validates if glucose value is within normal range
  static bool isNormalGlucose(double valueMgPerDl) {
    return valueMgPerDl >= AppConstants.glucoseWarningLow &&
           valueMgPerDl <= AppConstants.glucoseHigh;
  }

  /// Returns recommended action based on glucose level
  static String getRecommendedAction(double valueMgPerDl) {
    if (valueMgPerDl < AppConstants.glucoseCriticalLow) {
      return 'Administrer G10 IV en bolus, répéter glycémie dans 30 minutes';
    } else if (valueMgPerDl < AppConstants.glucoseWarningLow) {
      return 'Alimentation entérale précoce, répéter glycémie dans 1 heure';
    } else if (valueMgPerDl > AppConstants.glucoseHigh) {
      return 'Réduire apport glucosé, contrôler glycémie dans 2 heures';
    }
    return 'Maintenir surveillance habituelle';
  }
}