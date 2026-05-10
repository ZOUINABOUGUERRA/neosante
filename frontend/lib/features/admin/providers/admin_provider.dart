// frontend/lib/features/admin/providers/admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';
import '../../../services/auth_service.dart';

/// حالة إدارة المستخدمين
class AdminUsersState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error = null,
  });

  AdminUsersState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// مزود إدارة المستخدمين
final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref);
});

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  AdminUsersNotifier(this._ref) : super(const AdminUsersState()) {
    _loadUsers();
  }

  /// تحميل جميع المستخدمين من Firestore
  Future<void> _loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
          .toList();

      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des utilisateurs: $e',
      );
    }
  }

  /// إضافة مستخدم جديد (بواسطة Admin)
  Future<bool> addUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // إنشاء المستخدم في Firebase Auth
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // إنشاء المستند في Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        profileImage: null,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());

      // إعادة تحميل القائمة
      await _loadUsers();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'ajout: $e',
      );
      return false;
    }
  }

  /// تعطيل / تفعيل حساب مستخدم
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'isActive': isActive});

      await _loadUsers();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: $e',
      );
      return false;
    }
  }

  /// حذف مستخدم نهائياً (نادر الاستخدام، بحذر)
  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // حذف من Authentication
      await _authService.deleteUser(userId);
      // حذف من Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();

      await _loadUsers();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la suppression: $e',
      );
      return false;
    }
  }

  /// إعادة تعيين كلمة المرور (إرسال رابط)
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'envoi: $e');
      return false;
    }
  }

  /// تحديث دور المستخدم (admin / sage-femme)
  Future<bool> updateUserRole(String userId, String newRole) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': newRole});

      await _loadUsers();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la modification du rôle: $e',
      );
      return false;
    }
  }

  /// Rafraîchir la liste
  Future<void> refresh() async {
    await _loadUsers();
  }
}