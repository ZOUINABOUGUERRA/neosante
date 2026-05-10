import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failure.dart';
import '../shared/models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// Récupérer le modèle utilisateur courant depuis Firestore
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

  /// Connexion avec email / mot de passe
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

  /// Récupérer un utilisateur par son UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!userDoc.exists) return null;

      return UserModel.fromJson(userDoc.data()!, docId: userDoc.id);
    } catch (e) {
      throw AuthFailure(
          message: 'Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  /// Envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AuthFailure(
          message:
              'Erreur lors de l\'envoi de l\'email de réinitialisation : $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================================================
  // 🔥 NOUVELLES FONCTIONS POUR ADMIN (GESTION DES UTILISATEURS)
  // ============================================================

  /// Récupérer tous les utilisateurs (admin only)
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  /// Créer un utilisateur complet (admin only)
  /// Cette méthode crée l'utilisateur dans Firebase Auth ET dans Firestore
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

      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email.trim(),
        role: role,
        profileImage: null,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());
    } catch (e) {
      throw AuthFailure(message: 'Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /// Mettre à jour un utilisateur (admin only)
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

  /// Désactiver un utilisateur (admin only)
  /// Note: la suppression complète nécessiterait une Cloud Function
  Future<void> disableUser(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Réactiver un utilisateur (admin only)
  Future<void> enableUser(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'isActive': true,
      'deletedAt': FieldValue.delete(),
    });
  }
}