import 'package:equatable/equatable.dart';

import '../../../core/models/models.dart';

/// Authentication state types
enum AuthStatus {
  /// Initial state, checking for stored credentials
  initial,

  /// Currently checking authentication status
  loading,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Authentication error occurred
  error,
}

/// Authentication state containing status and user data
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  /// Current authentication status
  final AuthStatus status;

  /// Authenticated user (null if not authenticated)
  final User? user;

  /// JWT token (null if not authenticated)
  final String? token;

  /// Error message (null if no error)
  final String? errorMessage;

  /// Initial state
  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        token = null,
        errorMessage = null;

  /// Loading state
  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        token = null,
        errorMessage = null;

  /// Authenticated state
  AuthState.authenticated({
    required User this.user,
    required String this.token,
  })  : status = AuthStatus.authenticated,
        errorMessage = null;

  /// Unauthenticated state
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        token = null,
        errorMessage = null;

  /// Error state
  AuthState.error(String this.errorMessage)
      : status = AuthStatus.error,
        user = null,
        token = null;

  /// Whether user is currently authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Whether authentication is in progress
  bool get isLoading => status == AuthStatus.loading;

  /// Whether there's an error
  bool get hasError => status == AuthStatus.error;

  /// Create copy with updated fields
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, token, errorMessage];
}
