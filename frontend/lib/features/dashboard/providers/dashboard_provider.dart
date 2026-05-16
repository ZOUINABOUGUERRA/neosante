import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/transfer_model.dart';
import '../../../services/auth_service.dart';

/// Dashboard statistics state class
class DashboardStats {
  final int activeDossiers;
  final int criticalAlerts;
  final int warningAlerts;
  final int mediumAlerts;
  final int infoAlerts;
  final int pendingTransfers;
  final int approvedTransfers;
  final int completedTransfers;
  final int unreadNotifications;
  final int prematureCount;
  final int fullTermCount;
  final DateTime lastUpdated;

  const DashboardStats({
    this.activeDossiers = 0,
    this.criticalAlerts = 0,
    this.warningAlerts = 0,
    this.mediumAlerts = 0,
    this.infoAlerts = 0,
    this.pendingTransfers = 0,
    this.approvedTransfers = 0,
    this.completedTransfers = 0,
    this.unreadNotifications = 0,
    this.prematureCount = 0,
    this.fullTermCount = 0,
    required this.lastUpdated,
  });

  DashboardStats copyWith({
    int? activeDossiers,
    int? criticalAlerts,
    int? warningAlerts,
    int? mediumAlerts,
    int? infoAlerts,
    int? pendingTransfers,
    int? approvedTransfers,
    int? completedTransfers,
    int? unreadNotifications,
    int? prematureCount,
    int? fullTermCount,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      activeDossiers: activeDossiers ?? this.activeDossiers,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      warningAlerts: warningAlerts ?? this.warningAlerts,
      mediumAlerts: mediumAlerts ?? this.mediumAlerts,
      infoAlerts: infoAlerts ?? this.infoAlerts,
      pendingTransfers: pendingTransfers ?? this.pendingTransfers,
      approvedTransfers: approvedTransfers ?? this.approvedTransfers,
      completedTransfers: completedTransfers ?? this.completedTransfers,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      prematureCount: prematureCount ?? this.prematureCount,
      fullTermCount: fullTermCount ?? this.fullTermCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Total alerts count
  int get totalAlerts =>
      criticalAlerts + warningAlerts + mediumAlerts + infoAlerts;

  /// Total transfers count
  int get totalTransfers =>
      pendingTransfers + approvedTransfers + completedTransfers;

  /// Total dossiers count
  int get totalDossiers => prematureCount + fullTermCount;

  /// Returns true if there are any critical alerts
  bool get hasCriticalAlerts => criticalAlerts > 0;

  /// Returns true if there are any pending transfers
  bool get hasPendingTransfers => pendingTransfers > 0;
}

/// Dashboard provider - manages dashboard statistics
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
  return DashboardNotifier();
});

/// Dashboard notifier for loading and managing dashboard statistics
class DashboardNotifier extends StateNotifier<DashboardStats> {
  //final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DashboardNotifier() : super(DashboardStats(lastUpdated: DateTime.now()));

