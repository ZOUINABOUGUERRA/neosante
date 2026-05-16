import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/dossier_model.dart';
import '../../../services/alert_service.dart';
import '../../../core/errors/failure.dart';

/// ===============================
/// DOSSIER STATE
/// ===============================
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
    bool clearError = false,
  }) {
    return DossierState(
      dossiers: dossiers ?? this.dossiers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      selectedDossierId:
          selectedDossierId ?? this.selectedDossierId,
    );
  }
}

/// ===============================
/// PROVIDER
/// ===============================
final dossierProvider =
    StateNotifierProvider<DossierNotifier, DossierState>(
  (ref) => DossierNotifier(),
);

/// ===============================
/// NOTIFIER
/// ===============================
class DossierNotifier
    extends StateNotifier<DossierState> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final AlertService _alertService =
      AlertService();

  DossierNotifier()
      : super(const DossierState());

  /// ===============================
  /// HELPERS
  /// ===============================
  String getCollectionByServiceType(
    String serviceType,
  ) {
    return serviceType ==
            AppConstants.servicePremature
        ? AppConstants
            .dossiersPrematuresCollection
        : AppConstants
            .dossiersATermeCollection;
  }

  /// ===============================
  /// LOAD DOSSIERS
  /// ===============================
  Future<void> loadDossiers(
    String collection, {
    String? status,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      Query query = _firestore
          .collection(collection)
          .orderBy(
            'createdAt',
            descending: true,
          );

      if (status != null &&
          status != 'all') {
        query = query.where(
          'status',
          isEqualTo: status,
        );
      }

      final snapshot = await query.get();

      final dossiers = snapshot.docs
          .where(
            (doc) =>
                (doc.data()
                        as Map<String, dynamic>)
                    .isNotEmpty,
          )
          .map(
            (doc) => DossierModel.fromJson(
              doc.data()
                  as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      state = state.copyWith(
        dossiers: dossiers,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Load dossiers error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(
          message:
              'Erreur lors du chargement: $e',
        ),
      );
    }
  }

  /// ===============================
  /// LOAD ALL DOSSIERS
  /// ===============================
  Future<void> loadAllDossiers({
    String? status,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      List<DossierModel> allDossiers =
          [];

      final prematureSnapshot =
          await _firestore
              .collection(
                AppConstants
                    .dossiersPrematuresCollection,
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .get();

      final fulltermSnapshot =
          await _firestore
              .collection(
                AppConstants
                    .dossiersATermeCollection,
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .get();

      allDossiers.addAll(
        prematureSnapshot.docs
            .where(
              (doc) => doc
                  .data()
                  .isNotEmpty,
            )
            .map(
              (doc) =>
                  DossierModel.fromJson(
                doc.data(),
                doc.id,
              ),
            ),
      );

      allDossiers.addAll(
        fulltermSnapshot.docs
            .where(
              (doc) => doc
                  .data()
                  .isNotEmpty,
            )
            .map(
              (doc) =>
                  DossierModel.fromJson(
                doc.data(),
                doc.id,
              ),
            ),
      );

      if (status != null &&
          status != 'all') {
        allDossiers = allDossiers
            .where(
              (dossier) =>
                  dossier.status ==
                  status,
            )
            .toList();
      }

      allDossiers.sort(
        (a, b) => b.createdAt.compareTo(
          a.createdAt,
        ),
      );

      state = state.copyWith(
        dossiers: allDossiers,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Load all dossiers error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(
          message:
              'Erreur lors du chargement: $e',
        ),
      );
    }
  }

  /// ===============================
  /// LOAD SINGLE DOSSIER
  /// ===============================
  Future<DossierModel?> loadDossier(
    String collection,
    String dossierId,
  ) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(dossierId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();

      if (data == null) {
        return null;
      }

      return DossierModel.fromJson(
        data,
        doc.id,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Load dossier error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  /// ===============================
  /// LOAD DOSSIER BY ID
  /// ===============================
  Future<DossierModel?>
      loadDossierById(
    String dossierId,
  ) async {
    try {
      var doc = await _firestore
          .collection(
            AppConstants
                .dossiersPrematuresCollection,
          )
          .doc(dossierId)
          .get();

      if (doc.exists &&
          doc.data() != null) {
        return DossierModel.fromJson(
          doc.data()!,
          doc.id,
        );
      }

      doc = await _firestore
          .collection(
            AppConstants
                .dossiersATermeCollection,
          )
          .doc(dossierId)
          .get();

      if (doc.exists &&
          doc.data() != null) {
        return DossierModel.fromJson(
          doc.data()!,
          doc.id,
        );
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint(
        'Load dossier by ID error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  /// ===============================
  /// CREATE DOSSIER
  /// ===============================
  Future<String> createDossier(
    String collection,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final docRef = _firestore
          .collection(collection)
          .doc();

      data['id'] = docRef.id;

      data['createdAt'] =
          FieldValue.serverTimestamp();

      data['status'] =
          AppConstants
              .dossierStatusActive;

      await docRef.set(data);

      final savedDoc =
          await docRef.get();

      final savedData =
          savedDoc.data();

      if (savedData == null) {
        throw Exception(
          'Dossier data not found',
        );
      }

      final dossier =
          DossierModel.fromJson(
        savedData,
        docRef.id,
      );

      await _alertService
          .evaluateAndGenerateAlerts(
        dossier,
      );

      await loadAllDossiers();

      state = state.copyWith(
        isLoading: false,
      );

      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint(
        'Create dossier error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(
          message:
              'Erreur lors de la création: $e',
        ),
      );

      rethrow;
    }
  }

  /// ===============================
  /// UPDATE DOSSIER
  /// ===============================
  Future<void> updateDossier(
    String collection,
    String dossierId,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      data['updatedAt'] =
          FieldValue.serverTimestamp();

      await _firestore
          .collection(collection)
          .doc(dossierId)
          .update(data);

      final dossier =
          await loadDossier(
        collection,
        dossierId,
      );

      if (dossier != null) {
        await _alertService
            .evaluateAndGenerateAlerts(
          dossier,
        );
      }

      await loadAllDossiers();

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Update dossier error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(
          message:
              'Erreur lors de la mise à jour: $e',
        ),
      );

      rethrow;
    }
  }

  /// ===============================
  /// ARCHIVE DOSSIER
  /// ===============================
  Future<void> archiveDossier(
    String collection,
    String dossierId,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final dossier =
          await loadDossier(
        collection,
        dossierId,
      );

      if (dossier != null) {
        await _firestore
            .collection(
              AppConstants
                  .archivesCollection,
            )
            .doc(dossierId)
            .set({
          ...dossier.toJson(),
          'archivedAt':
              FieldValue
                  .serverTimestamp(),
          'originalCollection':
              collection,
        });

        await _firestore
            .collection(collection)
            .doc(dossierId)
            .delete();
      }

      await loadAllDossiers();

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Archive dossier error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(
          message:
              'Erreur lors de l\'archivage: $e',
        ),
      );

      rethrow;
    }
  }

  /// ===============================
  /// DELETE DOSSIER
  /// ===============================
  Future<void> deleteDossier(
    String collection,
    String dossierId,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _firestore
          .collection(collection)
          .doc(dossierId)
          .delete();

      final archiveDoc =
          await _firestore
              .collection(
                AppConstants
                    .archivesCollection,
              )
              .doc(dossierId)
              .get();

      if (archiveDoc.exists) {
        await _firestore
            .collection(
              AppConstants
                  .archivesCollection,
            )
            .doc(dossierId)
            .delete();
      }

      await loadAllDossiers();

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Delete dossier error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: DatabaseFailure(
          message:
              'Erreur lors de la suppression: $e',
        ),
      );

      rethrow;
    }
  }

  /// ===============================
  /// SELECT DOSSIER
  /// ===============================
  void selectDossier(
    String dossierId,
  ) {
    state = state.copyWith(
      selectedDossierId:
          dossierId,
    );
  }

  /// ===============================
  /// CLEAR SELECTED DOSSIER
  /// ===============================
  void clearSelectedDossier() {
    state = state.copyWith(
      selectedDossierId: null,
    );
  }

  /// ===============================
  /// CLEAR DOSSIERS
  /// ===============================
  void clearDossiers() {
    state = const DossierState();
  }

  /// ===============================
  /// STREAM DOSSIERS
  /// ===============================
  Stream<List<DossierModel>>
      streamDossiers(
    String collection, {
    String? status,
  }) {
    Query query = _firestore
        .collection(collection)
        .orderBy(
          'createdAt',
          descending: true,
        );

    if (status != null &&
        status != 'all') {
      query = query.where(
        'status',
        isEqualTo: status,
      );
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(
        (doc) {
          final data = doc.data()
              as Map<String, dynamic>;

          return DossierModel.fromJson(
            data,
            doc.id,
          );
        },
      ).toList(),
    );
  }
}