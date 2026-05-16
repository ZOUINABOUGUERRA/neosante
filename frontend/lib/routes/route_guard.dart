import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../shared/models/user_model.dart';

final authGuardProvider = Provider<AuthGuard>(
  (ref) => AuthGuard(ref),
);

class AuthGuard {
  final Ref ref;

  AuthGuard(this.ref);

  /// =========================
  /// ROUTE REDIRECT LOGIC
  /// =========================
  String? redirect(GoRouterState state) {
    final authState = ref.read(authProvider);

    final user = authState.user;
    final isLoggedIn = authState.isLoggedIn;

    final location = state.matchedLocation;

    const publicRoutes = [
      '/login',
      '/forgot-password',
    ];

    final isPublic = publicRoutes.contains(location);

    // =========================
    // NOT LOGGED IN
    // =========================
    if (!isLoggedIn || user == null) {
      return isPublic ? null : '/login';
    }

    // =========================
    // LOGGED IN + PUBLIC ROUTE
    // =========================
    if (isPublic) {
      return user.role == AppConstants.roleAdmin
          ? '/admin/dashboard'
          : '/dashboard';
    }

    // =========================
    // ADMIN ROUTE PROTECTION
    // =========================
    final isAdminRoute =
        location == '/admin' ||
        location.startsWith('/admin/');

    if (isAdminRoute &&
        user.role != AppConstants.roleAdmin) {
      return '/dashboard';
    }

    // =========================
    // PREVENT ADMIN USING USER DASHBOARD
    // =========================
    if (location == '/dashboard' &&
        user.role == AppConstants.roleAdmin) {
      return '/admin/dashboard';
    }

    return null;
  }

  /// =========================
  /// DOSSIER ACCESS CONTROL
  /// =========================
  Future<bool> canAccessDossier(
    String id,
    String type,
  ) async {
    final user = ref.read(authProvider).user;

    if (user == null) return false;

    // ✅ Admin full access
    if (user.role == AppConstants.roleAdmin) {
      return true;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(type)
          .doc(id)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();

      if (data == null) return false;

      final createdBy = data['createdBy'];
      final assignedDoctorId =
          data['assignedDoctorId'];

      return createdBy == user.id ||
          assignedDoctorId == user.id;

    } catch (e) {
      debugPrint(
        '❌ Dossier access error: $e',
      );
      return false;
    }
  }

  /// =========================
  /// LOGOUT
  /// =========================
  Future<void> logout(
    BuildContext context,
  ) async {
    try {
      await ref
          .read(authProvider.notifier)
          .signOut();

      if (context.mounted) {
        context.go('/login');
      }

    } catch (e) {
      debugPrint(
        '❌ Logout error: $e',
      );
    }
  }

  /// =========================
  /// HELPERS
  /// =========================

  UserModel? getCurrentUser() {
    return ref.read(authProvider).user;
  }

  bool isAuthenticated() {
    return ref.read(authProvider).isLoggedIn;
  }

  bool isAdmin() {
    final user = ref.read(authProvider).user;

    return user?.role ==
        AppConstants.roleAdmin;
  }

  bool isSageFemme() {
    final user = ref.read(authProvider).user;

    return user?.role ==
        AppConstants.roleSageFemme;
  }
}