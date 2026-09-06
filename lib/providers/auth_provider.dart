import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'biometric_provider.dart';
import 'pin_provider.dart';

/// Provider for accessing the AuthService instance across the app.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// StreamProvider exposing real-time authentication status (logged in / logged out).
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// State class holding the UI state during authentication operations.
class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Controller managing authentication state and actions for the UI.
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref? _ref;

  AuthController(this._authService, [this._ref]) : super(const AuthState());

  /// Clears any currently displayed error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Signs in with email and password. Returns true on success.
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Registers a new user account. Returns true on success.
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Signs in using Google. Returns true if sign-in succeeded, false if failed or cancelled.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return user != null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sends a Firebase email verification link to the current user. Returns true on success.
  Future<bool> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.sendEmailVerification();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Reloads current user's profile and returns true if email is verified.
  /// If verified, invalidates authStateProvider to refresh application routing.
  Future<bool> checkEmailVerified() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final isVerified = await _authService.checkEmailVerified();
      state = state.copyWith(isLoading: false);
      if (isVerified && _ref != null) {
        _ref.invalidate(authStateProvider);
      }
      return isVerified;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_ref != null) {
        _ref.read(biometricUnlockedProvider.notifier).lock();
        _ref.read(isPinUnlockedProvider.notifier).lock();
      }
      await _authService.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

/// Provider for accessing the AuthController in screens.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService, ref);
});
