import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/media/services/video_service.dart';

void main() {
  group('Video Validation', () {
    /// **Feature: multimodal-ai-assistant, Property 12: Video Validation**
    /// **Validates: Requirements 5.1**
    /// 
    /// Property: For any video file, the validation function SHALL accept only
    /// files where duration < 5 minutes AND file size < 100MB; all other files
    /// SHALL be rejected with appropriate error.
    test('property: validates duration < 5 minutes AND size < 100MB (100 iterations)', () {
      final random = Random(42);
      
      const maxDuration = VideoValidationResult.maxDurationSeconds; // 300 seconds
      const maxSize = VideoValidationResult.maxFileSizeBytes; // 100MB

      for (var i = 0; i < 100; i++) {
        // Generate random duration (0 to 600 seconds - up to 10 minutes)
        final duration = random.nextInt(601);
        
        // Generate random file size (0 to 200MB)
        final fileSize = random.nextInt(200 * 1024 * 1024 + 1);

        final result = validateVideo(
          durationSeconds: duration,
          fileSizeBytes: fileSize,
        );

        final shouldBeValid = duration < maxDuration && fileSize < maxSize;

        expect(result.isValid, equals(shouldBeValid),
            reason: 'Video with duration=${duration}s, size=${fileSize}B '
                'should be ${shouldBeValid ? "valid" : "invalid"}');

        // If invalid, should have error message
        if (!shouldBeValid) {
          expect(result.error, isNotNull,
              reason: 'Invalid video should have error message');
          expect(result.error!.isNotEmpty, isTrue,
              reason: 'Error message should not be empty');
        }

        // Duration and file size should always be returned
        expect(result.duration, equals(duration),
            reason: 'Duration should be returned in result');
        expect(result.fileSize, equals(fileSize),
            reason: 'File size should be returned in result');
      }
    });


    /// **Feature: multimodal-ai-assistant, Property 12: Video Validation**
    /// **Validates: Requirements 5.1**
    test('property: videos under limits are always accepted (100 iterations)', () {
      final random = Random(42);
      
      const maxDuration = VideoValidationResult.maxDurationSeconds;
      const maxSize = VideoValidationResult.maxFileSizeBytes;

      for (var i = 0; i < 100; i++) {
        // Generate valid duration (0 to 299 seconds)
        final duration = random.nextInt(maxDuration);
        
        // Generate valid file size (0 to 99.99MB)
        final fileSize = random.nextInt(maxSize);

        final result = validateVideo(
          durationSeconds: duration,
          fileSizeBytes: fileSize,
        );

        expect(result.isValid, isTrue,
            reason: 'Video with duration=${duration}s (<$maxDuration), '
                'size=${fileSize}B (<$maxSize) should be valid');
        expect(result.error, isNull,
            reason: 'Valid video should not have error');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 12: Video Validation**
    /// **Validates: Requirements 5.1**
    test('property: videos at or over limits are always rejected (100 iterations)', () {
      final random = Random(42);
      
      const maxDuration = VideoValidationResult.maxDurationSeconds;
      const maxSize = VideoValidationResult.maxFileSizeBytes;

      for (var i = 0; i < 100; i++) {
        // Randomly choose which constraint to violate
        final violateDuration = random.nextBool();
        final violateSize = random.nextBool() || !violateDuration;

        // Generate duration
        final duration = violateDuration
            ? maxDuration + random.nextInt(300)
            : random.nextInt(maxDuration);

        // Generate file size
        final fileSize = violateSize
            ? maxSize + random.nextInt(100 * 1024 * 1024)
            : random.nextInt(maxSize);

        final result = validateVideo(
          durationSeconds: duration,
          fileSizeBytes: fileSize,
        );

        expect(result.isValid, isFalse,
            reason: 'Video with duration=${duration}s, size=${fileSize}B '
                'should be invalid');
        expect(result.error, isNotNull,
            reason: 'Invalid video should have error message');
      }
    });

    test('boundary: exactly at 5 minutes is rejected', () {
      final result = validateVideo(
        durationSeconds: 300,
        fileSizeBytes: 50 * 1024 * 1024,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('5 minutes'));
    });

    test('boundary: exactly at 100MB is rejected', () {
      final result = validateVideo(
        durationSeconds: 60,
        fileSizeBytes: 100 * 1024 * 1024,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('100MB'));
    });

    test('boundary: just under limits is accepted', () {
      final result = validateVideo(
        durationSeconds: 299,
        fileSizeBytes: 100 * 1024 * 1024 - 1,
      );

      expect(result.isValid, isTrue);
    });
  });

  group('VideoJobResponse', () {
    test('fromJson parses pending status', () {
      final json = {
        'job_id': 'job-123',
        'status': 'pending',
        'progress': null,
        'result': null,
        'error': null,
      };

      final response = VideoJobResponse.fromJson(json);

      expect(response.jobId, equals('job-123'));
      expect(response.status, equals(VideoJobStatus.pending));
      expect(response.progress, isNull);
      expect(response.result, isNull);
    });

    test('fromJson parses processing status with progress', () {
      final json = {
        'job_id': 'job-456',
        'status': 'processing',
        'progress': 45,
        'result': null,
        'error': null,
      };

      final response = VideoJobResponse.fromJson(json);

      expect(response.status, equals(VideoJobStatus.processing));
      expect(response.progress, equals(45));
    });

    test('fromJson parses completed status with result', () {
      final json = {
        'job_id': 'job-789',
        'status': 'completed',
        'progress': 100,
        'result': {
          'title': 'Test Video Summary',
          'highlights': ['Point 1', 'Point 2', 'Point 3', 'Point 4'],
          'transcript': 'This is the transcript.',
          'duration': 120,
        },
        'error': null,
      };

      final response = VideoJobResponse.fromJson(json);

      expect(response.status, equals(VideoJobStatus.completed));
      expect(response.result, isNotNull);
      expect(response.result!.title, equals('Test Video Summary'));
      expect(response.result!.highlights.length, equals(4));
    });

    test('fromJson parses failed status with error', () {
      final json = {
        'job_id': 'job-error',
        'status': 'failed',
        'progress': null,
        'result': null,
        'error': 'Processing failed due to invalid format',
      };

      final response = VideoJobResponse.fromJson(json);

      expect(response.status, equals(VideoJobStatus.failed));
      expect(response.error, equals('Processing failed due to invalid format'));
    });

    test('toJson produces valid JSON', () {
      const response = VideoJobResponse(
        jobId: 'job-test',
        status: VideoJobStatus.processing,
        progress: 50,
      );

      final json = response.toJson();

      expect(json['job_id'], equals('job-test'));
      expect(json['status'], equals('processing'));
      expect(json['progress'], equals(50));
    });
  });

  group('VideoException', () {
    test('toString returns formatted message', () {
      const exception = VideoException('Test error message');
      expect(exception.toString(), equals('VideoException: Test error message'));
    });
  });

  group('VideoValidationResult constants', () {
    test('maxDurationSeconds is 5 minutes', () {
      expect(VideoValidationResult.maxDurationSeconds, equals(300));
    });

    test('maxFileSizeBytes is 100MB', () {
      expect(VideoValidationResult.maxFileSizeBytes, equals(100 * 1024 * 1024));
    });
  });

  group('VideoSummary Format', () {
    /// **Feature: multimodal-ai-assistant, Property 13: Video Summary Format**
    /// **Validates: Requirements 5.4**
    test('property: valid VideoSummary has title <= 20 words and exactly 4 highlights (100 iterations)', () {
      final random = Random(42);
      final words = [
        'the', 'quick', 'brown', 'fox', 'jumps', 'over', 'lazy', 'dog',
        'video', 'summary', 'tutorial', 'guide', 'introduction', 'overview',
        'how', 'to', 'learn', 'build', 'create', 'make', 'understand',
      ];

      for (var i = 0; i < 100; i++) {
        final titleWordCount = 1 + random.nextInt(20);
        final titleWords = List.generate(
          titleWordCount,
          (_) => words[random.nextInt(words.length)],
        );
        final title = titleWords.join(' ');

        final highlights = List.generate(4, (j) {
          final highlightWordCount = 3 + random.nextInt(10);
          final highlightWords = List.generate(
            highlightWordCount,
            (_) => words[random.nextInt(words.length)],
          );
          return highlightWords.join(' ');
        });

        final transcriptWordCount = 50 + random.nextInt(200);
        final transcriptWords = List.generate(
          transcriptWordCount,
          (_) => words[random.nextInt(words.length)],
        );
        final transcript = transcriptWords.join(' ');

        final duration = 1 + random.nextInt(300);

        final summary = VideoSummary(
          title: title,
          highlights: highlights,
          transcript: transcript,
          duration: duration,
        );

        expect(summary.isTitleValid, isTrue,
            reason: 'Title has ${title.split(' ').length} words, should be <= 20');
        expect(summary.hasValidHighlights, isTrue,
            reason: 'Summary should have exactly 4 highlights');
        expect(summary.highlights.length, equals(4));
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 13: Video Summary Format**
    /// **Validates: Requirements 5.4**
    test('property: VideoSummary with > 20 word title is flagged as invalid (100 iterations)', () {
      final random = Random(42);
      final words = ['word', 'test', 'long', 'title', 'video', 'summary'];

      for (var i = 0; i < 100; i++) {
        final titleWordCount = 21 + random.nextInt(20);
        final titleWords = List.generate(
          titleWordCount,
          (_) => words[random.nextInt(words.length)],
        );
        final title = titleWords.join(' ');

        final summary = VideoSummary(
          title: title,
          highlights: ['h1', 'h2', 'h3', 'h4'],
          transcript: 'Test transcript',
          duration: 60,
        );

        expect(summary.isTitleValid, isFalse,
            reason: 'Title with ${title.split(' ').length} words should be invalid');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 13: Video Summary Format**
    /// **Validates: Requirements 5.4**
    test('property: VideoSummary with != 4 highlights is flagged as invalid (100 iterations)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        int highlightCount;
        do {
          highlightCount = random.nextInt(10);
        } while (highlightCount == 4);

        final highlights = List.generate(highlightCount, (j) => 'Highlight $j');

        final summary = VideoSummary(
          title: 'Valid Title',
          highlights: highlights,
          transcript: 'Test transcript',
          duration: 60,
        );

        expect(summary.hasValidHighlights, isFalse,
            reason: 'Summary with $highlightCount highlights should be invalid');
      }
    });

    test('boundary: exactly 20 words in title is valid', () {
      final title = List.generate(20, (i) => 'word').join(' ');
      
      final summary = VideoSummary(
        title: title,
        highlights: ['h1', 'h2', 'h3', 'h4'],
        transcript: 'Test',
        duration: 60,
      );

      expect(summary.isTitleValid, isTrue);
    });

    test('boundary: 21 words in title is invalid', () {
      final title = List.generate(21, (i) => 'word').join(' ');
      
      final summary = VideoSummary(
        title: title,
        highlights: ['h1', 'h2', 'h3', 'h4'],
        transcript: 'Test',
        duration: 60,
      );

      expect(summary.isTitleValid, isFalse);
    });

    test('VideoSummary serialization round-trip', () {
      const original = VideoSummary(
        title: 'Test Video Summary',
        highlights: ['Point 1', 'Point 2', 'Point 3', 'Point 4'],
        transcript: 'This is the full transcript of the video.',
        duration: 180,
      );

      final json = original.toJson();
      final restored = VideoSummary.fromJson(json);

      expect(restored.title, equals(original.title));
      expect(restored.highlights, equals(original.highlights));
      expect(restored.transcript, equals(original.transcript));
      expect(restored.duration, equals(original.duration));
    });

    test('durationObject returns correct Duration', () {
      const summary = VideoSummary(
        title: 'Test',
        highlights: ['h1', 'h2', 'h3', 'h4'],
        transcript: 'Test',
        duration: 125,
      );

      expect(summary.durationObject, equals(const Duration(seconds: 125)));
      expect(summary.durationObject.inMinutes, equals(2));
      expect(summary.durationObject.inSeconds % 60, equals(5));
    });
  });
}
