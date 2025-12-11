import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/config.dart';
import '../../../core/models/models.dart';

/// Authentication response from backend
class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  final User user;
  final String accessToken;
  final String? refreshToken;
}

/// Login request for email authentication
class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

/// Signup request for email registration
class SignupRequest {
  const SignupRequest({
    required this.email,
    required this.password,
    this.name,
  });

  final String email;
  final String password;
  final String? name;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (name != null) 'name': name,
  };
}

/// OAuth provider types
enum OAuthProvider { google }

/// Abstract interface for authentication operations
abstract class AuthService {
  /// Login with email and password
  Future<AuthResponse> login(LoginRequest request);

  /// Register new user with email
  Future<AuthResponse> signup(SignupRequest request);

  /// Login with OAuth provider (Google)
  Future<AuthResponse> loginWithOAuth(OAuthProvider provider);

  /// Logout and clear credentials
  Future<void> logout();

  /// Logout from all devices
  Future<void> logoutAll();

  /// Refresh the access token
  Future<String> refreshToken();

  /// Get stored JWT token
  Future<String?> getStoredToken();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Get current user from API
  Future<User?> getCurrentUser();

  /// Get active sessions
  Future<List<Map<String, dynamic>>> getSessions();
}

/// Implementation of AuthService using backend API
class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    FlutterSecureStorage? secureStorage,
    Dio? dio,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _dio = dio ?? Dio() {
    _setupDio();
  }

  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: EnvConfig.instance.apiBaseUrl,
      connectTimeout: Duration(seconds: EnvConfig.instance.apiTimeoutSeconds),
      receiveTimeout: Duration(seconds: EnvConfig.instance.apiTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto refresh token on 401
        if (error.response?.statusCode == 401) {
          try {
            final newToken = await refreshToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // Refresh failed, clear credentials
            await _clearCredentials();
          }
        }
        handler.next(error);
      },
    ));
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        final authResponse = AuthResponse.fromJson(response.data['data']);
        await _storeCredentials(authResponse);
        return authResponse;
      }

      throw AuthException(response.data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        final authResponse = AuthResponse.fromJson(response.data['data']);
        await _storeCredentials(authResponse);
        return authResponse;
      }

      throw AuthException(response.data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> loginWithOAuth(OAuthProvider provider) async {
    // OAuth flow - get token from provider first, then send to backend
    // This would typically use google_sign_in package
    
    // For now, throw unimplemented
    throw UnimplementedError(
      'OAuth login requires platform-specific implementation. '
      'Use google_sign_in package.',
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore errors, clear local credentials anyway
    }
    await _clearCredentials();
  }

  @override
  Future<void> logoutAll() async {
    try {
      await _dio.post('/auth/logout-all');
    } catch (e) {
      // Ignore errors
    }
    await _clearCredentials();
  }

  @override
  Future<String> refreshToken() async {
    final storedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (storedRefreshToken == null) {
      throw AuthException('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': storedRefreshToken},
      );

      if (response.data['success'] == true) {
        final newAccessToken = response.data['data']['accessToken'] as String;
        final newRefreshToken = response.data['data']['refreshToken'] as String?;
        
        await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
        }
        
        return newAccessToken;
      }

      throw AuthException('Token refresh failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String?> getStoredToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    if (token == null) return false;

    // Verify token with backend
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      if (response.data['success'] == true) {
        final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
        // Cache user data
        await _secureStorage.write(
          key: _userKey,
          value: jsonEncode(user.toJson()),
        );
        return user;
      }
      return null;
    } on DioException {
      // Try to return cached user
      final cachedUser = await _secureStorage.read(key: _userKey);
      if (cachedUser != null) {
        return User.fromJson(jsonDecode(cachedUser) as Map<String, dynamic>);
      }
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await _dio.get('/auth/sessions');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _storeCredentials(AuthResponse authResponse) async {
    await _secureStorage.write(
      key: _accessTokenKey,
      value: authResponse.accessToken,
    );
    if (authResponse.refreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: authResponse.refreshToken,
      );
    }
    await _secureStorage.write(
      key: _userKey,
      value: jsonEncode(authResponse.user.toJson()),
    );
  }

  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  AuthException _handleDioError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Request failed';
      final statusCode = e.response?.statusCode;
      
      if (statusCode == 401) {
        return AuthException('Invalid credentials');
      } else if (statusCode == 429) {
        return AuthException('Too many attempts. Please try again later.');
      } else if (statusCode == 400) {
        return AuthException(message);
      }
      return AuthException(message);
    }
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AuthException('Connection timeout. Please check your internet.');
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return AuthException('Cannot connect to server. Please check your internet.');
    }
    
    return AuthException('An error occurred. Please try again.');
  }
}

/// Exception thrown for authentication errors
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
