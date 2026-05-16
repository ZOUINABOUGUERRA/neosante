import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failure.dart';
import '../shared/models/user_model.dart';
import '../core/constants/app_constants.dart';

/// Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ============================================================
  // CURRENT USER
  // ============================================================

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return UserModel.fromJson(data, docId: doc.id);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw const AuthFailure(
          message: 'Utilisateur non trouvé dans la base de données.',
        );
      }

      await userDoc.reference.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return UserModel.fromJson(
        userDoc.data()!,
        docId: userCredential.user!.uid,
      );
    } catch (e) {
      throw AuthFailure(message: 'Erreur lors de la connexion: $e');
    }
  }

  // ============================================================
  // GET USER BY ID
  // ============================================================

  Future<UserModel?> getUserById(String uid) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data();
      if (data == null) return null;

      return UserModel.fromJson(data, docId: userDoc.id);
    } catch (e) {
      throw AuthFailure(
        message: 'Erreur lors de la récupération de l\'utilisateur: $e',
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AuthFailure(
        message:
            'Erreur lors de l\'envoi de l\'email de réinitialisation : $e',
      );
    }
  }

  // ============================================================
  // LOGOUT (FIX IMPORTANT)
  // ============================================================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthFailure(message: 'Erreur logout: $e');
    }
  }

  // ============================================================
  // ADMIN USERS
  // ============================================================

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  // ============================================================
  // CREATE USER (FIXED ROLLBACK)
  // ============================================================

  Future<void> createFullUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;

      final newUser = UserModel(
        id: uid,
        firstName: firstName,
        lastName: lastName,
        email: email.trim(),
        role: role,
        profileImage: null,
        createdAt: DateTime.now(),
        isActive: true,
      );

      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(newUser.toJson());
      } catch (e) {
        // rollback if Firestore fails
        await userCredential.user?.delete();
        throw AuthFailure(message: 'Erreur création user: $e');
      }
    } catch (e) {
      throw AuthFailure(
        message: 'Erreur lors de la création de l\'utilisateur: $e',
      );
    }
  }

  // ============================================================
  // SIMPLE CREATE USER
  // ============================================================

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw AuthFailure(message: 'Erreur création utilisateur: $e');
    }
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      throw AuthFailure(message: 'Erreur lors de la mise à jour: $e');
    }
  }

  // ============================================================
  // DISABLE USER
  // ============================================================

  Future<void> disableUser(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ENABLE USER
  // ============================================================

  Future<void> enableUser(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'isActive': true,
      'deletedAt': FieldValue.delete(),
    });
  }

  // ============================================================
  // DELETE USER (soft delete)
  // ============================================================

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      throw AuthFailure(message: 'Erreur lors de la suppression: $e');
    }
  }
}