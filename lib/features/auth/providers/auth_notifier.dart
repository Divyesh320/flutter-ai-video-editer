import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'auth_state.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceImpl();
});

/// Provider for AuthNotifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    // Check for existing authentication on initialization
    checkAuthStatus();
  }

  final AuthService _authService;

  /// Check if user is already authenticated (auto-login)
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    try {
      final isAuthenticated = await _authService.isAuthenticated();

      if (isAuthenticated) {
        final token = await _authService.getStoredToken();
        final user = await _authService.getCurrentUser();

        if (token != null && user != null) {
          state = AuthState.authenticated(user: user, token: token);
        } else {
          // Token exists but user data is missing, try to refresh
          state = const AuthState.unauthenticated();
        }
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error('Failed to check authentication: $e');
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final response = await _authService.login(
        LoginRequest(email: email, password: password),
      );

      state = AuthState.authenticated(
        user: response.user,
        token: response.token,
      );
    } catch (e) {
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Signup with email and password
  Future<void> signup({
    required String email,
    required String password,
    String? name,
  }) async {
    state = const AuthState.loading();

    try {
      final response = await _authService.signup(
        SignupRequest(email: email, password: password, name: name),
      );

      state = AuthState.authenticated(
        user: response.user,
        token: response.token,
      );
    } catch (e) {
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Login with OAuth provider
  Future<void> loginWithOAuth(OAuthProvider provider) async {
    state = const AuthState.loading();

    try {
      final response = await _authService.loginWithOAuth(provider);

      state = AuthState.authenticated(
        user: response.user,
        token: response.token,
      );
    } catch (e) {
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Logout and clear credentials
  Future<void> logout() async {
    state = const AuthState.loading();

    try {
      await _authService.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Even if logout fails, clear local state
      state = const AuthState.unauthenticated();
    }
  }

  /// Refresh the access token
  Future<void> refreshToken() async {
    try {
      final newToken = await _authService.refreshToken();
      if (state.user != null) {
        state = AuthState.authenticated(
          user: state.user!,
          token: newToken,
        );
      }
    } catch (e) {
      // Token refresh failed, user needs to re-authenticate
      state = const AuthState.unauthenticated();
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.hasError) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Invalid credentials')) {
        return 'Invalid email or password';
      }
      if (message.contains('Network')) {
        return 'Network error. Please check your connection.';
      }
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
