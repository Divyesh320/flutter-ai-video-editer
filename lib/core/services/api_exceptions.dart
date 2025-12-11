/// Base exception for API errors
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Exception for 401 Unauthorized responses
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

/// Exception for 429 Rate Limited responses
class RateLimitException extends ApiException {
  const RateLimitException(super.message, {this.retryAfter})
      : super(statusCode: 429);

  final Duration? retryAfter;
}

/// Exception for 5xx Server errors
class ServerException extends ApiException {
  const ServerException(super.message, {int? statusCode})
      : super(statusCode: statusCode ?? 500);
}

/// Exception for network/connectivity issues
class NetworkException extends ApiException {
  const NetworkException(super.message) : super(statusCode: null);
}

/// Exception for offline mode
class OfflineException extends ApiException {
  const OfflineException(super.message) : super(statusCode: null);
}

/// Exception for quota exceeded
class QuotaExceededException extends ApiException {
  const QuotaExceededException(super.message) : super(statusCode: 402);
}

/// Exception for validation errors
class ValidationException extends ApiException {
  const ValidationException(super.message, {this.errors})
      : super(statusCode: 400);

  final Map<String, List<String>>? errors;
}
