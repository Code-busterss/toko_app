// lib/features/auth/providers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toko_app/core/constants/constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;
  final bool hasPin;
  final bool hasSession;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
    this.hasPin = false,
    this.hasSession = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    bool? hasPin,
    bool? hasSession,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      hasPin: hasPin ?? this.hasPin,
      hasSession: hasSession ?? this.hasSession,
    );
  }
}

// Firebase Auth provider (login/register only).
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// StateNotifier for authentication.
/// Uses Firebase Auth ONLY for authentication; all business data is stored
/// locally in SharedPreferences (no Firestore).
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;

  AuthNotifier(this._auth) : super(const AuthState()) {
    _initAuth();
  }

  void _initAuth() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final hasSession = prefs.getBool(AppConstants.keySession) ?? false;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          hasSession: hasSession,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          hasSession: false,
        );
      }
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keySession, true);
        await prefs.setString(AppConstants.keyUserEmail, email);
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
          user: userCredential.user,
          hasSession: true,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getAuthErrorMessage(e.code),
        status: AuthStatus.error,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
        status: AuthStatus.error,
      );
      return false;
    }
  }

  Future<bool> register({
    required String companyName,
    required String email,
    required String password,
    required String phone,
    String? logo,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(companyName);

        // Save business data to SharedPreferences (NOT Firestore).
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keySession, true);
        await prefs.setString(AppConstants.keyUserEmail, email);
        await prefs.setString(AppConstants.keyCompanyName, companyName);
        await prefs.setString(AppConstants.keyCompanyPhone, phone);
        await prefs.setString(
          AppConstants.keyUserId,
          userCredential.user!.uid,
        );
        if (logo != null) {
          await prefs.setString(AppConstants.keyCompanyLogo, logo);
        }

        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
          user: userCredential.user,
          hasSession: true,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getAuthErrorMessage(e.code),
        status: AuthStatus.error,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
        status: AuthStatus.error,
      );
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      state = state.copyWith(isLoading: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keySession, false);
      await _auth.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Logout failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getAuthErrorMessage(e.code),
        status: AuthStatus.error,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send reset email. Please try again.',
        status: AuthStatus.error,
      );
      return false;
    }
  }

  /// Whether a local session exists (used by SplashScreen).
  Future<bool> hasLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keySession) ?? false;
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(firebaseAuthProvider));
});
