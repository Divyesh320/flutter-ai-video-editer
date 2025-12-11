import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';

void main() {
  group('Conversation Model', () {
    test('fromJson creates valid Conversation', () {
      final json = {
        'id': 'conv-123',
        'user_id': 'user-456',
        'title': 'Test Conversation',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
        'messages': [],
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, equals('conv-123'));
      expect(conversation.userId, equals('user-456'));
      expect(conversation.title, equals('Test Conversation'));
      expect(conversation.messages, isEmpty);
    });

    test('lastMessagePreview returns truncated content', () {
      final conversation = Conversation(
        id: 'conv-123',
        userId: 'user-456',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
        messages: [
          Message(
            id: 'msg-1',
            conversationId: 'conv-123',
            role: MessageRole.user,
            content: 'A' * 100, // 100 character message
            createdAt: DateTime.utc(2024, 1, 1),
          ),
        ],
      );

      expect(conversation.lastMessagePreview!.length, equals(53)); // 50 + "..."
      expect(conversation.lastMessagePreview!.endsWith('...'), isTrue);
    });
  });

  group('ImageAnalysis Model', () {
    test('fromJson creates valid ImageAnalysis', () {
      final json = {
        'caption': 'A cat sitting on a couch',
        'objects': [
          {'label': 'cat', 'confidence': 0.95},
          {'label': 'couch', 'confidence': 0.88},
          {'label': 'pillow', 'confidence': 0.65}, // Below threshold
        ],
        'ocr_text': 'Some text',
      };

      final analysis = ImageAnalysis.fromJson(json);

      expect(analysis.caption, equals('A cat sitting on a couch'));
      expect(analysis.objects.length, equals(3));
      expect(analysis.ocrText, equals('Some text'));
    });

    test('filteredObjects returns only high confidence objects', () {
      final analysis = ImageAnalysis(
        caption: 'Test',
        objects: [
          DetectedObject(label: 'cat', confidence: 0.95),
          DetectedObject(label: 'dog', confidence: 0.70),
          DetectedObject(label: 'bird', confidence: 0.65), // Below 70%
        ],
      );

      final filtered = analysis.filteredObjects;

      expect(filtered.length, equals(2));
      expect(filtered.map((o) => o.label), containsAll(['cat', 'dog']));
    });
  });

  group('VideoSummary Model', () {
    test('fromJson creates valid VideoSummary', () {
      final json = {
        'title': 'Introduction to Flutter',
        'highlights': [
          'Flutter is a UI toolkit',
          'Cross-platform development',
          'Hot reload feature',
          'Widget-based architecture',
        ],
        'transcript': 'Full transcript here...',
        'duration': 300,
      };

      final summary = VideoSummary.fromJson(json);

      expect(summary.title, equals('Introduction to Flutter'));
      expect(summary.highlights.length, equals(4));
      expect(summary.duration, equals(300));
      expect(summary.durationObject, equals(Duration(minutes: 5)));
    });

    test('validates title word count', () {
      final validSummary = VideoSummary(
        title: 'Short title',
        highlights: ['1', '2', '3', '4'],
        transcript: 'Test',
        duration: 60,
      );

      final invalidSummary = VideoSummary(
        title: List.generate(25, (i) => 'word').join(' '), // 25 words
        highlights: ['1', '2', '3', '4'],
        transcript: 'Test',
        duration: 60,
      );

      expect(validSummary.isTitleValid, isTrue);
      expect(invalidSummary.isTitleValid, isFalse);
    });

    test('validates highlights count', () {
      final validSummary = VideoSummary(
        title: 'Test',
        highlights: ['1', '2', '3', '4'],
        transcript: 'Test',
        duration: 60,
      );

      final invalidSummary = VideoSummary(
        title: 'Test',
        highlights: ['1', '2', '3'], // Only 3
        transcript: 'Test',
        duration: 60,
      );

      expect(validSummary.hasValidHighlights, isTrue);
      expect(invalidSummary.hasValidHighlights, isFalse);
    });
  });

  group('EmailDraft Model', () {
    test('fromJson creates valid EmailDraft', () {
      final json = {
        'subject': 'Meeting Follow-up',
        'body': 'Thank you for the meeting...',
        'conversation_id': 'conv-123',
      };

      final draft = EmailDraft.fromJson(json);

      expect(draft.subject, equals('Meeting Follow-up'));
      expect(draft.body, equals('Thank you for the meeting...'));
      expect(draft.conversationId, equals('conv-123'));
    });

    test('formattedEmail returns proper format', () {
      final draft = EmailDraft(
        subject: 'Test Subject',
        body: 'Test body content',
        conversationId: 'conv-123',
      );

      expect(
        draft.formattedEmail,
        equals('Subject: Test Subject\n\nTest body content'),
      );
    });

    test('isValid checks for non-empty fields', () {
      final validDraft = EmailDraft(
        subject: 'Subject',
        body: 'Body',
        conversationId: 'conv-123',
      );

      final invalidDraft = EmailDraft(
        subject: '',
        body: 'Body',
        conversationId: 'conv-123',
      );

      expect(validDraft.isValid, isTrue);
      expect(invalidDraft.isValid, isFalse);
    });
  });

  group('UsageStats Model', () {
    test('fromJson creates valid UsageStats', () {
      final json = {
        'message_count': 50,
        'media_uploads': 10,
        'quota_limit': 100,
        'quota_used': 60,
        'reset_date': '2024-02-01T00:00:00.000Z',
      };

      final stats = UsageStats.fromJson(json);

      expect(stats.messageCount, equals(50));
      expect(stats.mediaUploads, equals(10));
      expect(stats.quotaLimit, equals(100));
      expect(stats.quotaUsed, equals(60));
    });

    test('calculates usage percentage correctly', () {
      final stats = UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 75,
        resetDate: DateTime.utc(2024, 2, 1),
      );

      expect(stats.usagePercentage, equals(0.75));
      expect(stats.quotaRemaining, equals(25));
    });

    test('isNearQuotaLimit returns true at 80%', () {
      final nearLimit = UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 80,
        resetDate: DateTime.utc(2024, 2, 1),
      );

      final belowLimit = UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 79,
        resetDate: DateTime.utc(2024, 2, 1),
      );

      expect(nearLimit.isNearQuotaLimit, isTrue);
      expect(belowLimit.isNearQuotaLimit, isFalse);
    });

    test('isQuotaExceeded returns true when at or over limit', () {
      final atLimit = UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 100,
        resetDate: DateTime.utc(2024, 2, 1),
      );

      final overLimit = UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 105,
        resetDate: DateTime.utc(2024, 2, 1),
      );

      expect(atLimit.isQuotaExceeded, isTrue);
      expect(overLimit.isQuotaExceeded, isTrue);
    });
  });

  group('UserSettings Model', () {
    test('fromJson creates valid UserSettings', () {
      final json = {
        'tts_enabled': true,
        'preferred_voice': 'en-US-Standard-A',
        'dark_mode': true,
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.ttsEnabled, isTrue);
      expect(settings.preferredVoice, equals('en-US-Standard-A'));
      expect(settings.darkMode, isTrue);
    });

    test('defaults are applied correctly', () {
      final settings = UserSettings();

      expect(settings.ttsEnabled, isFalse);
      expect(settings.preferredVoice, isNull);
      expect(settings.darkMode, isFalse);
    });

    test('copyWith updates specified fields', () {
      final original = UserSettings(ttsEnabled: false, darkMode: false);
      final updated = original.copyWith(ttsEnabled: true);

      expect(updated.ttsEnabled, isTrue);
      expect(updated.darkMode, isFalse);
    });
  });

  group('DetectedObject Model', () {
    test('fromJson creates valid DetectedObject with bounding box', () {
      final json = {
        'label': 'cat',
        'confidence': 0.95,
        'bounding_box': {
          'x': 10.0,
          'y': 20.0,
          'width': 100.0,
          'height': 80.0,
        },
      };

      final obj = DetectedObject.fromJson(json);

      expect(obj.label, equals('cat'));
      expect(obj.confidence, equals(0.95));
      expect(obj.boundingBox, isNotNull);
      expect(obj.boundingBox!.x, equals(10.0));
      expect(obj.boundingBox!.width, equals(100.0));
    });
  });

  group('MediaAsset Model', () {
    test('fromJson creates valid MediaAsset', () {
      final json = {
        'id': 'asset-123',
        'user_id': 'user-456',
        'conversation_id': 'conv-789',
        's3_path': 's3://bucket/path/image.png',
        'media_type': 'image',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final asset = MediaAsset.fromJson(json);

      expect(asset.id, equals('asset-123'));
      expect(asset.userId, equals('user-456'));
      expect(asset.s3Path, equals('s3://bucket/path/image.png'));
      expect(asset.mediaType, equals(MediaType.image));
    });
  });
}
