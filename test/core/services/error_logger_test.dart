import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/services/services.dart';

void main() {
  group('ErrorLogger', () {
    late ErrorLogger logger;

    setUp(() {
      logger = ErrorLogger(enableLogging: true);
    });

    test('logs API errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test', method: 'GET'),
        message: 'Test error',
        type: DioExceptionType.badResponse,
      );

      logger.logApiError(error);

      expect(logger.logs.length, equals(1));
      expect(logger.logs.first.path, equals('/api/test'));
      expect(logger.logs.first.method, equals('GET'));
    });

    test('sanitizes JWT tokens from error messages', () {
      final jwt =
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        message: 'Auth failed with token: $jwt',
        type: DioExceptionType.badResponse,
      );

      logger.logApiError(error);

      expect(logger.logs.first.errorMessage, contains('[REDACTED]'));
      expect(logger.logs.first.errorMessage, isNot(contains('eyJ')));
    });

    test('sanitizes email addresses from error messages', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        message: 'User not found: user@example.com',
        type: DioExceptionType.badResponse,
      );

      logger.logApiError(error);

      expect(logger.logs.first.errorMessage, contains('[REDACTED]'));
      expect(logger.logs.first.errorMessage, isNot(contains('@example.com')));
    });

    test('sanitizes phone numbers from error messages', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        message: 'Contact: 555-123-4567',
        type: DioExceptionType.badResponse,
      );

      logger.logApiError(error);

      expect(logger.logs.first.errorMessage, contains('[REDACTED]'));
      expect(logger.logs.first.errorMessage, isNot(contains('555-123-4567')));
    });

    test('sanitizes sensitive headers', () {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer secret_token',
        'X-Api-Key': 'my_api_key',
        'X-Custom': 'safe_value',
      };

      final sanitized = logger.sanitizeHeaders(headers);

      expect(sanitized['Content-Type'], equals('application/json'));
      expect(sanitized['Authorization'], equals('[REDACTED]'));
      expect(sanitized['X-Api-Key'], equals('[REDACTED]'));
      expect(sanitized['X-Custom'], equals('safe_value'));
    });

    test('sanitizes sensitive data fields', () {
      final data = {
        'username': 'john',
        'password': 'secret123',
        'email': 'john@example.com',
        'message': 'Hello world',
      };

      final sanitized = logger.sanitizeData(data);

      expect(sanitized['username'], equals('john'));
      expect(sanitized['password'], equals('[REDACTED]'));
      expect(sanitized['email'], equals('[REDACTED]'));
      expect(sanitized['message'], equals('Hello world'));
    });

    test('clears logs', () {
      logger.log('Test message');
      expect(logger.logs.length, equals(1));

      logger.clear();
      expect(logger.logs, isEmpty);
    });
  });


  group('Property Tests', () {
    /// **Property 30: Error Logging Sanitization**
    /// For any logged API error, the log entry SHALL NOT contain JWT tokens,
    /// passwords, or user PII; only request path, status code, and sanitized
    /// error message SHALL be logged.
    group('Property 30: Error Logging Sanitization', () {
      test('no JWT tokens in logs (100 iterations)', () {
        final random = Random(42);
        final logger = ErrorLogger(enableLogging: true);

        for (var i = 0; i < 100; i++) {
          final jwt = _generateRandomJwt(random);
          final message = 'Error with token: Bearer $jwt';

          final error = DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            message: message,
            type: DioExceptionType.badResponse,
          );

          logger.logApiError(error);
          final logEntry = logger.logs.last;

          expect(logEntry.errorMessage, isNot(contains(jwt)),
              reason: 'JWT should be redacted from logs');
          expect(logEntry.errorMessage, contains('[REDACTED]'),
              reason: 'Sensitive data should be replaced with [REDACTED]');
        }
      });

      test('no email addresses in logs (100 iterations)', () {
        final random = Random(42);
        final logger = ErrorLogger(enableLogging: true);

        for (var i = 0; i < 100; i++) {
          final email = _generateRandomEmail(random);
          final message = 'User not found: $email';

          final error = DioException(
            requestOptions: RequestOptions(path: '/api/users'),
            message: message,
            type: DioExceptionType.badResponse,
          );

          logger.logApiError(error);
          final logEntry = logger.logs.last;

          expect(logEntry.errorMessage, isNot(contains(email)),
              reason: 'Email should be redacted from logs');
        }
      });


      test('no phone numbers in logs (100 iterations)', () {
        final random = Random(42);
        final logger = ErrorLogger(enableLogging: true);

        for (var i = 0; i < 100; i++) {
          final phone = _generateRandomPhone(random);
          final message = 'Contact phone: $phone';

          final error = DioException(
            requestOptions: RequestOptions(path: '/api/contact'),
            message: message,
            type: DioExceptionType.badResponse,
          );

          logger.logApiError(error);
          final logEntry = logger.logs.last;

          expect(logEntry.errorMessage, isNot(contains(phone)),
              reason: 'Phone number should be redacted from logs');
        }
      });

      test('no passwords in sanitized data (100 iterations)', () {
        final random = Random(42);
        final logger = ErrorLogger(enableLogging: true);

        for (var i = 0; i < 100; i++) {
          final password = _generateRandomPassword(random);
          final data = {
            'username': 'user_$i',
            'password': password,
            'token': _generateRandomJwt(random),
            'api_key': 'key_${random.nextInt(10000)}',
          };

          final sanitized = logger.sanitizeData(data);

          expect(sanitized['password'], equals('[REDACTED]'),
              reason: 'Password should be redacted');
          expect(sanitized['token'], equals('[REDACTED]'),
              reason: 'Token should be redacted');
          expect(sanitized['api_key'], equals('[REDACTED]'),
              reason: 'API key should be redacted');
          expect(sanitized['username'], equals('user_$i'),
              reason: 'Non-sensitive data should be preserved');
        }
      });
    });
  });
}


String _generateRandomJwt(Random random) {
  final header = _randomBase64(random, 20);
  final payload = _randomBase64(random, 50);
  final signature = _randomBase64(random, 30);
  return '$header.$payload.$signature';
}

String _randomBase64(Random random, int length) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}

String _generateRandomEmail(Random random) {
  final user = _randomString(random, 8);
  final domain = _randomString(random, 6);
  final tld = ['com', 'org', 'net', 'io'][random.nextInt(4)];
  return '$user@$domain.$tld';
}

String _generateRandomPhone(Random random) {
  final area = random.nextInt(900) + 100;
  final prefix = random.nextInt(900) + 100;
  final line = random.nextInt(9000) + 1000;
  return '$area-$prefix-$line';
}

String _generateRandomPassword(Random random) {
  return _randomString(random, 12 + random.nextInt(8));
}

String _randomString(Random random, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}
