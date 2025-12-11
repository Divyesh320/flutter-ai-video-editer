import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/user.dart';

void main() {
  group('User Model', () {
    group('JSON Serialization', () {
      test('fromJson creates valid User', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'name': 'Test User',
          'avatar_url': 'https://example.com/avatar.png',
          'provider': 'email',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final user = User.fromJson(json);

        expect(user.id, equals('user-123'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.avatarUrl, equals('https://example.com/avatar.png'));
        expect(user.provider, equals(AuthProvider.email));
        expect(user.createdAt, equals(DateTime.utc(2024, 1, 1)));
      });

      test('toJson produces valid JSON', () {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          avatarUrl: 'https://example.com/avatar.png',
          provider: AuthProvider.google,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final json = user.toJson();

        expect(json['id'], equals('user-123'));
        expect(json['email'], equals('test@example.com'));
        expect(json['name'], equals('Test User'));
        expect(json['avatar_url'], equals('https://example.com/avatar.png'));
        expect(json['provider'], equals('google'));
        expect(json['created_at'], equals('2024-01-01T00:00:00.000Z'));
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'provider': 'facebook',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final user = User.fromJson(json);

        expect(user.name, isNull);
        expect(user.avatarUrl, isNull);
      });

      /// **Feature: multimodal-ai-assistant, Property 4: Message Persistence Round-Trip**
      /// **Validates: Requirements 9.1, 9.2**
      test('serialization round-trip preserves all fields (property test)', () {
        final random = Random(42);

        // Run 100 iterations as per property-based testing requirements
        for (var i = 0; i < 100; i++) {
          final providers = AuthProvider.values;
          final user = User(
            id: 'user-${random.nextInt(10000)}',
            email: 'user${random.nextInt(10000)}@example.com',
            name: random.nextBool() ? 'User ${random.nextInt(1000)}' : null,
            avatarUrl: random.nextBool()
                ? 'https://example.com/avatar/${random.nextInt(1000)}.png'
                : null,
            provider: providers[random.nextInt(providers.length)],
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              1700000000000 + random.nextInt(100000000),
            ),
          );

          final json = user.toJson();
          final restored = User.fromJson(json);

          expect(restored.id, equals(user.id),
              reason: 'id should be preserved');
          expect(restored.email, equals(user.email),
              reason: 'email should be preserved');
          expect(restored.name, equals(user.name),
              reason: 'name should be preserved');
          expect(restored.avatarUrl, equals(user.avatarUrl),
              reason: 'avatarUrl should be preserved');
          expect(restored.provider, equals(user.provider),
              reason: 'provider should be preserved');
          expect(
            restored.createdAt.millisecondsSinceEpoch,
            equals(user.createdAt.millisecondsSinceEpoch),
            reason: 'createdAt should be preserved',
          );
        }
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Original Name',
          avatarUrl: null,
          provider: AuthProvider.email,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          avatarUrl: 'https://example.com/new-avatar.png',
        );

        expect(updated.id, equals(original.id));
        expect(updated.email, equals(original.email));
        expect(updated.name, equals('Updated Name'));
        expect(updated.avatarUrl, equals('https://example.com/new-avatar.png'));
        expect(updated.provider, equals(original.provider));
        expect(updated.createdAt, equals(original.createdAt));
      });
    });

    group('Equatable', () {
      test('equal users have same props', () {
        final createdAt = DateTime.utc(2024, 1, 1);
        final user1 = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test',
          avatarUrl: null,
          provider: AuthProvider.email,
          createdAt: createdAt,
        );
        final user2 = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test',
          avatarUrl: null,
          provider: AuthProvider.email,
          createdAt: createdAt,
        );

        expect(user1, equals(user2));
      });
    });
  });
}
