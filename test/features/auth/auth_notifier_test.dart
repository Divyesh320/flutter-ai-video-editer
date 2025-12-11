import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/auth/providers/auth_notifier.dart';
import 'package:multimodal_ai_assistant/features/auth/providers/auth_state.dart';
import 'package:multimodal_ai_assistant/features/auth/services/auth_service.dart';

/// Mock AuthService for testing
class MockAuthService implements AuthService {
  MockAuthService({
    this.storedToken,
    this.storedUser,
    this.shouldFailLogin = false,
    this.shouldFailRefresh = false,
  });

  String? storedToken;
  User? storedUser;
  bool shouldFailLogin;
  bool shouldFailRefresh;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (shouldFailLogin) {
      throw Exception('Invalid credentials');
    }
    final user = User(
      id: 'user-123',
      email: request.email,
      name: 'Test User',
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
    );
    storedToken = 'test_token';
    storedUser = user;
    return AuthResponse(user: user, accessToken: 'test_token');
  }

  @override
  Future<AuthResponse> signup(SignupRequest request) async {
    final user = User(
      id: 'user-123',
      email: request.email,
      name: request.name ?? 'Test User',
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
    );
    storedToken = 'test_token';
    storedUser = user;
    return AuthResponse(user: user, accessToken: 'test_token');
  }

  @override
  Future<AuthResponse> loginWithOAuth(OAuthProvider provider) async {
    final user = User(
      id: 'user-123',
      email: 'oauth@example.com',
      name: 'OAuth User',
      provider: AuthProvider.google,
      createdAt: DateTime.now(),
    );
    storedToken = 'oauth_token';
    storedUser = user;
    return AuthResponse(user: user, accessToken: 'oauth_token');
  }

  @override
  Future<void> logout() async {
    storedToken = null;
    storedUser = null;
  }

  @override
  Future<void> logoutAll() async {
    storedToken = null;
    storedUser = null;
  }

  @override
  Future<String> refreshToken() async {
    if (shouldFailRefresh) {
      throw Exception('Refresh failed');
    }
    storedToken = 'refreshed_token';
    return 'refreshed_token';
  }

  @override
  Future<String?> getStoredToken() async => storedToken;

  @override
  Future<bool> isAuthenticated() async => storedToken != null;

  @override
  Future<User?> getCurrentUser() async => storedUser;

  @override
  Future<List<Map<String, dynamic>>> getSessions() async => [];
}

void main() {
  group('AuthNotifier', () {
    late MockAuthService mockAuthService;
    late AuthNotifier authNotifier;

    setUp(() {
      mockAuthService = MockAuthService();
      authNotifier = AuthNotifier(mockAuthService);
    });

    test('initial state is loading then unauthenticated', () async {
      // Wait for checkAuthStatus to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
    });

    test('login success updates state to authenticated', () async {
      await authNotifier.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user, isNotNull);
      expect(authNotifier.state.user!.email, equals('test@example.com'));
      expect(authNotifier.state.token, equals('test_token'));
    });

    test('login failure updates state to error', () async {
      mockAuthService.shouldFailLogin = true;

      await authNotifier.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(authNotifier.state.status, equals(AuthStatus.error));
      expect(authNotifier.state.errorMessage, isNotNull);
    });

    test('logout clears authentication state', () async {
      // First login
      await authNotifier.login(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(authNotifier.state.isAuthenticated, isTrue);

      // Then logout
      await authNotifier.logout();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.user, isNull);
      expect(authNotifier.state.token, isNull);
    });

    test('OAuth login works for Google', () async {
      await authNotifier.loginWithOAuth(OAuthProvider.google);

      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(authNotifier.state.user!.provider, equals(AuthProvider.google));
    });



    test('clearError resets error state', () async {
      mockAuthService.shouldFailLogin = true;
      await authNotifier.login(email: 'test@example.com', password: 'wrong');

      expect(authNotifier.state.hasError, isTrue);

      authNotifier.clearError();

      expect(authNotifier.state.hasError, isFalse);
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
    });

    /// **Feature: multimodal-ai-assistant, Property 2: JWT Token Auto-Authentication**
    /// **Validates: Requirements 1.5**
    test('property: auto-authenticates when valid token exists (100 iterations)', () async {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        // Create mock with stored credentials
        final token = 'valid_token_${random.nextInt(10000)}';
        final user = User(
          id: 'user-${random.nextInt(10000)}',
          email: 'user${random.nextInt(10000)}@example.com',
          name: 'User ${random.nextInt(100)}',
          provider: AuthProvider.values[random.nextInt(AuthProvider.values.length)],
          createdAt: DateTime.now(),
        );

        final mockService = MockAuthService(
          storedToken: token,
          storedUser: user,
        );

        final notifier = AuthNotifier(mockService);

        // Wait for auto-auth check
        await Future.delayed(const Duration(milliseconds: 50));

        // Should be authenticated with stored credentials
        expect(notifier.state.isAuthenticated, isTrue,
            reason: 'Should auto-authenticate with valid token');
        expect(notifier.state.token, equals(token),
            reason: 'Token should match stored token');
        expect(notifier.state.user?.id, equals(user.id),
            reason: 'User should match stored user');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 2: JWT Token Auto-Authentication**
    /// **Validates: Requirements 1.5**
    test('property: does not authenticate when no token exists (100 iterations)', () async {
      for (var i = 0; i < 100; i++) {
        // Create mock without stored credentials
        final mockService = MockAuthService(
          storedToken: null,
          storedUser: null,
        );

        final notifier = AuthNotifier(mockService);

        // Wait for auto-auth check
        await Future.delayed(const Duration(milliseconds: 50));

        // Should be unauthenticated
        expect(notifier.state.isAuthenticated, isFalse,
            reason: 'Should not authenticate without token');
        expect(notifier.state.status, equals(AuthStatus.unauthenticated),
            reason: 'Status should be unauthenticated');
      }
    });
  });

  group('AuthState', () {
    test('initial state has correct defaults', () {
      const state = AuthState.initial();

      expect(state.status, equals(AuthStatus.initial));
      expect(state.user, isNull);
      expect(state.token, isNull);
      expect(state.errorMessage, isNull);
    });

    test('authenticated state has user and token', () {
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        provider: AuthProvider.email,
        createdAt: DateTime.now(),
      );

      final state = AuthState.authenticated(user: user, token: 'token123');

      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(user));
      expect(state.token, equals('token123'));
    });

    test('error state has error message', () {
      final state = AuthState.error('Something went wrong');

      expect(state.hasError, isTrue);
      expect(state.errorMessage, equals('Something went wrong'));
    });

    test('copyWith creates new state with updated fields', () {
      const original = AuthState.initial();
      final updated = original.copyWith(status: AuthStatus.loading);

      expect(updated.status, equals(AuthStatus.loading));
      expect(original.status, equals(AuthStatus.initial));
    });
  });
}
