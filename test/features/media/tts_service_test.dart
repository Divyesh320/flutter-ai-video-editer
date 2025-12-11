import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/settings_models.dart';
import 'package:multimodal_ai_assistant/features/media/services/tts_service.dart';

void main() {
  group('shouldPlayTTSForResponse', () {
    /// **Feature: multimodal-ai-assistant, Property 8: TTS Conditional Playback**
    /// **Validates: Requirements 3.4**
    ///
    /// Property: For any assistant response when TTS is enabled in user settings,
    /// the system SHALL generate audio output; when TTS is disabled, no audio
    /// SHALL be generated.
    test('TTS conditional playback respects user settings (property test)', () {
      final random = Random(42);

      // Run 100 iterations as per property-based testing requirements
      for (var i = 0; i < 100; i++) {
        // Generate random TTS enabled setting
        final ttsEnabled = random.nextBool();

        // Generate random response text (non-empty for valid responses)
        final responseWords = List.generate(
          random.nextInt(50) + 1,
          (_) => _generateRandomWord(random),
        );
        final responseText = responseWords.join(' ');

        // Test the conditional playback logic
        final shouldPlay = shouldPlayTTSForResponse(
          ttsEnabled: ttsEnabled,
          responseText: responseText,
        );

        // Property assertions:
        if (ttsEnabled) {
          // When TTS is enabled and response is non-empty, should play
          expect(
            shouldPlay,
            isTrue,
            reason: 'TTS should play when enabled and response is non-empty',
          );
        } else {
          // When TTS is disabled, should NOT play regardless of response
          expect(
            shouldPlay,
            isFalse,
            reason: 'TTS should NOT play when disabled',
          );
        }
      }
    });

    test('TTS does not play for empty response even when enabled', () {
      final shouldPlay = shouldPlayTTSForResponse(
        ttsEnabled: true,
        responseText: '',
      );

      expect(shouldPlay, isFalse);
    });

    test('TTS plays for non-empty response when enabled', () {
      final shouldPlay = shouldPlayTTSForResponse(
        ttsEnabled: true,
        responseText: 'Hello, how can I help you?',
      );

      expect(shouldPlay, isTrue);
    });

    test('TTS does not play when disabled', () {
      final shouldPlay = shouldPlayTTSForResponse(
        ttsEnabled: false,
        responseText: 'Hello, how can I help you?',
      );

      expect(shouldPlay, isFalse);
    });
  });

  group('TTSService.shouldPlayTTS', () {
    test('returns true when TTS is enabled in settings', () {
      const settings = UserSettings(ttsEnabled: true);

      // Using the pure function to test the logic
      final result = shouldPlayTTSForResponse(
        ttsEnabled: settings.ttsEnabled,
        responseText: 'Test response',
      );

      expect(result, isTrue);
    });

    test('returns false when TTS is disabled in settings', () {
      const settings = UserSettings(ttsEnabled: false);

      final result = shouldPlayTTSForResponse(
        ttsEnabled: settings.ttsEnabled,
        responseText: 'Test response',
      );

      expect(result, isFalse);
    });

    /// Property test for UserSettings TTS toggle
    test('TTS setting toggle property (property test)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final ttsEnabled = random.nextBool();
        final darkMode = random.nextBool();
        final preferredVoice = random.nextBool() ? 'voice_${random.nextInt(10)}' : null;

        final settings = UserSettings(
          ttsEnabled: ttsEnabled,
          darkMode: darkMode,
          preferredVoice: preferredVoice,
        );

        // Generate random response
        final responseText = List.generate(
          random.nextInt(20) + 1,
          (_) => _generateRandomWord(random),
        ).join(' ');

        final shouldPlay = shouldPlayTTSForResponse(
          ttsEnabled: settings.ttsEnabled,
          responseText: responseText,
        );

        // The result should match the ttsEnabled setting
        expect(
          shouldPlay,
          equals(ttsEnabled),
          reason: 'shouldPlayTTS should match ttsEnabled setting',
        );
      }
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
