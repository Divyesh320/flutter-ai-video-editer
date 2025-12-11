import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/message.dart';

void main() {
  group('Message Model', () {
    group('JSON Serialization', () {
      test('fromJson creates valid Message', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-456',
          'role': 'user',
          'content': 'Hello, AI!',
          'type': 'text',
          'metadata': {'key': 'value'},
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final message = Message.fromJson(json);

        expect(message.id, equals('msg-123'));
        expect(message.conversationId, equals('conv-456'));
        expect(message.role, equals(MessageRole.user));
        expect(message.content, equals('Hello, AI!'));
        expect(message.type, equals(MessageType.text));
        expect(message.metadata, equals({'key': 'value'}));
        expect(message.createdAt, equals(DateTime.utc(2024, 1, 1)));
      });

      test('toJson produces valid JSON', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-456',
          role: MessageRole.assistant,
          content: 'Hello, human!',
          type: MessageType.text,
          metadata: {'tokens': 10},
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final json = message.toJson();

        expect(json['id'], equals('msg-123'));
        expect(json['conversation_id'], equals('conv-456'));
        expect(json['role'], equals('assistant'));
        expect(json['content'], equals('Hello, human!'));
        expect(json['type'], equals('text'));
        expect(json['metadata'], equals({'tokens': 10}));
        expect(json['created_at'], equals('2024-01-01T00:00:00.000Z'));
      });

      test('handles message with media references', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-456',
          'role': 'user',
          'content': 'Check this image',
          'type': 'image',
          'media': [
            {
              'id': 'media-789',
              'url': 'https://example.com/image.png',
              'type': 'image',
              'analysis': {'caption': 'A cat'},
            }
          ],
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final message = Message.fromJson(json);

        expect(message.media, isNotNull);
        expect(message.media!.length, equals(1));
        expect(message.media![0].id, equals('media-789'));
        expect(message.media![0].type, equals(MediaType.image));
        expect(message.media![0].analysis, equals({'caption': 'A cat'}));
      });

      /// **Feature: multimodal-ai-assistant, Property 4: Message Persistence Round-Trip**
      /// **Validates: Requirements 9.1, 9.2, 9.3**
      test('serialization round-trip preserves all fields (property test)', () {
        final random = Random(42);
        final roles = MessageRole.values;
        final types = MessageType.values;
        final mediaTypes = MediaType.values;

        // Run 100 iterations as per property-based testing requirements
        for (var i = 0; i < 100; i++) {
          // Generate random media references
          final mediaCount = random.nextInt(3);
          final media = mediaCount > 0
              ? List.generate(
                  mediaCount,
                  (j) => MediaReference(
                    id: 'media-${random.nextInt(10000)}',
                    url: 'https://example.com/file${random.nextInt(1000)}.png',
                    type: mediaTypes[random.nextInt(mediaTypes.length)],
                    analysis: random.nextBool()
                        ? {'caption': 'Caption ${random.nextInt(100)}'}
                        : null,
                    transcript: random.nextBool()
                        ? 'Transcript ${random.nextInt(100)}'
                        : null,
                  ),
                )
              : null;

          final message = Message(
            id: 'msg-${random.nextInt(10000)}',
            conversationId: 'conv-${random.nextInt(10000)}',
            role: roles[random.nextInt(roles.length)],
            content: 'Content ${random.nextInt(1000)}',
            type: types[random.nextInt(types.length)],
            metadata: random.nextBool()
                ? {'key${random.nextInt(10)}': 'value${random.nextInt(100)}'}
                : null,
            media: media,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              1700000000000 + random.nextInt(100000000),
            ),
          );

          final json = message.toJson();
          final restored = Message.fromJson(json);

          expect(restored.id, equals(message.id),
              reason: 'id should be preserved');
          expect(restored.conversationId, equals(message.conversationId),
              reason: 'conversationId should be preserved');
          expect(restored.role, equals(message.role),
              reason: 'role should be preserved');
          expect(restored.content, equals(message.content),
              reason: 'content should be preserved');
          expect(restored.type, equals(message.type),
              reason: 'type should be preserved');
          expect(restored.metadata, equals(message.metadata),
              reason: 'metadata should be preserved');
          expect(
            restored.createdAt.millisecondsSinceEpoch,
            equals(message.createdAt.millisecondsSinceEpoch),
            reason: 'createdAt should be preserved',
          );

          // Verify media references
          if (message.media != null) {
            expect(restored.media, isNotNull,
                reason: 'media should be preserved');
            expect(restored.media!.length, equals(message.media!.length),
                reason: 'media count should match');
            for (var j = 0; j < message.media!.length; j++) {
              expect(restored.media![j].id, equals(message.media![j].id));
              expect(restored.media![j].url, equals(message.media![j].url));
              expect(restored.media![j].type, equals(message.media![j].type));
              expect(restored.media![j].analysis,
                  equals(message.media![j].analysis));
              expect(restored.media![j].transcript,
                  equals(message.media![j].transcript));
            }
          } else {
            expect(restored.media, isNull);
          }
        }
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = Message(
          id: 'msg-123',
          conversationId: 'conv-456',
          role: MessageRole.user,
          content: 'Original content',
          type: MessageType.text,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final updated = original.copyWith(
          content: 'Updated content',
          role: MessageRole.assistant,
        );

        expect(updated.id, equals(original.id));
        expect(updated.conversationId, equals(original.conversationId));
        expect(updated.role, equals(MessageRole.assistant));
        expect(updated.content, equals('Updated content'));
        expect(updated.type, equals(original.type));
        expect(updated.createdAt, equals(original.createdAt));
      });
    });
  });

  group('MediaReference Model', () {
    test('fromJson creates valid MediaReference', () {
      final json = {
        'id': 'media-123',
        'url': 'https://example.com/image.png',
        'type': 'image',
        'analysis': {'caption': 'A beautiful sunset'},
        'transcript': null,
      };

      final media = MediaReference.fromJson(json);

      expect(media.id, equals('media-123'));
      expect(media.url, equals('https://example.com/image.png'));
      expect(media.type, equals(MediaType.image));
      expect(media.analysis, equals({'caption': 'A beautiful sunset'}));
      expect(media.transcript, isNull);
    });

    test('toJson produces valid JSON', () {
      final media = MediaReference(
        id: 'media-123',
        url: 'https://example.com/video.mp4',
        type: MediaType.video,
        transcript: 'Hello world',
      );

      final json = media.toJson();

      expect(json['id'], equals('media-123'));
      expect(json['url'], equals('https://example.com/video.mp4'));
      expect(json['type'], equals('video'));
      expect(json['transcript'], equals('Hello world'));
    });
  });
}
