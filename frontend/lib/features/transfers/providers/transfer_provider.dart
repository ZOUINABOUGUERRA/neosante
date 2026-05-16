import 'dart:async';
//import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/transfer_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

/// Transfer state class
class TransferState {
  final List<TransferModel> pendingTransfers;
  final List<TransferModel> approvedTransfers;
  final List<TransferModel> rejectedTransfers;
  final List<TransferModel> completedTransfers;
  final bool isLoading;
  final String? error;

  const TransferState({
    this.pendingTransfers = const [],
    this.approvedTransfers = const [],
    this.rejectedTransfers = const [],
    this.completedTransfers = const [],
    this.isLoading = false,
    this.error,
  });

  TransferState copyWith({
    List<TransferModel>? pendingTransfers,
    List<TransferModel>? approvedTransfers,
    List<TransferModel>? rejectedTransfers,
    List<TransferModel>? completedTransfers,
    bool? isLoading,
    String? error,
  }) {
    return TransferState(
      pendingTransfers: pendingTransfers ?? this.pendingTransfers,
      approvedTransfers: approvedTransfers ?? this.approvedTransfers,
      rejectedTransfers: rejectedTransfers ?? this.rejectedTransfers,
      completedTransfers: completedTransfers ?? this.completedTransfers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  int get totalPending => pendingTransfers.length;
  int get totalApproved => approvedTransfers.length;
  int get totalRejected => rejectedTransfers.length;
  int get totalCompleted => completedTransfers.length;
  int get total =>
      pendingTransfers.length +
      approvedTransfers.length +
      rejectedTransfers.length +
      completedTransfers.length;
}

/// Transfer provider
final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>(
  (ref) {
    return TransferNotifier();
  },
);

/// Transfer notifier for managing transfer requests
class TransferNotifier extends StateNotifier<TransferState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _approvedSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _rejectedSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _completedSubscription;

  TransferNotifier() : super(const TransferState()) {
    _loadTransfers();
  }

  void _loadTransfers() {
    final currentUser = _authService.currentFirebaseUser;
    if (currentUser == null) return;

    // Pending transfers
    _pendingSubscription = _firestore
        .collection(AppConstants.transfersCollection)
        .where('requestedTo', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: AppConstants.transferStatusPending)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final transfers = snapshot.docs
                .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
                .toList();

            state = state.copyWith(pendingTransfers: transfers, error: null);
          },
          onError: (e) {
            state = state.copyWith(error: e.toString());
          },
        );

    // Approved transfers
    _approvedSubscription = _firestore
        .collection(AppConstants.transfersCollection)
        .where('status', isEqualTo: AppConstants.transferStatusApproved)
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final transfers = snapshot.docs
                .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
                .toList();

            state = state.copyWith(approvedTransfers: transfers, error: null);
          },
          onError: (e) {
            state = state.copyWith(error: e.toString());
          },
        );

    // Rejected transfers
    _rejectedSubscription = _firestore
        .collection(AppConstants.transfersCollection)
        .where('status', isEqualTo: AppConstants.transferStatusRejected)
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final transfers = snapshot.docs
                .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
                .toList();

            state = state.copyWith(rejectedTransfers: transfers, error: null);
          },
          onError: (e) {
            state = state.copyWith(error: e.toString());
          },
        );

    // Completed transfers
    _completedSubscription = _firestore
        .collection(AppConstants.transfersCollection)
        .where('status', isEqualTo: AppConstants.transferStatusCompleted)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final transfers = snapshot.docs
                .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
                .toList();

            state = state.copyWith(completedTransfers: transfers, error: null);
          },
          onError: (e) {
            state = state.copyWith(error: e.toString());
          },
        );
  }

  /// Approve a transfer request
  Future<void> approveTransfer(String transferId, {String? notes}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transferRef = _firestore
          .collection(AppConstants.transfersCollection)
          .doc(transferId);
      final transferDoc = await transferRef.get();

      if (!transferDoc.exists) {
        throw Exception('Transfert non trouvé');
      }

      final transfer = TransferModel.fromJson(
        transferDoc.data()!,
        transferDoc.id,
      );

      // Update transfer status
      await transferRef.update({
        'status': AppConstants.transferStatusApproved,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': _authService.currentFirebaseUser?.uid,
        'approvalNotes': notes,
      });

      // Update dossier with assigned doctor
      final dossierRef = _firestore
          .collection(AppConstants.dossiersPrematuresCollection)
          .doc(transfer.dossierId);
      await dossierRef
          .update({
            'assignedDoctorId': transfer.requestedTo,
            'transferStatus': AppConstants.transferStatusApproved,
            'transferredAt': FieldValue.serverTimestamp(),
          })
          .catchError((_) async {
            // Try full-term collection if not found
            await _firestore
                .collection(AppConstants.dossiersATermeCollection)
                .doc(transfer.dossierId)
                .update({
                  'assignedDoctorId': transfer.requestedTo,
                  'transferStatus': AppConstants.transferStatusApproved,
                  'transferredAt': FieldValue.serverTimestamp(),
                });
          });

      // Send notification to requester (sage-femme)
      await NotificationService.notifyTransferApproved(
        transfer.requestedBy,
        transfer.dossierNumber,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Reject a transfer request
  Future<void> rejectTransfer(String transferId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transferRef = _firestore
          .collection(AppConstants.transfersCollection)
          .doc(transferId);
      final transferDoc = await transferRef.get();

      if (!transferDoc.exists) {
        throw Exception('Transfert non trouvé');
      }

      final transfer = TransferModel.fromJson(
        transferDoc.data()!,
        transferDoc.id,
      );

      await transferRef.update({
        'status': AppConstants.transferStatusRejected,
        'rejectionReason': reason,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': _authService.currentFirebaseUser?.uid,
      });

      await NotificationService.sendPushNotification(
        userId: transfer.requestedBy,
        title: '❌ Transfert refusé',
        body:
            'Le transfert du dossier ${transfer.dossierNumber} a été refusé.\nRaison: $reason',
        type: 'transfer_rejected',
        data: {'transferId': transferId, 'dossierId': transfer.dossierId},
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Mark transfer as completed
  Future<void> completeTransfer(String transferId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestore
          .collection(AppConstants.transfersCollection)
          .doc(transferId)
          .update({
            'status': AppConstants.transferStatusCompleted,
            'completedAt': FieldValue.serverTimestamp(),
          });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Get transfer by ID
  Future<TransferModel?> getTransferById(String transferId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.transfersCollection)
          .doc(transferId)
          .get();
      if (!doc.exists) return null;
      return TransferModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Get transfers for a specific dossier
  Future<List<TransferModel>> getTransfersForDossier(String dossierId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.transfersCollection)
          .where('dossierId', isEqualTo: dossierId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _approvedSubscription?.cancel();
    _rejectedSubscription?.cancel();
    _completedSubscription?.cancel();
    super.dispose();
  }
}

/// Pending transfers count provider (for badge)
final pendingTransfersCountProvider = StreamProvider<int>((ref) {
  final authService = AuthService();
  final currentUser = authService.currentFirebaseUser;

  if (currentUser == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection(AppConstants.transfersCollection)
      .where('requestedTo', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: AppConstants.transferStatusPending)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Transfers sent by current user provider
final myTransferRequestsProvider = StreamProvider<List<TransferModel>>((ref) {
  final authService = AuthService();
  final currentUser = authService.currentFirebaseUser;

  if (currentUser == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(AppConstants.transfersCollection)
      .where('requestedBy', isEqualTo: currentUser.uid)
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TransferModel.fromJson(doc.data(), doc.id))
            .toList(),
      );
});
