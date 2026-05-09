import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/dossier_model.dart';
import '../../../services/alert_service.dart';
import '../../../core/errors/failure.dart';

/// Dossier state class
class DossierState {
  final List<DossierModel> dossiers;
  final bool isLoading;
  final Failure? error;
  final String? selectedDossierId;

  const DossierState({
    this.dossiers = const [],
    this.isLoading = false,
    this.error,
    this.selectedDossierId,
  });

  DossierState copyWith({
    List<DossierModel>? dossiers,
    bool? isLoading,
    Failure? error,
    String? selectedDossierId,
  }) {
    return DossierState(
      dossiers: dossiers ?? this.dossiers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedDossierId: selectedDossierId ?? this.selectedDossierId,
    );
  }
}

/// Dossier provider
final dossierProvider = StateNotifierProvider<DossierNotifier, DossierState>((ref) {
  return DossierNotifier();
});

/// Dossier notifier for managing dossier operations
class DossierNotifier extends StateNotifier<DossierState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AlertService _alertService = AlertService();

  DossierNotifier() : super(const DossierState());

  /// Load all dossiers for a collection
  Future<void> loadDossiers(String collection, {String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      Query query = _firestore.collection(collection).orderBy('createdAt', descending: true);
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      final snapshot = await query.get();
      final dossiers = snapshot.docs
          .map((doc) => DossierModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      state = state.copyWith(dossiers: dossiers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(message: 'Erreur lors du chargement: $e'),
      );
    }
  }

  /// Load a single dossier
  Future<DossierModel?> loadDossier(String collection, String dossierId) async {
    try {
      final doc = await _firestore.collection(collection).doc(dossierId).get();
      if (!doc.exists) return null;
      return DossierModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Create a new dossier
  Future<String> createDossier(String collection, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final docRef = _firestore.collection(collection).doc();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['status'] = AppConstants.dossierStatusActive;
      
      await docRef.set(data);
      
      // Generate alerts based on initial data
      final dossier = DossierModel.fromJson(data, docRef.id);
      await _alertService.evaluateAndGenerateAlerts(dossier);
      
      state = state.copyWith(isLoading: false);
      return docRef.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(message: 'Erreur lors de la création: $e'),
      );
      rethrow;
    }
  }

  /// Update a dossier
  Future<void> updateDossier(String collection, String dossierId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(collection).doc(dossierId).update(data);
      
      // Re-evaluate alerts
      final dossier = await loadDossier(collection, dossierId);
      if (dossier != null) {
        await _alertService.evaluateAndGenerateAlerts(dossier);
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(message: 'Erreur lors de la mise à jour: $e'),
      );
      rethrow;
    }
  }

  /// Archive a dossier
  Future<void> archiveDossier(String collection, String dossierId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dossier = await loadDossier(collection, dossierId);
      if (dossier != null) {
        // Copy to archives
        await _firestore.collection(AppConstants.archivesCollection).doc(dossierId).set({
          ...dossier.toJson(),
          'archivedAt': FieldValue.serverTimestamp(),
          'originalCollection': collection,
        });
        
        // Delete from original collection
        await _firestore.collection(collection).doc(dossierId).delete();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(message: 'Erreur lors de l\'archivage: $e'),
      );
      rethrow;
    }
  }

  /// Stream dossiers for real-time updates
  Stream<List<DossierModel>> streamDossiers(String collection, {String? status}) {
    Query query = _firestore.collection(collection).orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DossierModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}