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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// =====================================================
  /// Evaluate dossier and generate alerts
  /// =====================================================

  Future<List<AlertModel>>
      evaluateAndGenerateAlerts(
    DossierModel dossier,
  ) async {
    final List<AlertModel> generatedAlerts =
        [];

    // Glucose
    final glucoseAlert =
        _evaluateGlucoseAlert(dossier);

    if (glucoseAlert != null) {
      generatedAlerts.add(glucoseAlert);
    }

    // Temperature
    final tempAlert =
        _evaluateTemperatureAlert(dossier);

    if (tempAlert != null) {
      generatedAlerts.add(tempAlert);
    }

    // APGAR
    final apgarAlert =
        _evaluateApgarAlert(dossier);

    if (apgarAlert != null) {
      generatedAlerts.add(apgarAlert);
    }

    // Respiration
    final respAlert =
        _evaluateRespirationAlert(dossier);

    if (respAlert != null) {
      generatedAlerts.add(respAlert);
    }

    // Tonus
    final tonusAlert =
        _evaluateTonusAlert(dossier);

    if (tonusAlert != null) {
      generatedAlerts.add(tonusAlert);
    }

    // Cry
    final cryAlert =
        _evaluateCryAlert(dossier);

    if (cryAlert != null) {
      generatedAlerts.add(cryAlert);
    }

    // Save alerts
    for (final alert in generatedAlerts) {
      await _saveAlert(alert);
    }

    // Update dossier severity
    if (generatedAlerts.isNotEmpty) {
      await _updateDossierAlertSeverity(
        dossier.id,
        generatedAlerts,
      );
    }

    return generatedAlerts;
  }

  /// =====================================================
  /// GLUCOSE
  /// =====================================================

  AlertModel? _evaluateGlucoseAlert(
    DossierModel dossier,
  ) {
    final evaluation =
        GlucoseCalculator.evaluateGlucose(
      dossier.bloodGlucose,
    );

    if (evaluation.severity !=
        AppConstants.alertSeverityInfo) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
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

  /// =====================================================
  /// TEMPERATURE
  /// =====================================================

  AlertModel? _evaluateTemperatureAlert(
    DossierModel dossier,
  ) {
    final temperature =
        dossier.bodyTemperature;

    if (temperature <
        AppConstants.temperatureEmergency) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'temperature',
        value: temperature,
        severity:
            AppConstants.alertSeverityCritical,
        message:
            '🔴 TEMPÉRATURE CRITIQUE: $temperature°C - Hypothermie sévère',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    if (temperature <
        AppConstants.temperatureHypothermia) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'temperature',
        value: temperature,
        severity:
            AppConstants.alertSeverityWarning,
        message:
            '🟠 HYPOTHERMIE: $temperature°C - Réchauffement nécessaire',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    if (temperature >
        AppConstants.temperatureFever) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'temperature',
        value: temperature,
        severity:
            AppConstants.alertSeverityCritical,
        message:
            '🔴 RISQUE INFECTIEUX: $temperature°C - Évaluation urgente',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  /// =====================================================
  /// APGAR
  /// =====================================================

  AlertModel? _evaluateApgarAlert(
    DossierModel dossier,
  ) {
    final evaluation =
        ApgarEvaluator.evaluateApgar(
      dossier.apgar1,
      minute: 1,
    );

    if (evaluation.severity !=
        AppConstants.alertSeverityInfo) {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
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

  /// =====================================================
  /// RESPIRATION
  /// =====================================================

  AlertModel? _evaluateRespirationAlert(
    DossierModel dossier,
  ) {
    final respiration =
        dossier.respiration.toLowerCase();

    if (respiration == 'absente') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'respiration',
        value: respiration,
        severity:
            AppConstants.alertSeverityCritical,
        message:
            '🔴 RESPIRATION ABSENTE - Réanimation immédiate',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    if (respiration ==
        'faible irrégulière') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'respiration',
        value: respiration,
        severity:
            AppConstants.alertSeverityWarning,
        message:
            '🟠 RESPIRATION FAIBLE/IRRÉGULIÈRE - Assistance respiratoire',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  /// =====================================================
  /// TONUS
  /// =====================================================

  AlertModel? _evaluateTonusAlert(
    DossierModel dossier,
  ) {
    final tonus =
        dossier.tonus.toLowerCase();

    if (tonus == 'flasque') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'tonus',
        value: tonus,
        severity:
            AppConstants.alertSeverityWarning,
        message:
            '🟠 TONUS FLASQUE - Évaluation neurologique urgente',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  /// =====================================================
  /// CRY
  /// =====================================================

  AlertModel? _evaluateCryAlert(
    DossierModel dossier,
  ) {
    final cry =
        dossier.cry.toLowerCase();

    if (cry == 'absent') {
      return AlertModel(
        id: '',
        dossierId: dossier.id,
        dossierNumber:
            dossier.dossierNumber,
        newbornName: dossier.newbornName,
        parameter: 'cri',
        value: cry,
        severity:
            AppConstants.alertSeverityCritical,
        message:
            '🔴 CRI ABSENT - Réanimation respiratoire',
        isRead: false,
        isAcknowledged: false,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  /// =====================================================
  /// SAVE ALERT
  /// =====================================================

  Future<void> _saveAlert(
    AlertModel alert,
  ) async {
    try {
      final docRef = _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .doc();

      await docRef.set(
        alert
            .copyWith(id: docRef.id)
            .toJson(),
      );
    } catch (e) {
      throw DatabaseFailure(
        message:
            'Erreur sauvegarde alerte: $e',
        originalError: e,
      );
    }
  }

  /// =====================================================
  /// UPDATE DOSSIER ALERT SEVERITY
  /// =====================================================

  Future<void>
      _updateDossierAlertSeverity(
    String dossierId,
    List<AlertModel> alerts,
  ) async {
    final severities =
        alerts.map((e) => e.severity);

    String highestSeverity =
        AppConstants.alertSeverityInfo;

    if (severities.contains(
      AppConstants.alertSeverityCritical,
    )) {
      highestSeverity =
          AppConstants.alertSeverityCritical;
    } else if (severities.contains(
      AppConstants.alertSeverityWarning,
    )) {
      highestSeverity =
          AppConstants.alertSeverityWarning;
    } else if (severities.contains(
      AppConstants.alertSeverityMedium,
    )) {
      highestSeverity =
          AppConstants.alertSeverityMedium;
    }

    try {
      await _firestore
          .collection(
            AppConstants
                .dossiersPrematuresCollection,
          )
          .doc(dossierId)
          .update({
        'alertSeverity':
            highestSeverity,
      });
    } catch (_) {
      try {
        await _firestore
            .collection(
              AppConstants
                  .dossiersATermeCollection,
            )
            .doc(dossierId)
            .update({
          'alertSeverity':
              highestSeverity,
        });
      } catch (e) {
        throw DatabaseFailure(
          message:
              'Erreur mise à jour sévérité: $e',
          originalError: e,
        );
      }
    }
  }

  /// =====================================================
  /// ACTIVE ALERTS
  /// =====================================================

  Stream<List<AlertModel>>
      getActiveAlerts(
    String dossierId,
  ) {
    return _firestore
        .collection(
          AppConstants.alertsCollection,
        )
        .where(
          'dossierId',
          isEqualTo: dossierId,
        )
        .where(
          'isAcknowledged',
          isEqualTo: false,
        )
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AlertModel.fromJson(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// =====================================================
  /// ALL ALERTS
  /// =====================================================

  Stream<List<AlertModel>>
      getAllAlerts(
    String dossierId,
  ) {
    return _firestore
        .collection(
          AppConstants.alertsCollection,
        )
        .where(
          'dossierId',
          isEqualTo: dossierId,
        )
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AlertModel.fromJson(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// =====================================================
  /// ACKNOWLEDGE ALERT
  /// =====================================================

  Future<void> acknowledgeAlert(
    String alertId,
    String acknowledgedBy, {
    String? actionTaken,
  }) async {
    try {
      await _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .doc(alertId)
          .update({
        'isAcknowledged': true,
        'acknowledgedBy':
            acknowledgedBy,
        'acknowledgedAt':
            FieldValue.serverTimestamp(),
        'actionTaken': actionTaken,
      });
    } catch (e) {
      throw DatabaseFailure(
        message:
            'Erreur accusé réception: $e',
        originalError: e,
      );
    }
  }

  /// =====================================================
  /// MARK AS READ
  /// =====================================================

  Future<void> markAsRead(
    String alertId,
  ) async {
    try {
      await _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .doc(alertId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      throw DatabaseFailure(
        message:
            'Erreur mise à jour lecture: $e',
        originalError: e,
      );
    }
  }

  /// =====================================================
  /// CRITICAL ALERTS
  /// =====================================================

  Stream<List<AlertModel>>
      getUnacknowledgedCriticalAlerts() {
    return _firestore
        .collection(
          AppConstants.alertsCollection,
        )
        .where(
          'severity',
          isEqualTo:
              AppConstants
                  .alertSeverityCritical,
        )
        .where(
          'isAcknowledged',
          isEqualTo: false,
        )
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AlertModel.fromJson(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  /// =====================================================
  /// CLEANUP OLD ALERTS
  /// =====================================================

  Future<void> cleanupOldAlerts() async {
    final cutoffDate = DateTime.now()
        .subtract(
      const Duration(days: 30),
    );

    try {
      final snapshot = await _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .where(
            'timestamp',
            isLessThan:
                Timestamp.fromDate(
              cutoffDate,
            ),
          )
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw DatabaseFailure(
        message:
            'Erreur nettoyage alertes: $e',
        originalError: e,
      );
    }
  }
}