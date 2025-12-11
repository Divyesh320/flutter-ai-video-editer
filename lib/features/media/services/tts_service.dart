import '../../../core/models/settings_models.dart';
import 'audio_service.dart';
import 'voice_service.dart';

/// Service for handling Text-to-Speech playback based on user settings
class TTSService {
  TTSService({
    required AudioService audioService,
    required VoiceService voiceService,
  })  : _audioService = audioService,
        _voiceService = voiceService;

  final AudioService _audioService;
  final VoiceService _voiceService;

  /// Play TTS audio for the given text if TTS is enabled in settings
  /// Returns true if audio was played, false if TTS is disabled
  Future<bool> playResponseIfEnabled({
    required String text,
    required UserSettings settings,
  }) async {
    // Check if TTS is enabled in user settings
    if (!settings.ttsEnabled) {
      return false;
    }

    return playResponse(text);
  }

  /// Play TTS audio for the given text unconditionally
  /// Returns true if audio was played successfully
  Future<bool> playResponse(String text) async {
    try {
      // Get TTS audio URL from backend
      final audioUrl = await _voiceService.getTTSAudio(text);

      // Play the audio
      await _audioService.playAudio(audioUrl);

      return true;
    } catch (e) {
      // Log error but don't throw - TTS failure shouldn't break the app
      return false;
    }
  }

  /// Stop any currently playing TTS audio
  Future<void> stopPlayback() async {
    await _audioService.stopAudio();
  }

  /// Check if TTS should be played based on settings
  bool shouldPlayTTS(UserSettings settings) {
    return settings.ttsEnabled;
  }

  /// Get current playback state
  PlaybackState get playbackState => _audioService.playbackState;

  /// Stream of playback state changes
  Stream<PlaybackState> get playbackStateStream =>
      _audioService.playbackStateStream;
}

/// Determines if TTS should be played for a response
/// This is a pure function for testing
bool shouldPlayTTSForResponse({
  required bool ttsEnabled,
  required String responseText,
}) {
  // TTS should only play if:
  // 1. TTS is enabled in settings
  // 2. Response text is not empty
  return ttsEnabled && responseText.isNotEmpty;
}
