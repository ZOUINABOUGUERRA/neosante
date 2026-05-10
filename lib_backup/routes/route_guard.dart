// frontend/lib/routes/route_guard.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/providers/auth_provider.dart';
import '../shared/models/user_model.dart';

/// Route guard provider for protecting routes based on authentication and roles
final authGuardProvider = Provider<AuthGuard>((ref) => AuthGuard(ref));

/// AuthGuard class for managing route protection
class AuthGuard {
  final Ref ref;  // ✅ تغيير من WidgetRef إلى Ref
  
  AuthGuard(this.ref);

  /// Redirect function for GoRouter
  String? redirect(GoRouterState state) {
    final authState = ref.read(authProvider);
    final isLoggedIn = authState.isLoggedIn;
    final user = authState.user;
    final isLoginRoute = state.matchedLocation == '/login';
    final isForgotPasswordRoute = state.matchedLocation == '/forgot-password';
    
    // Allow public routes without authentication
    final publicRoutes = ['/login', '/forgot-password'];
    if (publicRoutes.contains(state.matchedLocation)) {
      if (isLoggedIn && (isLoginRoute || isForgotPasswordRoute)) {
        return '/dashboard';
      }
      return null;
    }
    
    // Redirect to login if not authenticated
    if (!isLoggedIn) {
      return '/login';
    }
    
    // Role-based route protection
    if (!_hasRequiredRole(state, user)) {
      return '/dashboard';
    }
    
    return null;
  }

  /// Check if user has required role for the route
  bool _hasRequiredRole(GoRouterState state, UserModel? user) {
    final path = state.matchedLocation;
    
    // Admin-only routes
    final adminRoutes = [
      '/backup',
      '/settings/users',
      '/analytics',
    ];
    
    if (adminRoutes.any((route) => path.startsWith(route))) {
      return user?.isAdmin == true;
    }
    
    // Routes accessible by both admin and sage-femme
    return user != null;
  }

  /// Check if user can access a specific dossier
  Future<bool> canAccessDossier(String dossierId, String dossierType) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    
    if (user == null) return false;
    if (user.isAdmin) return true;
    
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection(dossierType).doc(dossierId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data();
      if (data == null) return false;
      
      final createdBy = data['createdBy'];
      final assignedDoctorId = data['assignedDoctorId'];
      
      return createdBy == user.id || assignedDoctorId == user.id;
    } catch (e) {
      return false;
    }
  }

  /// Get current user
  UserModel? getCurrentUser() {
    return ref.read(authProvider).user;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return ref.read(authProvider).isLoggedIn;
  }

  /// Check if user is admin
  bool isAdmin() {
    final user = ref.read(authProvider).user;
    return user?.isAdmin ?? false;
  }

  /// Check if user is sage-femme
  bool isSageFemme() {
    final user = ref.read(authProvider).user;
    return user?.isSageFemme ?? false;
  }
}

/// Provider for checking if user has specific role
final hasRoleProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return user != null;
});

/// Provider for checking if user is admin
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.isAdmin ?? false;
});

/// Provider for checking if user is sage-femme
final isSageFemmeProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.isSageFemme ?? false;
});

/// Provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});