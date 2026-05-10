import '../constants/app_constants.dart';

/// APGAR score evaluator for neonatal assessment at 1 and 5 minutes.
/// The APGAR score evaluates 5 criteria: Appearance, Pulse, Grimace, Activity, Respiration.
class ApgarEvaluator {
  ApgarEvaluator._(); // Private constructor

  /// Individual APGAR criterion scores (0, 1, or 2)
  static const Map<String, Map<String, int>> criteria = {
    'Appearance (Couleur)': {
      'bleu/pâle': 0,
      'corps rose extrémités bleues': 1,
      'tout rose': 2,
    },
    'Pulse (Fréquence cardiaque)': {
      'absent': 0,
      '<100/min': 1,
      '>100/min': 2,
    },
    'Grimace (Réflexes)': {
      'aucune réaction': 0,
      'grimace': 1,
      'cri/éternuement': 2,
    },
    'Activity (Tonus)': {
      'flasque': 0,
      'faible': 1,
      'bon': 2,
    },
    'Respiration': {
      'absente': 0,
      'faible irrégulière': 1,
      'régulière/cri': 2,
    },
  };

  /// Calculates total APGAR score from individual criteria values
  static int calculateScore({
    required String coloration, // 'bleu/pâle', 'corps rose extrémités bleues', 'tout rose'
    required int heartRate, // 0 for absent, 1 for <100, 2 for >100 (or pass the string)
    required String reflex, // 'aucune réaction', 'grimace', 'cri/éternuement'
    required String tonus, // 'flasque', 'faible', 'bon'
    required String respiration, // 'absente', 'faible irrégulière', 'régulière'
  }) {
    int score = 0;

    // Appearance
    if (coloration == 'tout rose') score += 2;
    else if (coloration == 'corps rose extrémités bleues') score += 1;

    // Pulse (heart rate)
    if (heartRate > 100) score += 2;
    else if (heartRate >= 100) score += 1;

    // Grimace (reflex)
    if (reflex == 'cri/éternuement') score += 2;
    else if (reflex == 'grimace') score += 1;

    // Activity (tonus)
    if (tonus == 'bon') score += 2;
    else if (tonus == 'faible') score += 1;

    // Respiration
    if (respiration == 'régulière/cri') score += 2;
    else if (respiration == 'faible irrégulière') score += 1;

    return score;
  }

  /// Alternative method using string values for heart rate
  static int calculateScoreFromStrings({
    required String coloration,
    required String heartRate, // 'absent', '<100/min', '>100/min'
    required String reflex,
    required String tonus,
    required String respiration,
  }) {
    int heartRateScore = 0;
    if (heartRate == '>100/min') heartRateScore = 2;
    else if (heartRate == '<100/min') heartRateScore = 1;

    int score = 0;
    if (coloration == 'tout rose') score += 2;
    else if (coloration == 'corps rose extrémités bleues') score += 1;
    score += heartRateScore;
    if (reflex == 'cri/éternuement') score += 2;
    else if (reflex == 'grimace') score += 1;
    if (tonus == 'bon') score += 2;
    else if (tonus == 'faible') score += 1;
    if (respiration == 'régulière/cri') score += 2;
    else if (respiration == 'faible irrégulière') score += 1;

    return score;
  }

  /// Evaluates APGAR score and returns severity and message
  static ({String severity, String message, bool isCritical}) evaluateApgar(int? score, {int minute = 1}) {
    if (score == null) {
      return (
        severity: AppConstants.alertSeverityInfo,
        message: 'APGAR T$minute non mesuré',
        isCritical: false,
      );
    }

    if (score < AppConstants.apgarEmergency) {
      return (
        severity: AppConstants.alertSeverityCritical,
        message: '🔴 APGAR CRITIQUE: $score/10 à $minute minute - Réanimation immédiate',
        isCritical: true,
      );
    } else if (score < AppConstants.apgarWarning) {
      return (
        severity: AppConstants.alertSeverityWarning,
        message: '🟠 APGAR BAS: $score/10 à $minute minute - Surveillance étroite',
        isCritical: false,
      );
    } else if (score >= AppConstants.apgarNormalMin) {
      return (
        severity: AppConstants.alertSeverityInfo,
        message: 'APGAR normal: $score/10 à $minute minute',
        isCritical: false,
      );
    }

    return (
      severity: AppConstants.alertSeverityInfo,
      message: 'APGAR $score/10 à $minute minute',
      isCritical: false,
    );
  }

  /// Returns the interpretation of APGAR score
  static String getApgarInterpretation(int score) {
    if (score >= 8) {
      return 'Nouveau-né en bonne santé';
    } else if (score >= 5) {
      return 'Asphyxie modérée - Surveillance requise';
    } else if (score >= 3) {
      return 'Asphyxie sévère - Réanimation nécessaire';
    } else {
      return 'Détresse sévère - Réanimation immédiate';
    }
  }

  /// Returns recommended action based on APGAR score
  static String getRecommendedAction(int score, {int minute = 1}) {
    if (score < 3) {
      return 'Ventilation assistée immédiate, massage cardiaque si nécessaire, intubation, adrénaline selon protocole';
    } else if (score < 5) {
      return 'Ventilation assistée, oxygénothérapie, surveillance rapprochée';
    } else if (score < 7) {
      return 'Oxygénothérapie si besoin, stimulation, surveillance';
    }
    return 'Surveillance de routine, peau à peau avec la mère';
  }

  /// Returns the color for APGAR score display
  static int getApgarColor(int score) {
    if (score < AppConstants.apgarEmergency) return 0xFFFF3B3B; // emergencyRed
    if (score < AppConstants.apgarWarning) return 0xFFFFA500; // warningOrange
    if (score >= AppConstants.apgarNormalMin) return 0xFF4CAF50; // stableGreen
    return 0xFFFFD700; // mediumYellow
  }

  /// Validates if a value is a valid APGAR component score (0, 1, or 2)
  static bool isValidComponentScore(int value) {
    return value >= 0 && value <= 2;
  }

  /// Validates if a value is a valid total APGAR score (0-10)
  static bool isValidTotalScore(int value) {
    return value >= 0 && value <= 10;
  }

  /// Returns the list of criteria for APGAR assessment (useful for forms)
  static List<String> getCriteriaList() {
    return criteria.keys.toList();
  }

  /// Returns possible options for a given criterion
  static List<String> getOptionsForCriterion(String criterion) {
    return criteria[criterion]?.keys.toList() ?? [];
  }
}