  /// Load all dashboard statistics
  Future<void> loadStats() async {
    try {
      // Load all stats in parallel for better performance
      final results = await Future.wait<Object?>([
        _countActiveDossiers(),
        _countAlertsBySeverity(),
        _countTransfersByStatus(),
        _countUnreadNotifications(),
        _countDossiersByType(),
      ]);

      final alertStats = results[1] as Map<String, int>;
      final transferStats = results[2] as Map<String, int>;
      final dossierCounts = results[4] as Map<String, int>;

      state = state.copyWith(
        activeDossiers: results[0] as int,
        criticalAlerts: alertStats['critical'] ?? 0,
        warningAlerts: alertStats['warning'] ?? 0,
        mediumAlerts: alertStats['medium'] ?? 0,
        infoAlerts: alertStats['info'] ?? 0,
        pendingTransfers: transferStats['pending'] ?? 0,
        approvedTransfers: transferStats['approved'] ?? 0,
        completedTransfers: transferStats['completed'] ?? 0,
        unreadNotifications: results[3] as int,
        prematureCount: dossierCounts['premature'] ?? 0,
        fullTermCount: dossierCounts['fullTerm'] ?? 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // Keep existing state on error
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  /// Count active dossiers
  Future<int> _countActiveDossiers() async {
    try {
      final prematuresSnapshot = await _firestore
          .collection(AppConstants.dossiersPrematuresCollection)
          .where('status', isEqualTo: AppConstants.dossierStatusActive)
          .count()
          .get();

      final termeSnapshot = await _firestore
          .collection(AppConstants.dossiersATermeCollection)
          .where('status', isEqualTo: AppConstants.dossierStatusActive)
          .count()
          .get();

      return (prematuresSnapshot.count ?? 0) + (termeSnapshot.count ?? 0);
    } catch (e) {
      return 0;
    }
  }

  /// Count alerts by severity
  Future<Map<String, int>> _countAlertsBySeverity() async {
    try {
      final results = await Future.wait([
        _firestore
            .collection(AppConstants.alertsCollection)
            .where('severity', isEqualTo: AppConstants.alertSeverityCritical)
            .where('isAcknowledged', isEqualTo: false)
            .count()
            .get(),
        _firestore
            .collection(AppConstants.alertsCollection)
            .where('severity', isEqualTo: AppConstants.alertSeverityWarning)
            .where('isAcknowledged', isEqualTo: false)
            .count()
            .get(),
        _firestore
            .collection(AppConstants.alertsCollection)
            .where('severity', isEqualTo: AppConstants.alertSeverityMedium)
            .where('isAcknowledged', isEqualTo: false)
            .count()
            .get(),
        _firestore
            .collection(AppConstants.alertsCollection)
            .where('severity', isEqualTo: AppConstants.alertSeverityInfo)
            .where('isAcknowledged', isEqualTo: false)
            .count()
            .get(),
      ]);

      return {
        'critical': results[0].count ?? 0,
        'warning': results[1].count ?? 0,
        'medium': results[2].count ?? 0,
        'info': results[3].count ?? 0,
      };
    } catch (e) {
      return {'critical': 0, 'warning': 0, 'medium': 0, 'info': 0};
    }
  }

  /// Count transfers by status
  Future<Map<String, int>> _countTransfersByStatus() async {
    try {
      final results = await Future.wait([
        _firestore
            .collection(AppConstants.transfersCollection)
            .where('status', isEqualTo: AppConstants.transferStatusPending)
            .count()
            .get(),
        _firestore
            .collection(AppConstants.transfersCollection)
            .where('status', isEqualTo: AppConstants.transferStatusApproved)
            .count()
            .get(),
        _firestore
            .collection(AppConstants.transfersCollection)
            .where('status', isEqualTo: AppConstants.transferStatusCompleted)
            .count()
            .get(),
      ]);

      return {
        'pending': results[0].count ?? 0,
        'approved': results[1].count ?? 0,
        'completed': results[2].count ?? 0,
      };
    } catch (e) {
      return {'pending': 0, 'approved': 0, 'completed': 0};
    }
  }

  /// Count unread notifications for current user
  Future<int> _countUnreadNotifications() async {
    try {
      final authService = AuthService();
      final currentUser = authService.currentFirebaseUser;
      if (currentUser == null) return 0;

      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Count dossiers by type
  Future<Map<String, int>> _countDossiersByType() async {
    try {
      final prematuresSnapshot = await _firestore
          .collection(AppConstants.dossiersPrematuresCollection)
          .count()
          .get();

      final termeSnapshot = await _firestore
          .collection(AppConstants.dossiersATermeCollection)
          .count()
          .get();

      return {
        'premature': prematuresSnapshot.count ?? 0,
        'fullTerm': termeSnapshot.count ?? 0,
      };
    } catch (e) {
      return {'premature': 0, 'fullTerm': 0};
    }
  }

  /// Refresh dashboard stats
  Future<void> refresh() async {
    await loadStats();
  }

  /// Get alert color for severity
  static int getAlertColor(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return 0xFFFF3B3B;
      case AppConstants.alertSeverityWarning:
        return 0xFFFFA500;
      case AppConstants.alertSeverityMedium:
        return 0xFFFFD700;
      default:
        return 0xFF4CAF50;
    }
  }

  /// Get alert label for severity
  static String getAlertLabel(String severity) {
    switch (severity) {
      case AppConstants.alertSeverityCritical:
        return 'Urgence';
      case AppConstants.alertSeverityWarning:
        return 'Surveillance';
      case AppConstants.alertSeverityMedium:
        return 'Attention';
      default:
        return 'Information';
    }
  }
}

/// Recent dossiers stream provider (premature + full term combined)
final recentDossiersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = FirebaseFirestore.instance;

  // Combine streams from both collections
  final prematureStream = firestore
      .collection(AppConstants.dossiersPrematuresCollection)
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.dashboardRecentLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['type'] = 'premature';
            return data;
          }).toList());

  final fullTermStream = firestore
      .collection(AppConstants.dossiersATermeCollection)
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.dashboardRecentLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['type'] = 'fullterm';
            return data;
          }).toList());

  // Combine and sort by creation date
  return StreamZip([prematureStream, fullTermStream]).map((lists) {
    final allDossiers = [...lists[0], ...lists[1]];
    allDossiers.sort((a, b) {
      final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return allDossiers.take(AppConstants.dashboardRecentLimit).toList();
  });
});

/// Recent alerts stream provider
final recentAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection(AppConstants.alertsCollection)
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AlertModel.fromJson(doc.data(), doc.id))
          .toList());
});

/// Recent transfers stream provider
final recentTransfersProvider = StreamProvider<List<TransferModel>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection(AppConstants.transfersCollection)
      .orderBy('requestedAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
          .toList());
});

/// Critical alerts count provider (for badge display)
final criticalAlertsCountProvider = StreamProvider<int>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection(AppConstants.alertsCollection)
      .where('severity', isEqualTo: AppConstants.alertSeverityCritical)
      .where('isAcknowledged', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Pending transfers count provider (for badge display)
final pendingTransfersCountProvider = StreamProvider<int>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection(AppConstants.transfersCollection)
      .where('status', isEqualTo: AppConstants.transferStatusPending)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Unread notifications count provider (for badge display)
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final firestore = FirebaseFirestore.instance;
  final authService = AuthService();
  final currentUser = authService.currentFirebaseUser;

  if (currentUser == null) {
    return Stream.value(0);
  }

  return firestore
      .collection(AppConstants.notificationsCollection)
      .where('userId', isEqualTo: currentUser.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Weekly activity chart data provider
final weeklyActivityProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);

  final snapshot = await firestore
      .collectionGroup('dossiers') // This requires a collection group index
      .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
      .get();

  // Group by day
  final Map<String, int> dailyCount = {};
  for (var i = 0; i < 7; i++) {
    final date = DateTime(now.year, now.month, now.day - i);
    final key = '${date.day}/${date.month}';
    dailyCount[key] = 0;
  }

  for (final doc in snapshot.docs) {
    final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
    if (createdAt != null) {
      final key = '${createdAt.day}/${createdAt.month}';
      if (dailyCount.containsKey(key)) {
        dailyCount[key] = (dailyCount[key] ?? 0) + 1;
      }
    }
  }

  return dailyCount.entries
      .map((e) => {
            'day': e.key,
            'count': e.value,
          })
      .toList();
});
