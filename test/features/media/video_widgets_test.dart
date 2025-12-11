import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/media/widgets/video_summary_card.dart';
import 'package:multimodal_ai_assistant/features/media/widgets/video_upload_card.dart';

void main() {
  group('VideoUploadCard', () {
    testWidgets('displays uploading state with progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.uploading,
              uploadProgress: 0.45,
            ),
          ),
        ),
      );

      expect(find.text('Uploading video...'), findsOneWidget);
      expect(find.text('45% uploaded'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays processing state with progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.processing,
              processingProgress: 60,
            ),
          ),
        ),
      );

      expect(find.text('Processing video...'), findsOneWidget);
      expect(find.textContaining('60%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.failed,
              errorMessage: 'Video processing failed due to invalid format',
              onRetry: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Video processing failed'), findsOneWidget);
      expect(find.text('Video processing failed due to invalid format'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is pressed', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.failed,
              errorMessage: 'Error',
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button is pressed during upload', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.uploading,
              uploadProgress: 0.5,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets('displays nothing when idle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.idle,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('displays VideoSummaryCard when completed', (tester) async {
      const summary = VideoSummary(
        title: 'Test Video Title',
        highlights: ['Point 1', 'Point 2', 'Point 3', 'Point 4'],
        transcript: 'This is the transcript.',
        duration: 120,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.completed,
              summary: summary,
            ),
          ),
        ),
      );

      expect(find.text('Test Video Title'), findsOneWidget);
      expect(find.text('Point 1'), findsOneWidget);
      expect(find.text('Point 2'), findsOneWidget);
      expect(find.text('Point 3'), findsOneWidget);
      expect(find.text('Point 4'), findsOneWidget);
    });
  });

  group('VideoSummaryCard', () {
    const testSummary = VideoSummary(
      title: 'Introduction to Flutter Development',
      highlights: [
        'Flutter is a cross-platform framework',
        'Uses Dart programming language',
        'Hot reload for fast development',
        'Rich widget library included',
      ],
      transcript: 'Welcome to this tutorial about Flutter development...',
      duration: 180,
    );

    testWidgets('displays title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(summary: testSummary),
            ),
          ),
        ),
      );

      expect(find.text('Introduction to Flutter Development'), findsOneWidget);
    });

    testWidgets('displays all 4 highlights', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(summary: testSummary),
            ),
          ),
        ),
      );

      expect(find.text('Flutter is a cross-platform framework'), findsOneWidget);
      expect(find.text('Uses Dart programming language'), findsOneWidget);
      expect(find.text('Hot reload for fast development'), findsOneWidget);
      expect(find.text('Rich widget library included'), findsOneWidget);
    });

    testWidgets('displays duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(summary: testSummary),
            ),
          ),
        ),
      );

      expect(find.textContaining('3 min'), findsOneWidget);
    });

    testWidgets('transcript section is collapsible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(summary: testSummary),
            ),
          ),
        ),
      );

      // Transcript should be collapsed by default
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.textContaining('Welcome to this tutorial'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Transcript'));
      await tester.pump();

      // Now transcript should be visible
      expect(find.textContaining('Welcome to this tutorial'), findsOneWidget);
    });

    testWidgets('shows follow-up button when callback provided', (tester) async {
      var followUpCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(
                summary: testSummary,
                onAskFollowUp: () => followUpCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ask a follow-up question'), findsOneWidget);

      await tester.tap(find.text('Ask a follow-up question'));
      await tester.pump();

      expect(followUpCalled, isTrue);
    });

    testWidgets('hides follow-up button when no callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(summary: testSummary),
            ),
          ),
        ),
      );

      expect(find.text('Ask a follow-up question'), findsNothing);
    });

    testWidgets('shows play button when video URL provided', (tester) async {
      var playCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoSummaryCard(
                summary: testSummary,
                videoUrl: 'https://example.com/video.mp4',
                onPlayVideo: () => playCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pump();

      expect(playCalled, isTrue);
    });
  });

  group('Video Validation Error Display', () {
    testWidgets('displays validation error in error card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.failed,
              errorMessage: 'Video duration must be under 5 minutes. Current duration: 6m 30s',
            ),
          ),
        ),
      );

      expect(find.textContaining('5 minutes'), findsOneWidget);
      expect(find.textContaining('6m 30s'), findsOneWidget);
    });

    testWidgets('displays file size error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoUploadCard(
              state: VideoUploadState.failed,
              errorMessage: 'Video file size must be under 100MB. Current size: 150.5MB',
            ),
          ),
        ),
      );

      expect(find.textContaining('100MB'), findsOneWidget);
      expect(find.textContaining('150.5MB'), findsOneWidget);
    });
  });
}
