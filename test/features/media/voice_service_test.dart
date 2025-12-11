import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/media/services/voice_service.dart';

void main() {
  group('VoiceResponse', () {
    test('fromJson creates valid VoiceResponse', () {
      final json = {
        'transcript': 'Hello, how are you?',
        'response': 'I am doing well, thank you!',
        'message_id': 'msg-123',
      };

      final voiceResponse = VoiceResponse.fromJson(json);

      expect(voiceResponse.transcript, equals('Hello, how are you?'));
      expect(voiceResponse.response, equals('I am doing well, thank you!'));
      expect(voiceResponse.messageId, equals('msg-123'));
    });

    test('toJson produces valid JSON', () {
      const voiceResponse = VoiceResponse(
        transcript: 'Test transcript',
        response: 'Test response',
        messageId: 'msg-456',
      );

      final json = voiceResponse.toJson();

      expect(json['transcript'], equals('Test transcript'));
      expect(json['response'], equals('Test response'));
      expect(json['message_id'], equals('msg-456'));
    });
  });

  group('createMessageFromVoice', () {
    /// **Feature: multimodal-ai-assistant, Property 7: Voice-to-Chat Pipeline**
    /// **Validates: Requirements 3.2, 3.3**
    ///
    /// Property: For any recorded audio file, the system SHALL produce a text
    /// transcription via STT and automatically submit it as a chat message,
    /// resulting in a new Message record with the transcribed content.
    test('voice-to-chat pipeline creates message with transcribed content (property test)', () {
      final random = Random(42);

      // Run 100 iterations as per property-based testing requirements
      for (var i = 0; i < 100; i++) {
        // Generate random transcript content
        final transcriptWords = List.generate(
          random.nextInt(20) + 1,
          (_) => _generateRandomWord(random),
        );
        final transcript = transcriptWords.join(' ');

        // Generate random response
        final responseWords = List.generate(
          random.nextInt(50) + 1,
          (_) => _generateRandomWord(random),
        );
        final response = responseWords.join(' ');

        // Generate random IDs
        final messageId = 'msg-${random.nextInt(100000)}';
        final conversationId = 'conv-${random.nextInt(100000)}';

        // Create VoiceResponse (simulating STT result)
        final voiceResponse = VoiceResponse(
          transcript: transcript,
          response: response,
          messageId: messageId,
        );

        // Create message from voice response (the pipeline output)
        final message = createMessageFromVoice(
          voiceResponse: voiceResponse,
          conversationId: conversationId,
        );

        // Property assertions:
        // 1. Message content equals the transcribed text
        expect(
          message.content,
          equals(transcript),
          reason: 'Message content should equal the transcribed text',
        );

        // 2. Message has the correct conversation ID
        expect(
          message.conversationId,
          equals(conversationId),
          reason: 'Message should belong to the correct conversation',
        );

        // 3. Message has the correct message ID from response
        expect(
          message.id,
          equals(messageId),
          reason: 'Message ID should match the response message ID',
        );

        // 4. Message role is user (voice input comes from user)
        expect(
          message.role,
          equals(MessageRole.user),
          reason: 'Voice message should have user role',
        );

        // 5. Message type is audio
        expect(
          message.type,
          equals(MessageType.audio),
          reason: 'Voice message should have audio type',
        );

        // 6. Message metadata contains transcript
        expect(
          message.metadata,
          isNotNull,
          reason: 'Message should have metadata',
        );
        expect(
          message.metadata!['transcript'],
          equals(transcript),
          reason: 'Metadata should contain the transcript',
        );
        expect(
          message.metadata!['source'],
          equals('voice'),
          reason: 'Metadata should indicate voice source',
        );

        // 7. Message has a valid creation timestamp
        expect(
          message.createdAt,
          isNotNull,
          reason: 'Message should have a creation timestamp',
        );
        expect(
          message.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))),
          isTrue,
          reason: 'Creation timestamp should be recent',
        );
      }
    });

    test('creates message with correct fields', () {
      const voiceResponse = VoiceResponse(
        transcript: 'What is the weather today?',
        response: 'The weather is sunny.',
        messageId: 'msg-789',
      );

      final message = createMessageFromVoice(
        voiceResponse: voiceResponse,
        conversationId: 'conv-123',
      );

      expect(message.id, equals('msg-789'));
      expect(message.conversationId, equals('conv-123'));
      expect(message.role, equals(MessageRole.user));
      expect(message.content, equals('What is the weather today?'));
      expect(message.type, equals(MessageType.audio));
      expect(message.metadata?['source'], equals('voice'));
      expect(message.metadata?['transcript'], equals('What is the weather today?'));
    });
  });
}

/// Generate a random word for testing
String _generateRandomWord(Random random) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final length = random.nextInt(10) + 1;
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
