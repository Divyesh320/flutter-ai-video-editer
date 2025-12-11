import 'package:dio/dio.dart';

/// Logger for API errors with PII sanitization
class ErrorLogger {
  ErrorLogger({this.enableLogging = true});

  final bool enableLogging;

  /// List of logged errors (for testing)
  final List<LogEntry> logs = [];

  /// Sensitive keys to sanitize from logs
  static const _sensitiveKeys = [
    'authorization',
    'token',
    'jwt',
    'password',
    'secret',
    'api_key',
    'apikey',
    'api-key',
    'x-api-key',
    'access_token',
    'refresh_token',
    'email',
    'phone',
    'address',
    'ssn',
    'credit_card',
  ];

  /// Patterns to sanitize from log content
  static final _sensitivePatterns = [
    RegExp(r'Bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'), // JWT
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), // Email
    RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'), // Phone
    RegExp(r'\b\d{3}[-]?\d{2}[-]?\d{4}\b'), // SSN
    RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // Credit card
  ];

  /// Log an API error with sanitization
  void logApiError(DioException error) {
    if (!enableLogging) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      path: error.requestOptions.path,
      method: error.requestOptions.method,
      statusCode: error.response?.statusCode,
      errorMessage: _sanitizeString(error.message ?? 'Unknown error'),
      errorType: error.type.toString(),
    );

    logs.add(entry);
    _printLog(entry);
  }

  /// Log a general error
  void log(String message, [dynamic error]) {
    if (!enableLogging) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      path: null,
      method: null,
      statusCode: null,
      errorMessage: _sanitizeString(message),
      errorType: error?.runtimeType.toString(),
    );

    logs.add(entry);
    _printLog(entry);
  }

  /// Sanitize a string by removing sensitive data
  String _sanitizeString(String input) {
    var result = input;
    for (final pattern in _sensitivePatterns) {
      result = result.replaceAll(pattern, '[REDACTED]');
    }
    return result;
  }

  /// Sanitize headers by removing sensitive keys
  Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    for (final entry in headers.entries) {
      final keyLower = entry.key.toLowerCase().replaceAll('-', '_');
      if (_sensitiveKeys.any((k) => keyLower.contains(k.replaceAll('-', '_')))) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Sanitize request/response data
  Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      final keyLower = entry.key.toLowerCase();
      if (_sensitiveKeys.any((k) => keyLower.contains(k))) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (entry.value is String) {
        sanitized[entry.key] = _sanitizeString(entry.value as String);
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeData(entry.value as Map<String, dynamic>);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  void _printLog(LogEntry entry) {
    // In production, this would send to a logging service
    // For now, just print to console in debug mode
    assert(() {
      print('[ERROR] ${entry.timestamp.toIso8601String()} '
          '${entry.method ?? ''} ${entry.path ?? ''} '
          '${entry.statusCode ?? ''} - ${entry.errorMessage}');
      return true;
    }());
  }

  /// Clear all logs (for testing)
  void clear() {
    logs.clear();
  }
}

/// A single log entry
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.path,
    required this.method,
    required this.statusCode,
    required this.errorMessage,
    this.errorType,
  });

  final DateTime timestamp;
  final String? path;
  final String? method;
  final int? statusCode;
  final String errorMessage;
  final String? errorType;

  @override
  String toString() =>
      'LogEntry(path: $path, method: $method, status: $statusCode, message: $errorMessage)';
}
