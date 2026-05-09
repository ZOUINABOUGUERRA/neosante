import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/dossier_model.dart';

/// Archive state class
class ArchiveState {
  final List<Map<String, dynamic>> archives;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final int prematureCount;
  final int fullTermCount;

  const ArchiveState({
    this.archives = const [],
    this.isLoading = false,
    this.error = null,
    this.totalCount = 0,
    this.prematureCount = 0,
    this.fullTermCount = 0,
  });

  ArchiveState copyWith({
    List<Map<String, dynamic>>? archives,
    bool? isLoading,
    String? error,
    int? totalCount,
    int? prematureCount,
    int? fullTermCount,
  }) {
    return ArchiveState(
      archives: archives ?? this.archives,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalCount: totalCount ?? this.totalCount,
      prematureCount: prematureCount ?? this.prematureCount,
      fullTermCount: fullTermCount ?? this.fullTermCount,
    );
  }
}

/// Archive provider
final archiveProvider =
    StateNotifierProvider<ArchiveNotifier, ArchiveState>((ref) {
  return ArchiveNotifier();
});

/// Archive notifier for managing archived dossiers
class ArchiveNotifier extends StateNotifier<ArchiveState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _archivesSubscription;

  ArchiveNotifier() : super(const ArchiveState()) {
    _loadArchives();
  }

  void _loadArchives() {
    _archivesSubscription = _firestore
        .collection(AppConstants.archivesCollection)
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final archives = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      final prematureCount = archives
          .where((a) =>
              a['originalCollection'] ==
                  AppConstants.dossiersPrematuresCollection ||
              a['serviceType'] == AppConstants.servicePremature)
          .length;

      final fullTermCount = archives
          .where((a) =>
              a['originalCollection'] ==
                  AppConstants.dossiersATermeCollection ||
              a['serviceType'] == AppConstants.serviceFullTerm)
          .length;

      state = state.copyWith(
        archives: archives,
        totalCount: archives.length,
        prematureCount: prematureCount,
        fullTermCount: fullTermCount,
      );
    });
  }

  /// Restore an archived dossier
  Future<String?> restoreArchive(String archiveId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get archive document
      final archiveDoc = await _firestore
          .collection(AppConstants.archivesCollection)
          .doc(archiveId)
          .get();

      if (!archiveDoc.exists) {
        throw Exception('Archive non trouvée');
      }

      final archiveData = archiveDoc.data() as Map<String, dynamic>;
      final originalCollection = archiveData['originalCollection'] ??
          (archiveData['serviceType'] == AppConstants.servicePremature
              ? AppConstants.dossiersPrematuresCollection
              : AppConstants.dossiersATermeCollection);

      // Remove archive-specific fields
      final restoreData = Map<String, dynamic>.from(archiveData);
      restoreData.remove('archivedAt');
      restoreData.remove('originalCollection');
      restoreData['status'] = AppConstants.dossierStatusActive;
      restoreData['restoredAt'] = FieldValue.serverTimestamp();

      // Restore to original collection
      await _firestore
          .collection(originalCollection)
          .doc(archiveId)
          .set(restoreData);

      // Delete from archives
      await _firestore
          .collection(AppConstants.archivesCollection)
          .doc(archiveId)
          .delete();

      state = state.copyWith(isLoading: false);
      return archiveId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Permanently delete an archive
  Future<bool> deleteArchivePermanently(String archiveId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestore
          .collection(AppConstants.archivesCollection)
          .doc(archiveId)
          .delete();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete all archives older than days
  Future<int> deleteOldArchives(int days) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final snapshot = await _firestore
          .collection(AppConstants.archivesCollection)
          .where('archivedAt', isLessThan: cutoffTimestamp)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      state = state.copyWith(isLoading: false);
      return snapshot.docs.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  /// Search archives by query
  Future<List<Map<String, dynamic>>> searchArchives(String query) async {
    if (query.isEmpty) return state.archives;

    final lowerQuery = query.toLowerCase();
    return state.archives.where((archive) {
      return (archive['newbornName']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerQuery) ??
              false) ||
          (archive['motherName']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerQuery) ??
              false) ||
          (archive['dossierNumber']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerQuery) ??
              false);
    }).toList();
  }

  /// Get archive statistics
  Map<String, dynamic> getStatistics() {
    final archives = state.archives;
    final now = DateTime.now();

    // Count by month
    final Map<String, int> byMonth = {};
    for (final archive in archives) {
      final archivedAt = archive['archivedAt'] as Timestamp?;
      if (archivedAt != null) {
        final date = archivedAt.toDate();
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        byMonth[monthKey] = (byMonth[monthKey] ?? 0) + 1;
      }
    }

    return {
      'total': state.totalCount,
      'premature': state.prematureCount,
      'fullTerm': state.fullTermCount,
      'byMonth': byMonth,
    };
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _archivesSubscription?.cancel();
    super.dispose();
  }
}

/// Archive search provider
final archiveSearchProvider = StateProvider<String>((ref) => '');

/// Filtered archives provider
final filteredArchivesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final archives = ref.watch(archiveProvider).archives;
  final searchQuery = ref.watch(archiveSearchProvider);

  if (searchQuery.isEmpty) return archives;

  final lowerQuery = searchQuery.toLowerCase();
  return archives.where((archive) {
    return (archive['newbornName']
                ?.toString()
                .toLowerCase()
                .contains(lowerQuery) ??
            false) ||
        (archive['motherName']?.toString().toLowerCase().contains(lowerQuery) ??
            false) ||
        (archive['dossierNumber']
                ?.toString()
                .toLowerCase()
                .contains(lowerQuery) ??
            false);
  }).toList();
});
