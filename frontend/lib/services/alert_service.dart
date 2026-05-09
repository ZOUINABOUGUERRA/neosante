import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/alert_model.dart';
import '../shared/models/dossier_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/glucose_calculator.dart';
import '../core/utils/apgar_evaluator.dart';
import '../core/errors/failure.dart';

/// Smart alert service for medical alerts based on clinical parameters.
/// Automatically evaluates patient data and generates alerts when thresholds are crossed.
class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Evaluate a dossier and generate alerts if needed
  Future<List<AlertModel>> evaluateAndGenerateAlerts(DossierModel dossier) async {
    final List<AlertModel> generatedAlerts = [];
    
    // Evaluate glucose
    final glucoseAlert = _evaluateGlucoseAlert(dossier);
    if (glucoseAlert != null) {
      generatedAlerts.add(glucoseAlert);
    }
    
    // Evaluate temperature
    final tempAlert = _evaluateTemperatureAlert(dossier);
    if (tempAlert != null) {
      generatedAlerts.add(tempAlert);
    }
    
    // Evaluate APGAR
    final apgarAlert = _evaluateApgarAlert(dossier);
    if (apgarAlert != null) {
      generatedAlerts.add(apgarAlert);
    }
    
    // Evaluate respiration
    final respAlert = _evaluateRespirationAlert(dossier);
    if (respAlert != null) {
      generatedAlerts.add(respAlert);
    }
    
    // Evaluate tonus
    final tonusAlert = _evaluateTonusAlert(dossier);
    if (tonusAlert != null) {
      generatedAlerts.add(tonusAlert);
    }
    
    // Evaluate cry
    final cryAlert = _evaluateCryAlert(dossier);
    if (cryAlert != null) {
      generatedAlerts.add(cryAlert);
    }
    
    // Save alerts to Firestore
    for (final alert in generatedAlerts) {
      await _saveAlert(alert);
    }
    
    // Update dossier with highest severity
    if (generatedAlerts.isNotEmpty) {
      await _updateDossierAlertSeverity(dossier.id, generatedAlerts);
    }
    
    return generatedAlerts;
  }

  /// Evaluate glucose level and generate alert if needed
  AlertModel? _evaluateGlucoseAlert(DossierModel dossier) {
    final evaluation = GlucoseCalculator.evaluateGlucose(dossier.bloodGlucose);
    
    if (evaluation.severity != AppConstants.alertSeverityInfo) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'glucose',
        value: dossier.bloodGlucose,
        severity: evaluation.severity,
        message: evaluation.message,
        isRead: false,
        isAcknowledged: false,
        acknowledgedBy: null,
        acknowledgedAt: null,
        timestamp: DateTime.now(),
        actionTaken: null,
      );
    }
    return null;
  }

  /// Evaluate temperature and generate alert if needed
  AlertModel? _evaluateTemperatureAlert(DossierModel dossier) {
    if (dossier.bodyTemperature < AppConstants.temperatureEmergency) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'temperature',
        value: dossier.bodyTemperature,
        severity: AppConstants.alertSeverityCritical,
        message: '🔴 TEMPÉRATURE CRITIQUE: ${dossier.bodyTemperature}°C - Hypothermie sévère',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    } else if (dossier.bodyTemperature < AppConstants.temperatureHypothermia) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'temperature',
        value: dossier.bodyTemperature,
        severity: AppConstants.alertSeverityWarning,
        message: '🟠 HYPOTHERMIE: ${dossier.bodyTemperature}°C - Réchauffement nécessaire',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    } else if (dossier.bodyTemperature > AppConstants.temperatureFever) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'temperature',
        value: dossier.bodyTemperature,
        severity: AppConstants.alertSeverityCritical,
        message: '🔴 RISQUE INFECTIEUX: ${dossier.bodyTemperature}°C - Évaluation urgente',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Evaluate APGAR score and generate alert if needed
  AlertModel? _evaluateApgarAlert(DossierModel dossier) {
    final evaluation = ApgarEvaluator.evaluateApgar(dossier.apgar1, minute: 1);
    
    if (evaluation.severity != AppConstants.alertSeverityInfo) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'apgar',
        value: dossier.apgar1,
        severity: evaluation.severity,
        message: evaluation.message,
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Evaluate respiration and generate alert if needed
  AlertModel? _evaluateRespirationAlert(DossierModel dossier) {
    if (dossier.respiration == 'absente') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'respiration',
        value: dossier.respiration,
        severity: AppConstants.alertSeverityCritical,
        message: '🔴 RESPIRATION ABSENTE - Réanimation immédiate',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    } else if (dossier.respiration == 'faible irrégulière') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'respiration',
        value: dossier.respiration,
        severity: AppConstants.alertSeverityWarning,
        message: '🟠 RESPIRATION FAIBLE/IRRÉGULIÈRE - Assistance respiratoire',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Evaluate tonus and generate alert if needed
  AlertModel? _evaluateTonusAlert(DossierModel dossier) {
    if (dossier.tonus == 'flasque') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'tonus',
        value: dossier.tonus,
        severity: AppConstants.alertSeverityWarning,
        message: '🟠 TONUS FLASQUE - Évaluation neurologique urgente',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Evaluate cry and generate alert if needed
  AlertModel? _evaluateCryAlert(DossierModel dossier) {
    if (dossier.cry == 'absent') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber: dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'cri',
        value: dossier.cry,
        severity: AppConstants.alertSeverityCritical,
        message: '🔴 CRI ABSENT - Réanimation respiratoire',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Save alert to Firestore
  Future<void> _saveAlert(AlertModel alert) async {
    try {
      final docRef = _firestore.collection(AppConstants.alertsCollection).doc();
      await docRef.set(alert.copyWith(id: docRef.id).toJson());
    } catch (e) {
      throw DatabaseFailure(message: 'Erreur lors de la sauvegarde de l\'alerte: $e', originalError: e);
    }
  }

  /// Update dossier with highest alert severity
  Future<void> _updateDossierAlertSeverity(String dossierId, List<AlertModel> alerts) async {
    final severities = alerts.map((a) => a.severity);
    String highestSeverity = AppConstants.alertSeverityInfo;
    
    // Priority: critical > warning > medium > info
    if (severities.contains(AppConstants.alertSeverityCritical)) {
      highestSeverity = AppConstants.alertSeverityCritical;
    } else if (severities.contains(AppConstants.alertSeverityWarning)) {
      highestSeverity = AppConstants.alertSeverityWarning;
    } else if (severities.contains(AppConstants.alertSeverityMedium)) {
      highestSeverity = AppConstants.alertSeverityMedium;
    }
    
    try {
      await _firestore
          .collection(AppConstants.dossiersPrematuresCollection)
          .doc(dossierId)
          .update({'alertSeverity': highestSeverity});
    } catch (e) {
      // Try the other collection
      await _firestore
          .collection(AppConstants.dossiersATermeCollection)
          .doc(dossierId)
          .update({'alertSeverity': highestSeverity});
    }
  }

  /// Get active alerts for a dossier
  Stream<List<AlertModel>> getActiveAlerts(String dossierId) {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('dossierId', isEqualTo: dossierId)
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Get all alerts for a dossier
  Stream<List<AlertModel>> getAllAlerts(String dossierId) {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('dossierId', isEqualTo: dossierId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId, String acknowledgedBy, {String? actionTaken}) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alertId)
          .update({
            'isAcknowledged': true,
            'acknowledgedBy': acknowledgedBy,
            'acknowledgedAt': FieldValue.serverTimestamp(),
            'actionTaken': actionTaken,
          });
    } catch (e) {
      throw DatabaseFailure(message: 'Erreur lors de l\'accusé de réception: $e', originalError: e);
    }
  }

  /// Mark alert as read
  Future<void> markAsRead(String alertId) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alertId)
          .update({'isRead': true});
    } catch (e) {
      throw DatabaseFailure(message: 'Erreur lors de la mise à jour: $e', originalError: e);
    }
  }

  /// Get unacknowledged critical alerts for dashboard
  Stream<List<AlertModel>> getUnacknowledgedCriticalAlerts() {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('severity', isEqualTo: AppConstants.alertSeverityCritical)
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Delete old alerts (older than 30 days)
  Future<void> cleanupOldAlerts() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    try {
      final snapshot = await _firestore
          .collection(AppConstants.alertsCollection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw DatabaseFailure(message: 'Erreur lors du nettoyage: $e', originalError: e);
    }
  }
}