import 'dart:async';
import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
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
abstract class AudioService {
  /// Request microphone permission
  Future<bool> requestPermission();

  /// Check if microphone permission is granted
  Future<bool> hasPermission();

  /// Start audio recording
  Future<void> startRecording();

  /// Stop recording and return the audio file
  Future<File> stopRecording();

  /// Pause current recording
  Future<void> pauseRecording();

  /// Resume paused recording
  Future<void> resumeRecording();

  /// Play TTS audio from text
  Future<void> playAudio(String audioUrl);

  /// Stop audio playback
  Future<void> stopAudio();

  /// Pause audio playback
  Future<void> pauseAudio();

  /// Resume audio playback
  Future<void> resumeAudio();

  /// Stream of recording state changes
  Stream<RecordingState> get recordingStateStream;

  /// Stream of playback state changes
  Stream<PlaybackState> get playbackStateStream;

  /// Current recording state
  RecordingState get recordingState;

  /// Current playback state
  PlaybackState get playbackState;

  /// Dispose resources
  Future<void> dispose();
}

/// Implementation of AudioService using flutter_sound
class AudioServiceImpl implements AudioService {
  AudioServiceImpl({
    FlutterSoundRecorder? recorder,
    FlutterSoundPlayer? player,
  })  : _recorder = recorder ?? FlutterSoundRecorder(),
        _player = player ?? FlutterSoundPlayer();

  final FlutterSoundRecorder _recorder;
  final FlutterSoundPlayer _player;

  final _recordingStateController = StreamController<RecordingState>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();

  RecordingState _recordingState = RecordingState.idle;
  PlaybackState _playbackState = PlaybackState.idle;

  String? _currentRecordingPath;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;

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

  void _setRecordingState(RecordingState state) {
    _recordingState = state;
    _recordingStateController.add(state);
  }

  void _setPlaybackState(PlaybackState state) {
    _playbackState = state;
    _playbackStateController.add(state);
  }

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<void> _initRecorder() async {
    if (_isRecorderInitialized) return;
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> _initPlayer() async {
    if (_isPlayerInitialized) return;
    await _player.openPlayer();
    _isPlayerInitialized = true;
  }

  @override
  Future<void> startRecording() async {
    // Check permission first
    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        _setRecordingState(RecordingState.error);
        throw const PermissionDeniedException();
      }
    }

    try {
      await _initRecorder();

      // Generate unique file path for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.aac';

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _setRecordingState(RecordingState.recording);
    } catch (e) {
      _setRecordingState(RecordingState.error);
      throw AudioException('Failed to start recording: $e');
    }
  }

  @override
  Future<File> stopRecording() async {
    if (_recordingState != RecordingState.recording &&
        _recordingState != RecordingState.paused) {
      throw const AudioException('No active recording to stop');
    }

    try {
      await _recorder.stopRecorder();
      _setRecordingState(RecordingState.idle);

      if (_currentRecordingPath == null) {
        throw const AudioException('Recording path not found');
      }

      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        throw const AudioException('Recording file not found');
      }

      return file;
    } catch (e) {
      _setRecordingState(RecordingState.error);
      if (e is AudioException) rethrow;
      throw AudioException('Failed to stop recording: $e');
    }
  }

  @override
  Future<void> pauseRecording() async {
    if (_recordingState != RecordingState.recording) {
      throw const AudioException('No active recording to pause');
    }

    try {
      await _recorder.pauseRecorder();
      _setRecordingState(RecordingState.paused);
    } catch (e) {
      _setRecordingState(RecordingState.error);
      throw AudioException('Failed to pause recording: $e');
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (_recordingState != RecordingState.paused) {
      throw const AudioException('No paused recording to resume');
    }

    try {
      await _recorder.resumeRecorder();
      _setRecordingState(RecordingState.recording);
    } catch (e) {
      _setRecordingState(RecordingState.error);
      throw AudioException('Failed to resume recording: $e');
    }
  }

  @override
  Future<void> playAudio(String audioUrl) async {
    try {
      await _initPlayer();

      // Set up completion callback
      _player.setSubscriptionDuration(const Duration(milliseconds: 100));

      await _player.startPlayer(
        fromURI: audioUrl,
        whenFinished: () {
          _setPlaybackState(PlaybackState.completed);
        },
      );

      _setPlaybackState(PlaybackState.playing);
    } catch (e) {
      _setPlaybackState(PlaybackState.error);
      throw AudioException('Failed to play audio: $e');
    }
  }

  @override
  Future<void> stopAudio() async {
    if (_playbackState != PlaybackState.playing &&
        _playbackState != PlaybackState.paused) {
      return; // Nothing to stop
    }

    try {
      await _player.stopPlayer();
      _setPlaybackState(PlaybackState.idle);
    } catch (e) {
      _setPlaybackState(PlaybackState.error);
      throw AudioException('Failed to stop audio: $e');
    }
  }

  @override
  Future<void> pauseAudio() async {
    if (_playbackState != PlaybackState.playing) {
      throw const AudioException('No audio playing to pause');
    }

    try {
      await _player.pausePlayer();
      _setPlaybackState(PlaybackState.paused);
    } catch (e) {
      _setPlaybackState(PlaybackState.error);
      throw AudioException('Failed to pause audio: $e');
    }
  }

  @override
  Future<void> resumeAudio() async {
    if (_playbackState != PlaybackState.paused) {
      throw const AudioException('No paused audio to resume');
    }

    try {
      await _player.resumePlayer();
      _setPlaybackState(PlaybackState.playing);
    } catch (e) {
      _setPlaybackState(PlaybackState.error);
      throw AudioException('Failed to resume audio: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _recordingStateController.close();
    await _playbackStateController.close();

    if (_isRecorderInitialized) {
      await _recorder.closeRecorder();
    }
    if (_isPlayerInitialized) {
      await _player.closePlayer();
    }
  }
}
