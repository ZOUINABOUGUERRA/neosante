import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/errors/failure.dart';

/// Auth state class
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final Failure? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    Failure? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'AuthState(user: $user, isLoading: $isLoading, isLoggedIn: $isLoggedIn)';
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check auth status on startup
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    final currentUser = _authService.currentFirebaseUser;

    if (currentUser == null) {
      state = const AuthState(isLoggedIn: false, isLoading: false);
      return;
    }

    try {
      final user = await _authService.getUserById(currentUser.uid);

      if (user != null) {
        state = state.copyWith(
          user: user,
          isLoggedIn: true,
          isLoading: false,
        );
      } else {
        state = const AuthState(isLoggedIn: false, isLoading: false);
        await _authService.signOut();
      }
    } catch (e) {
      await _authService.signOut();
      state = const AuthState(isLoggedIn: false, isLoading: false);
    }
  }

  /// Sign in
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.signInWithEmail(email, password);

      state = state.copyWith(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure(message: 'Erreur inattendue: $e'),
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      state = const AuthState(isLoggedIn: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure(message: 'Erreur lors de la déconnexion: $e'),
      );
      rethrow;
    }
  }

  /// Reset password
  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure(message: 'Erreur: $e'),
      );
      rethrow;
    }
  }


  void clearError() {
    state = state.copyWith(error: null);
  }
}