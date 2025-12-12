import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Recording state for audio capture
enum RecordingState {
  idle,
  recording,
  paused,
  error,
}

/// Playback state for TTS audio
enum PlaybackState {
  idle,
  playing,
  paused,
  completed,
  error,
}

/// Exception thrown when audio operations fail
class AudioException implements Exception {
  const AudioException(this.message);
  final String message;

  @override
  String toString() => 'AudioException: $message';
}

/// Exception thrown when microphone permission is denied
class PermissionDeniedException extends AudioException {
  const PermissionDeniedException()
      : super('Microphone permission denied. Please grant permission in settings.');
}

/// Abstract interface for audio operations
/// NOTE: Audio recording/playback features removed (PAID APIs - OpenAI Whisper/TTS)
abstract class AudioService {
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<File> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<void> playAudio(String audioUrl);
  Future<void> stopAudio();
  Future<void> pauseAudio();
  Future<void> resumeAudio();
  Stream<RecordingState> get recordingStateStream;
  Stream<PlaybackState> get playbackStateStream;
  RecordingState get recordingState;
  PlaybackState get playbackState;
  Future<void> dispose();
}

/// Stub implementation - Audio features disabled (PAID APIs removed)
/// Speech-to-Text and Text-to-Speech require OpenAI paid APIs
class AudioServiceImpl implements AudioService {
  final _recordingStateController = StreamController<RecordingState>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();

  RecordingState _recordingState = RecordingState.idle;
  PlaybackState _playbackState = PlaybackState.idle;

  @override
  RecordingState get recordingState => _recordingState;

  @override
  PlaybackState get playbackState => _playbackState;

  @override
  Stream<RecordingState> get recordingStateStream =>
      _recordingStateController.stream;

  @override
  Stream<PlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> startRecording() async {
    throw const AudioException(
      'Audio recording disabled - Speech-to-Text requires paid API (OpenAI Whisper)'
    );
  }

  @override
  Future<File> stopRecording() async {
    throw const AudioException('No active recording');
  }

  @override
  Future<void> pauseRecording() async {
    throw const AudioException('No active recording');
  }

  @override
  Future<void> resumeRecording() async {
    throw const AudioException('No paused recording');
  }

  @override
  Future<void> playAudio(String audioUrl) async {
    throw const AudioException(
      'Audio playback disabled - Text-to-Speech requires paid API (OpenAI TTS)'
    );
  }

  @override
  Future<void> stopAudio() async {}

  @override
  Future<void> pauseAudio() async {}

  @override
  Future<void> resumeAudio() async {}

  @override
  Future<void> dispose() async {
    await _recordingStateController.close();
    await _playbackStateController.close();
  }
}
