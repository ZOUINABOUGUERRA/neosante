import 'dart:async';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/app_constants.dart';

/// Offline sync service for managing offline data and synchronizing with Firestore.
/// Implements offline-first architecture with queue-based sync.
class OfflineSyncService {
  static late Box _offlineBox;
  static late Box _syncQueue;
  static final StreamController<bool> _syncStatusController =
      StreamController<bool>.broadcast();
  static bool _isSyncing = false;
  static Timer? _syncTimer;

  /// Initialize offline storage and sync service
  static Future<void> initialize() async {
    _offlineBox = await Hive.openBox(AppConstants.hiveOfflineBox);
    _syncQueue = await Hive.openBox(AppConstants.hiveSyncQueueBox);

    // Start periodic sync
    _startPeriodicSync();

    // Listen to connectivity
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _syncPendingOperations();
      }
    });
  }

  /// Start periodic sync every 30 seconds
  static void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: AppConstants.syncRetryIntervalSeconds),
      (_) => _syncPendingOperations(),
    );
  }

  /// Save dossier offline when network is unavailable
  static Future<void> saveDossierOffline(
      String collection, String docId, Map<String, dynamic> data) async {
    final key = '$collection/$docId';
    await _offlineBox.put(key, data);
    await addToSyncQueue('create', collection, docId, data);
  }

  /// Add operation to sync queue
  static Future<void> addToSyncQueue(String operation, String collection,
      String docId, Map<String, dynamic> data) async {
    final queueItem = {
      'operation': operation,
      'collection': collection,
      'docId': docId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    await _syncQueue.add(queueItem);
    _syncPendingOperations();
  }

  /// Get offline dossier
  static Future<Map<String, dynamic>?> getOfflineDossier(
      String collection, String docId) async {
    final key = '$collection/$docId';
    return _offlineBox.get(key);
  }

  /// Get all offline dossiers for a collection
  static Future<List<Map<String, dynamic>>> getAllOfflineDossiers(
      String collection) async {
    final List<Map<String, dynamic>> results = [];
    final prefix = '$collection/';

    for (final key in _offlineBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith(prefix)) {
        final data = _offlineBox.get(key);
        if (data != null) {
          results.add(Map<String, dynamic>.from(data));
        }
      }
    }

    return results;
  }

  /// Sync pending operations with Firestore
  static Future<void> _syncPendingOperations() async {
    if (_isSyncing) return;
    if (_syncQueue.isEmpty) return;

    // Check connectivity
    final results = await Connectivity().checkConnectivity();
    if (results.every((entry) => entry == ConnectivityResult.none)) return;

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      final List<int> keysToDelete = [];

      for (var i = 0; i < _syncQueue.length; i++) {
        final operation = _syncQueue.getAt(i) as Map<String, dynamic>;

        try {
          switch (operation['operation']) {
            case 'create':
            case 'update':
              await FirebaseFirestore.instance
                  .collection(operation['collection'])
                  .doc(operation['docId'])
                  .set(operation['data'], SetOptions(merge: true));
              break;
            case 'delete':
              await FirebaseFirestore.instance
                  .collection(operation['collection'])
                  .doc(operation['docId'])
                  .delete();
              break;
          }

          // Success - mark for deletion
          keysToDelete.add(i);

          // Update offline cache
          final key = '${operation['collection']}/${operation['docId']}';
          await _offlineBox.delete(key);
        } catch (e) {
          // Increment retry count
          final retryCount = (operation['retryCount'] ?? 0) + 1;
          operation['retryCount'] = retryCount;

          if (retryCount >= 5) {
            // Max retries exceeded, mark for deletion to avoid infinite loop
            keysToDelete.add(i);
          } else {
            // Update operation with new retry count
            await _syncQueue.putAt(i, operation);
          }
        }
      }

      // Delete successful operations (reverse order to maintain indices)
      for (final key in keysToDelete.reversed) {
        await _syncQueue.deleteAt(key);
      }
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }

  /// Clear all offline data (logout)
  static Future<void> clearAllOfflineData() async {
    await _offlineBox.clear();
    await _syncQueue.clear();
  }

  /// Get pending sync count
  static int get pendingSyncCount => _syncQueue.length;

  /// Stream sync status
  static Stream<bool> get syncStatusStream => _syncStatusController.stream;

  /// Force immediate sync
  static Future<void> forceSync() async {
    await _syncPendingOperations();
  }

  /// Check if data is available offline
  static Future<bool> isDataAvailableOffline(
      String collection, String docId) async {
    final key = '$collection/$docId';
    return _offlineBox.containsKey(key);
  }

  /// Get sync queue size
  static int getQueueSize() => _syncQueue.length;

  /// Dispose resources
  static void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}
