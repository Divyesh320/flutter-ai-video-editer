import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/config.dart';
import 'api_exceptions.dart';
import 'error_logger.dart';
import 'offline_queue.dart';

/// Configuration for API service
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  /// Create ApiConfig from environment variables
  factory ApiConfig.fromEnv() {
    final env = EnvConfig.instance;
    final timeout = Duration(seconds: env.apiTimeoutSeconds);
    return ApiConfig(
      baseUrl: env.apiBaseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      maxRetries: env.apiMaxRetries,
    );
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int maxRetries;
}

/// Base API service with Dio, JWT interceptor, and error handling
class ApiService {
  ApiService({
    required ApiConfig config,
    FlutterSecureStorage? secureStorage,
    Dio? dio,
    ErrorLogger? errorLogger,
    OfflineQueueManager? offlineQueue,
  })  : _config = config,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _errorLogger = errorLogger ?? ErrorLogger(),
        _offlineQueue = offlineQueue ?? OfflineQueueManager() {
    _dio = dio ?? Dio();
    _setupDio();
  }

  final ApiConfig _config;
  final FlutterSecureStorage _secureStorage;
  final ErrorLogger _errorLogger;
  final OfflineQueueManager _offlineQueue;
  late final Dio _dio;

  static const _tokenKey = 'jwt_token';

  /// Callback for handling 401 responses (logout)
  void Function()? onUnauthorized;

  /// Stream controller for connectivity status
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      sendTimeout: _config.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add JWT interceptor
    _dio.interceptors.add(_AuthInterceptor(
      secureStorage: _secureStorage,
      tokenKey: _tokenKey,
    ));

    // Add error interceptor
    _dio.interceptors.add(_ErrorInterceptor(
      onUnauthorized: () => onUnauthorized?.call(),
      errorLogger: _errorLogger,
    ));

    // Add retry interceptor
    _dio.interceptors.add(_RetryInterceptor(
      dio: _dio,
      maxRetries: _config.maxRetries,
    ));
  }

  /// Get the stored JWT token
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  /// Current token (cached for sync access)
  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Store JWT token
  Future<void> setToken(String token) async {
    _currentToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Clear stored token
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// Update connectivity status
  void setConnectivity(bool isOnline) {
    _isOnline = isOnline;
    _connectivityController.add(isOnline);
    if (isOnline) {
      _syncOfflineQueue();
    }
  }

  /// Sync offline queue when connectivity is restored
  Future<void> _syncOfflineQueue() async {
    final pendingRequests = await _offlineQueue.getPendingRequests();
    for (final request in pendingRequests) {
      try {
        await _executeRequest(request);
        await _offlineQueue.removeRequest(request.id);
      } catch (e) {
        // Keep in queue if still failing
        _errorLogger.log('Failed to sync offline request: ${request.id}', e);
      }
    }
  }

  Future<Response<T>> _executeRequest<T>(QueuedRequest request) async {
    switch (request.method) {
      case 'GET':
        return _dio.get<T>(request.path, queryParameters: request.queryParams);
      case 'POST':
        return _dio.post<T>(request.path, data: request.data);
      case 'PUT':
        return _dio.put<T>(request.path, data: request.data);
      case 'DELETE':
        return _dio.delete<T>(request.path);
      default:
        throw ApiException('Unsupported method: ${request.method}');
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  /// POST request with offline queue support
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = false,
  }) async {
    if (!_isOnline && queueIfOffline) {
      await _offlineQueue.addRequest(QueuedRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        method: 'POST',
        path: path,
        data: data,
        queryParams: queryParameters,
        createdAt: DateTime.now(),
      ));
      throw OfflineException('Request queued for later');
    }
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Upload file with progress tracking
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?additionalFields,
    });

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onProgress,
    );
  }

  /// Get offline queue manager for testing
  OfflineQueueManager get offlineQueue => _offlineQueue;

  /// Dispose resources
  void dispose() {
    _connectivityController.close();
  }
}

/// Interceptor for adding JWT token to requests
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.secureStorage,
    required this.tokenKey,
  });

  final FlutterSecureStorage secureStorage;
  final String tokenKey;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await secureStorage.read(key: tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Interceptor for handling errors
class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor({
    required this.onUnauthorized,
    required this.errorLogger,
  });

  final void Function() onUnauthorized;
  final ErrorLogger errorLogger;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error with sanitization
    errorLogger.logApiError(err);

    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      // Clear credentials and redirect to login
      onUnauthorized();
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: UnauthorizedException('Session expired. Please log in again.'),
        type: DioExceptionType.badResponse,
        response: err.response,
      ));
      return;
    }

    if (statusCode == 429) {
      // Rate limited - will be handled by retry interceptor
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: RateLimitException('Too many requests. Please wait.'),
        type: DioExceptionType.badResponse,
        response: err.response,
      ));
      return;
    }

    if (statusCode != null && statusCode >= 500) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: ServerException('Server error. Please try again later.'),
        type: DioExceptionType.badResponse,
        response: err.response,
      ));
      return;
    }

    handler.next(err);
  }
}

/// Interceptor for retry with exponential backoff
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor({
    required this.dio,
    required this.maxRetries,
  });

  final Dio dio;
  final int maxRetries;

  static const _retryableStatuses = [408, 429, 500, 502, 503, 504];
  static const _baseDelay = Duration(seconds: 1);
  static const _maxDelay = Duration(seconds: 32);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    
    if (statusCode == null || !_retryableStatuses.contains(statusCode)) {
      handler.next(err);
      return;
    }

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    // Calculate backoff delay
    final delay = _calculateBackoff(retryCount, statusCode);
    await Future.delayed(delay);

    // Retry the request
    try {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  Duration _calculateBackoff(int retryCount, int statusCode) {
    // For 429, use Retry-After header if available
    final baseMs = _baseDelay.inMilliseconds;
    final delayMs = baseMs * (1 << retryCount); // 1s, 2s, 4s, 8s, 16s, 32s
    return Duration(milliseconds: delayMs.clamp(baseMs, _maxDelay.inMilliseconds));
  }
}
