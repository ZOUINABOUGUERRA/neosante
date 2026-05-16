import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/alert_model.dart';
import '../../../services/auth_service.dart';

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
    this.error,
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
      error: error,
      criticalCount: criticalCount ?? this.criticalCount,
      warningCount: warningCount ?? this.warningCount,
      mediumCount: mediumCount ?? this.mediumCount,
      infoCount: infoCount ?? this.infoCount,
    );
  }

  int get totalUnacknowledged =>
      criticalCount +
      warningCount +
      mediumCount +
      infoCount;

  bool get hasCriticalAlerts => criticalCount > 0;
}

/// Alert Provider
final alertProvider =
    StateNotifierProvider<AlertNotifier, AlertState>(
  (ref) => AlertNotifier(),
);

/// Alert Notifier
class AlertNotifier extends StateNotifier<AlertState> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final AuthService _authService =
      AuthService();

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _alertsSubscription;

  AlertNotifier()
      : super(
          const AlertState(
            isLoading: true,
          ),
        ) {
    _loadAlerts();
  }

  /// Load realtime alerts
  void _loadAlerts() {
    try {
      _alertsSubscription?.cancel();

      _alertsSubscription = _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .orderBy(
            'timestamp',
            descending: true,
          )
          .snapshots()
          .listen(
        (snapshot) {
          final alerts = snapshot.docs
              .map(
                (doc) => AlertModel.fromJson(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList();

          final critical = alerts
              .where(
                (a) =>
                    !a.isAcknowledged &&
                    a.severity ==
                        AppConstants
                            .alertSeverityCritical,
              )
              .length;

          final warning = alerts
              .where(
                (a) =>
                    !a.isAcknowledged &&
                    a.severity ==
                        AppConstants
                            .alertSeverityWarning,
              )
              .length;

          final medium = alerts
              .where(
                (a) =>
                    !a.isAcknowledged &&
                    a.severity ==
                        AppConstants
                            .alertSeverityMedium,
              )
              .length;

          final info = alerts
              .where(
                (a) =>
                    !a.isAcknowledged &&
                    a.severity ==
                        AppConstants
                            .alertSeverityInfo,
              )
              .length;

          state = state.copyWith(
            alerts: alerts,
            isLoading: false,
            error: null,
            criticalCount: critical,
            warningCount: warning,
            mediumCount: medium,
            infoCount: info,
          );
        },
        onError: (error) {
          state = state.copyWith(
            isLoading: false,
            error: error.toString(),
          );

          if (kDebugMode) {
            debugPrint(
              '❌ Error loading alerts: $error',
            );
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      if (kDebugMode) {
        debugPrint(
          '❌ Alert Provider Error: $e',
        );
      }
    }
  }

  /// Acknowledge single alert
  Future<void> acknowledgeAlert(
    String alertId, {
    String? actionTaken,
  }) async {
    final currentUser =
        _authService.currentFirebaseUser;

    if (currentUser == null) {
      state = state.copyWith(
        error: 'Utilisateur non connecté',
      );
      return;
    }

    try {
      await _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .doc(alertId)
          .update({
        'isAcknowledged': true,
        'acknowledgedBy':
            currentUser.uid,
        'acknowledgedAt':
            FieldValue.serverTimestamp(),
        'actionTaken': actionTaken,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error acknowledging alert: $e',
        );
      }

      state = state.copyWith(
        error: e.toString(),
      );

      rethrow;
    }
  }

  /// Acknowledge multiple alerts
  Future<void>
      acknowledgeMultipleAlerts(
    List<String> alertIds, {
    String? actionTaken,
  }) async {
    final currentUser =
        _authService.currentFirebaseUser;

    if (currentUser == null) {
      state = state.copyWith(
        error: 'Utilisateur non connecté',
      );
      return;
    }

    try {
      final batch =
          _firestore.batch();

      for (final alertId in alertIds) {
        final ref = _firestore
            .collection(
              AppConstants.alertsCollection,
            )
            .doc(alertId);

        batch.update(ref, {
          'isAcknowledged': true,
          'acknowledgedBy':
              currentUser.uid,
          'acknowledgedAt':
              FieldValue.serverTimestamp(),
          'actionTaken':
              actionTaken ?? '',
        });
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error acknowledging multiple alerts: $e',
        );
      }

      state = state.copyWith(
        error: e.toString(),
      );

      rethrow;
    }
  }

  /// Acknowledge all alerts by severity
  Future<void>
      acknowledgeAllAlertsBySeverity(
    String severity,
  ) async {
    final currentUser =
        _authService.currentFirebaseUser;

    if (currentUser == null) {
      state = state.copyWith(
        error: 'Utilisateur non connecté',
      );
      return;
    }

    try {
      final snapshot =
          await _firestore
              .collection(
                AppConstants
                    .alertsCollection,
              )
              .where(
                'severity',
                isEqualTo: severity,
              )
              .where(
                'isAcknowledged',
                isEqualTo: false,
              )
              .get();

      final batch =
          _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'isAcknowledged': true,
            'acknowledgedBy':
                currentUser.uid,
            'acknowledgedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error acknowledge severity alerts: $e',
        );
      }

      state = state.copyWith(
        error: e.toString(),
      );

      rethrow;
    }
  }

  /// Get alerts for dossier
  Future<List<AlertModel>>
      getAlertsForDossier(
    String dossierId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(
                AppConstants
                    .alertsCollection,
              )
              .where(
                'dossierId',
                isEqualTo: dossierId,
              )
              .orderBy(
                'timestamp',
                descending: true,
              )
              .get();

      return snapshot.docs
          .map(
            (doc) => AlertModel.fromJson(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error getting dossier alerts: $e',
        );
      }

      return [];
    }
  }

  /// Stream dossier alerts
  Stream<List<AlertModel>>
      streamUnacknowledgedAlertsForDossier(
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

  /// Stream critical alerts
  Stream<List<AlertModel>>
      streamCriticalAlerts() {
    return _firestore
        .collection(
          AppConstants.alertsCollection,
        )
        .where(
          'severity',
          isEqualTo: AppConstants
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

  /// Mark as read
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
      if (kDebugMode) {
        debugPrint(
          '❌ Error mark as read: $e',
        );
      }

      rethrow;
    }
  }

  /// Delete alert
  Future<void> deleteAlert(
    String alertId,
  ) async {
    try {
      await _firestore
          .collection(
            AppConstants.alertsCollection,
          )
          .doc(alertId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Error deleting alert: $e',
        );
      }

      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(
      error: null,
    );
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}

/// Filter Provider
final alertFilterProvider =
    StateProvider<String>(
  (ref) => 'all',
);

/// Filtered Alerts Provider
final filteredAlertsProvider =
    Provider<List<AlertModel>>(
  (ref) {
    final alerts =
        ref.watch(alertProvider).alerts;

    final filter =
        ref.watch(alertFilterProvider);

    switch (filter) {
      case 'critical':
        return alerts
            .where(
              (a) =>
                  a.severity ==
                  AppConstants
                      .alertSeverityCritical,
            )
            .toList();

      case 'warning':
        return alerts
            .where(
              (a) =>
                  a.severity ==
                  AppConstants
                      .alertSeverityWarning,
            )
            .toList();

      case 'medium':
        return alerts
            .where(
              (a) =>
                  a.severity ==
                  AppConstants
                      .alertSeverityMedium,
            )
            .toList();

      case 'info':
        return alerts
            .where(
              (a) =>
                  a.severity ==
                  AppConstants
                      .alertSeverityInfo,
            )
            .toList();

      case 'unacknowledged':
        return alerts
            .where(
              (a) =>
                  !a.isAcknowledged,
            )
            .toList();

      default:
        return alerts;
    }
  },
);

/// Critical Alerts Count Provider
final criticalAlertsCountProvider =
    StreamProvider<int>(
  (ref) {
    return FirebaseFirestore.instance
        .collection(
          AppConstants.alertsCollection,
        )
        .where(
          'severity',
          isEqualTo: AppConstants
              .alertSeverityCritical,
        )
        .where(
          'isAcknowledged',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.length,
        );
  },
);

/// Alerts by dossier provider
final alertsByDossierProvider =
    FutureProvider.family<
        List<AlertModel>,
        String>(
  (
    ref,
    dossierId,
  ) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection(
              AppConstants
                  .alertsCollection,
            )
            .where(
              'dossierId',
              isEqualTo: dossierId,
            )
            .orderBy(
              'timestamp',
              descending: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => AlertModel.fromJson(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  },
);