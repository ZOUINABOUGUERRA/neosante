import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/alert_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

/// Alert state class
class AlertState {
  final List<AlertModel> alerts;
  final bool isLoading;
  final String? error;
  final int criticalCount;
  final int warningCount;
  final int mediumCount;
  final int infoCount;

  const AlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.error = null,
    this.criticalCount = 0,
    this.warningCount = 0,
    this.mediumCount = 0,
    this.infoCount = 0,
  });

  AlertState copyWith({
    List<AlertModel>? alerts,
    bool? isLoading,
    String? error,
    int? criticalCount,
    int? warningCount,
    int? mediumCount,
    int? infoCount,
  }) {
    return AlertState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      criticalCount: criticalCount ?? this.criticalCount,
      warningCount: warningCount ?? this.warningCount,
      mediumCount: mediumCount ?? this.mediumCount,
      infoCount: infoCount ?? this.infoCount,
    );
  }

  int get totalUnacknowledged =>
      criticalCount + warningCount + mediumCount + infoCount;
  bool get hasCriticalAlerts => criticalCount > 0;
}

/// Alert provider
final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  return AlertNotifier();
});

/// Alert notifier for managing medical alerts
class AlertNotifier extends StateNotifier<AlertState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  StreamSubscription? _alertsSubscription;

  AlertNotifier() : super(const AlertState()) {
    _loadAlerts();
  }

  void _loadAlerts() {
    _alertsSubscription = _firestore
        .collection(AppConstants.alertsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final alerts = snapshot.docs
          .map((doc) =>
              AlertModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Count unacknowledged alerts by severity
      final critical = alerts
          .where((a) =>
              !a.isAcknowledged &&
              a.severity == AppConstants.alertSeverityCritical)
          .length;
      final warning = alerts
          .where((a) =>
              !a.isAcknowledged &&
              a.severity == AppConstants.alertSeverityWarning)
          .length;
      final medium = alerts
          .where((a) =>
              !a.isAcknowledged &&
              a.severity == AppConstants.alertSeverityMedium)
          .length;
      final info = alerts
          .where((a) =>
              !a.isAcknowledged && a.severity == AppConstants.alertSeverityInfo)
          .length;

      state = state.copyWith(
        alerts: alerts,
        criticalCount: critical,
        warningCount: warning,
        mediumCount: medium,
        infoCount: info,
      );
    });
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId, {String? actionTaken}) async {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alertId)
          .update({
        'isAcknowledged': true,
        'acknowledgedBy': currentUser.uid,
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'actionTaken': actionTaken,
      });
    } catch (e) {
      print('Error acknowledging alert: $e');
      rethrow;
    }
  }

  /// Acknowledge multiple alerts
  Future<void> acknowledgeMultipleAlerts(List<String> alertIds,
      {String? actionTaken}) async {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      for (final alertId in alertIds) {
        final ref =
            _firestore.collection(AppConstants.alertsCollection).doc(alertId);
        batch.update(ref, {
          'isAcknowledged': true,
          'acknowledgedBy': currentUser.uid,
          'acknowledgedAt': FieldValue.serverTimestamp(),
          'actionTaken': actionTaken,
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error acknowledging multiple alerts: $e');
      rethrow;
    }
  }

  /// Acknowledge all alerts of a specific severity
  Future<void> acknowledgeAllAlertsBySeverity(String severity) async {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection(AppConstants.alertsCollection)
          .where('severity', isEqualTo: severity)
          .where('isAcknowledged', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isAcknowledged': true,
          'acknowledgedBy': currentUser.uid,
          'acknowledgedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error acknowledging all alerts by severity: $e');
      rethrow;
    }
  }

  /// Get alerts for a specific dossier
  Future<List<AlertModel>> getAlertsForDossier(String dossierId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.alertsCollection)
          .where('dossierId', isEqualTo: dossierId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              AlertModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get unacknowledged alerts for a specific dossier
  Stream<List<AlertModel>> streamUnacknowledgedAlertsForDossier(
      String dossierId) {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('dossierId', isEqualTo: dossierId)
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AlertModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get critical alerts stream (for real-time monitoring)
  Stream<List<AlertModel>> streamCriticalAlerts() {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('severity', isEqualTo: AppConstants.alertSeverityCritical)
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AlertModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}

/// Filtered alerts provider
final filteredAlertsProvider = Provider<List<AlertModel>>((ref) {
  final alerts = ref.watch(alertProvider).alerts;
  final filter = ref.watch(alertFilterProvider);

  if (filter == 'all') return alerts;
  if (filter == 'unacknowledged') {
    return alerts.where((a) => !a.isAcknowledged).toList();
  }
  return alerts.where((a) => a.severity == filter).toList();
});

/// Alert filter state provider
final alertFilterProvider = StateProvider<String>((ref) => 'all');

/// Critical alerts count provider (for badge)
final criticalAlertsCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.alertsCollection)
      .where('severity', isEqualTo: AppConstants.alertSeverityCritical)
      .where('isAcknowledged', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Alerts by dossier provider
final alertsByDossierProvider =
    FutureProvider.family<List<AlertModel>, String>((ref, dossierId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(AppConstants.alertsCollection)
      .where('dossierId', isEqualTo: dossierId)
      .orderBy('timestamp', descending: true)
      .get();

  return snapshot.docs
      .map((doc) =>
          AlertModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
});
