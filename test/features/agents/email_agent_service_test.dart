import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/settings_models.dart';
import 'package:multimodal_ai_assistant/features/agents/utils/clipboard_utils.dart';

void main() {
  group('EmailDraft Model', () {
    group('JSON Serialization', () {
      test('fromJson creates valid EmailDraft', () {
        final json = {
          'subject': 'Meeting Follow-up',
          'body': 'Thank you for attending the meeting.',
          'conversation_id': 'conv-123',
        };

        final draft = EmailDraft.fromJson(json);

        expect(draft.subject, equals('Meeting Follow-up'));
        expect(draft.body, equals('Thank you for attending the meeting.'));
        expect(draft.conversationId, equals('conv-123'));
      });

      test('toJson produces valid JSON', () {
        const draft = EmailDraft(
          subject: 'Project Update',
          body: 'Here is the latest update on the project.',
          conversationId: 'conv-456',
        );

        final json = draft.toJson();

        expect(json['subject'], equals('Project Update'));
        expect(json['body'], equals('Here is the latest update on the project.'));
        expect(json['conversation_id'], equals('conv-456'));
      });
    });

    group('Validation', () {
      test('isValid returns true for valid draft', () {
        const draft = EmailDraft(
          subject: 'Test Subject',
          body: 'Test body content',
          conversationId: 'conv-123',
        );

        expect(draft.isValid, isTrue);
      });

      test('isValid returns false for empty subject', () {
        const draft = EmailDraft(
          subject: '',
          body: 'Test body content',
          conversationId: 'conv-123',
        );

        expect(draft.isValid, isFalse);
      });

      test('isValid returns false for empty body', () {
        const draft = EmailDraft(
          subject: 'Test Subject',
          body: '',
          conversationId: 'conv-123',
        );

        expect(draft.isValid, isFalse);
      });
    });

    group('Formatted Email', () {
      test('formattedEmail combines subject and body', () {
        const draft = EmailDraft(
          subject: 'Important Notice',
          body: 'Please review the attached document.',
          conversationId: 'conv-123',
        );

        expect(
          draft.formattedEmail,
          equals('Subject: Important Notice\n\nPlease review the attached document.'),
        );
      });
    });

    /// **Feature: multimodal-ai-assistant, Property 18: Email Draft Structure**
    /// **Validates: Requirements 7.2**
    test('Property 18: Email draft structure validation (property test)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final subjectLength = random.nextInt(100) + 1;
        final bodyLength = random.nextInt(500) + 1;

        final subject = _generateRandomString(random, subjectLength);
        final body = _generateRandomString(random, bodyLength);
        final conversationId = 'conv-${random.nextInt(10000)}';

        final draft = EmailDraft(
          subject: subject,
          body: body,
          conversationId: conversationId,
        );

        expect(draft.isValid, isTrue,
            reason: 'Draft with non-empty subject and body should be valid');
        expect(draft.subject.isNotEmpty, isTrue,
            reason: 'Subject should be non-empty');
        expect(draft.body.isNotEmpty, isTrue,
            reason: 'Body should be non-empty');

        final json = draft.toJson();
        final restored = EmailDraft.fromJson(json);

        expect(restored.isValid, equals(draft.isValid),
            reason: 'Validity should be preserved after serialization');
        expect(restored.subject, equals(draft.subject),
            reason: 'Subject should be preserved');
        expect(restored.body, equals(draft.body),
            reason: 'Body should be preserved');
      }
    });

    test('Property 18: Invalid drafts are correctly rejected (property test)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final conversationId = 'conv-${random.nextInt(10000)}';

        final emptySubjectDraft = EmailDraft(
          subject: '',
          body: _generateRandomString(random, random.nextInt(100) + 1),
          conversationId: conversationId,
        );
        expect(emptySubjectDraft.isValid, isFalse,
            reason: 'Draft with empty subject should be invalid');

        final emptyBodyDraft = EmailDraft(
          subject: _generateRandomString(random, random.nextInt(100) + 1),
          body: '',
          conversationId: conversationId,
        );
        expect(emptyBodyDraft.isValid, isFalse,
            reason: 'Draft with empty body should be invalid');

        const bothEmptyDraft = EmailDraft(
          subject: '',
          body: '',
          conversationId: 'conv-123',
        );
        expect(bothEmptyDraft.isValid, isFalse,
            reason: 'Draft with both empty should be invalid');
      }
    });
  });

  group('EmailClipboardUtils', () {
    /// **Feature: multimodal-ai-assistant, Property 19: Clipboard Copy Verification**
    /// **Validates: Requirements 7.3**
    test('Property 19: Clipboard copy verification (property test)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final subjectLength = random.nextInt(100) + 1;
        final bodyLength = random.nextInt(500) + 1;

        final subject = _generateRandomString(random, subjectLength);
        final body = _generateRandomString(random, bodyLength);
        final conversationId = 'conv-${random.nextInt(10000)}';

        final draft = EmailDraft(
          subject: subject,
          body: body,
          conversationId: conversationId,
        );

        final formattedEmail = draft.formattedEmail;

        expect(formattedEmail.contains(subject), isTrue,
            reason: 'Formatted email should contain the exact subject');
        expect(formattedEmail.contains(body), isTrue,
            reason: 'Formatted email should contain the exact body');
        expect(formattedEmail, equals('Subject: $subject\n\n$body'),
            reason: 'Formatted email should follow expected format');

        final lines = formattedEmail.split('\n\n');
        expect(lines.length, greaterThanOrEqualTo(2));
        expect(lines[0], equals('Subject: $subject'));
        expect(lines.sublist(1).join('\n\n'), equals(body));
      }
    });

    test('Property 19: ClipboardCopyResult correctly reports state (property test)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final content = _generateRandomString(random, random.nextInt(200) + 1);

        final successResult = ClipboardCopyResult.success(content);
        expect(successResult.success, isTrue);
        expect(successResult.copiedContent, equals(content));
        expect(successResult.errorMessage, isNull);

        final errorMessage = 'Error ${random.nextInt(100)}';
        final failureResult = ClipboardCopyResult.failure(errorMessage);
        expect(failureResult.success, isFalse);
        expect(failureResult.copiedContent, isEmpty);
        expect(failureResult.errorMessage, equals(errorMessage));
      }
    });
  });
}

String _generateRandomString(Random random, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
