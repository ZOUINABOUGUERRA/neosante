import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failure.dart';
import '../shared/models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ==========================
/// PROVIDER (خارج الكلاس مهم)
/// ==========================
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// ==========================
  /// 🔥 FIX IMPORTANT
  /// نجيب UserModel من Firestore
  /// ==========================
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromJson(doc.data()!, docId: doc.id);
  }

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
            message: 'Utilisateur non trouvé dans la base de données.');
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

  Future<UserModel?> getUserById(String uid) async {
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!userDoc.exists) return null;
    return UserModel.fromJson(userDoc.data()!, docId: userDoc.id);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AuthFailure(
          message:
              'Erreur lors de l\'envoi de l\'email de réinitialisation : $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
