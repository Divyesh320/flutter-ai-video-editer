import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/features/media/services/audio_service.dart';
import 'package:multimodal_ai_assistant/features/media/widgets/voice_recording_button.dart';

/// Mock AudioService for testing
class MockAudioService implements AudioService {
  MockAudioService({
    this.hasPermissionResult = true,
    this.requestPermissionResult = true,
    this.shouldThrowOnStart = false,
    this.shouldThrowPermissionDenied = false,
  });

  final bool hasPermissionResult;
  final bool requestPermissionResult;
  final bool shouldThrowOnStart;
  final bool shouldThrowPermissionDenied;

  final _recordingStateController = StreamController<RecordingState>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();

  RecordingState _recordingState = RecordingState.idle;
  PlaybackState _playbackState = PlaybackState.idle;

  String? lastRecordingPath;
  bool startRecordingCalled = false;
  bool stopRecordingCalled = false;

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

  void setRecordingState(RecordingState state) {
    _recordingState = state;
    _recordingStateController.add(state);
  }

  @override
  Future<bool> hasPermission() async => hasPermissionResult;

  @override
  Future<bool> requestPermission() async => requestPermissionResult;

  @override
  Future<void> startRecording() async {
    startRecordingCalled = true;
    if (shouldThrowPermissionDenied) {
      throw const PermissionDeniedException();
    }
    if (shouldThrowOnStart) {
      throw const AudioException('Failed to start recording');
    }
    setRecordingState(RecordingState.recording);
  }

  @override
  Future<File> stopRecording() async {
    stopRecordingCalled = true;
    setRecordingState(RecordingState.idle);
    lastRecordingPath = '/tmp/test_recording.aac';
    return File(lastRecordingPath!);
  }

  @override
  Future<void> pauseRecording() async {
    setRecordingState(RecordingState.paused);
  }

  @override
  Future<void> resumeRecording() async {
    setRecordingState(RecordingState.recording);
  }

  @override
  Future<void> playAudio(String audioUrl) async {
    _playbackState = PlaybackState.playing;
    _playbackStateController.add(_playbackState);
  }

  @override
  Future<void> stopAudio() async {
    _playbackState = PlaybackState.idle;
    _playbackStateController.add(_playbackState);
  }

  @override
  Future<void> pauseAudio() async {
    _playbackState = PlaybackState.paused;
    _playbackStateController.add(_playbackState);
  }

  @override
  Future<void> resumeAudio() async {
    _playbackState = PlaybackState.playing;
    _playbackStateController.add(_playbackState);
  }

  @override
  Future<void> dispose() async {
    await _recordingStateController.close();
    await _playbackStateController.close();
  }
}

void main() {
  group('VoiceRecordingButton', () {
    late MockAudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();
    });

    tearDown(() async {
      await mockAudioService.dispose();
    });

    Widget buildTestWidget({
      required void Function(String) onRecordingComplete,
      void Function(String)? onError,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: VoiceRecordingButton(
              audioService: mockAudioService,
              onRecordingComplete: onRecordingComplete,
              onError: onError,
            ),
          ),
        ),
      );
    }

    testWidgets('displays microphone icon when idle', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('displays stop icon when recording', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      // Start recording - use tap on the InkWell inside
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump(); // Allow state to update
      await tester.pump(const Duration(milliseconds: 100)); // Allow animation to start

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('calls startRecording when tapped in idle state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockAudioService.startRecordingCalled, isTrue);
    });

    testWidgets('calls stopRecording when tapped while recording', (tester) async {
      String? completedPath;

      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (path) => completedPath = path,
      ));

      // Start recording
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockAudioService.stopRecordingCalled, isTrue);
      expect(completedPath, equals('/tmp/test_recording.aac'));
    });

    testWidgets('shows permission dialog when permission denied', (tester) async {
      mockAudioService = MockAudioService(
        hasPermissionResult: false,
        requestPermissionResult: false,
        shouldThrowPermissionDenied: true,
      );

      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(find.text('Microphone Permission Required'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('calls onError when recording fails', (tester) async {
      mockAudioService = MockAudioService(shouldThrowOnStart: true);
      String? errorMessage;

      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
        onError: (error) => errorMessage = error,
      ));

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(errorMessage, equals('Failed to start recording'));
    });
  });

  group('VoiceInputWidget', () {
    late MockAudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();
    });

    tearDown(() async {
      await mockAudioService.dispose();
    });

    Widget buildTestWidget({
      required void Function(String) onRecordingComplete,
      void Function(String)? onError,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: VoiceInputWidget(
              audioService: mockAudioService,
              onRecordingComplete: onRecordingComplete,
              onError: onError,
            ),
          ),
        ),
      );
    }

    testWidgets('displays "Tap to record" when idle', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      expect(find.text('Tap to record'), findsOneWidget);
    });

    testWidgets('displays "Recording..." when recording', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      // Start recording
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Recording... Tap to stop'), findsOneWidget);
    });

    testWidgets('displays error message when error occurs', (tester) async {
      mockAudioService = MockAudioService(shouldThrowOnStart: true);

      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(find.text('Failed to start recording'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('can dismiss error message', (tester) async {
      mockAudioService = MockAudioService(shouldThrowOnStart: true);

      await tester.pumpWidget(buildTestWidget(
        onRecordingComplete: (_) {},
      ));

      // Trigger error
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(find.text('Failed to start recording'), findsOneWidget);

      // Dismiss error
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Failed to start recording'), findsNothing);
    });
  });
}
