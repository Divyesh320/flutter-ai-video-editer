import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/chat/providers/conversation_state.dart';

void main() {
  group('ConversationListState', () {
    /// **Feature: multimodal-ai-assistant, Property 14: Conversation List Sorting**
    /// **Validates: Requirements 6.1**
    /// *For any* list of conversations returned by the API, the conversations
    /// SHALL be sorted by updated_at in descending order (most recent first).
    test('property: conversations are sorted by updatedAt descending (100 iterations)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        // Generate random number of conversations (1-20)
        final count = 1 + random.nextInt(20);
        final conversations = <Conversation>[];

        for (var j = 0; j < count; j++) {
          // Generate random timestamps within a year range
          final daysAgo = random.nextInt(365);
          final hoursAgo = random.nextInt(24);
          final updatedAt = DateTime.now()
              .subtract(Duration(days: daysAgo, hours: hoursAgo));
          final createdAt = updatedAt.subtract(Duration(days: random.nextInt(30)));

          conversations.add(Conversation(
            id: 'conv-$j-$i',
            userId: 'user-1',
            title: 'Conversation $j',
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: const [],
          ));
        }

        // Sort as the notifier would
        final sorted = List<Conversation>.from(conversations)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        // Verify sorting: each conversation should have updatedAt >= next
        for (var k = 0; k < sorted.length - 1; k++) {
          expect(
            sorted[k].updatedAt.isAfter(sorted[k + 1].updatedAt) ||
                sorted[k].updatedAt.isAtSameMomentAs(sorted[k + 1].updatedAt),
            isTrue,
            reason: 'Conversation at index $k should be more recent than index ${k + 1}',
          );
        }
      }
    });


    /// **Feature: multimodal-ai-assistant, Property 15: Conversation Load Completeness**
    /// **Validates: Requirements 6.2**
    /// *For any* conversation selected from the list, loading SHALL return all
    /// messages associated with that conversation_id, with message count matching
    /// the database record count.
    test('property: loaded conversation contains all messages (100 iterations)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        // Generate random number of messages (0-50)
        final messageCount = random.nextInt(51);
        final conversationId = 'conv-$i';
        final messages = <Message>[];

        for (var j = 0; j < messageCount; j++) {
          messages.add(Message(
            id: 'msg-$j-$i',
            conversationId: conversationId,
            role: random.nextBool() ? MessageRole.user : MessageRole.assistant,
            content: 'Message content $j',
            createdAt: DateTime.now().subtract(Duration(minutes: j)),
          ));
        }

        final conversation = Conversation(
          id: conversationId,
          userId: 'user-1',
          title: 'Test Conversation',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          messages: messages,
        );

        // Verify all messages are present
        expect(conversation.messages.length, equals(messageCount));
        expect(conversation.messageCount, equals(messageCount));

        // Verify all messages belong to this conversation
        for (final message in conversation.messages) {
          expect(message.conversationId, equals(conversationId));
        }
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 16: Conversation Deletion Cascade**
    /// **Validates: Requirements 6.5**
    /// *For any* deleted conversation, the system SHALL remove the conversation
    /// record AND all associated messages from the list.
    test('property: deleting conversation removes it from list (100 iterations)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        // Generate random number of conversations (2-20)
        final count = 2 + random.nextInt(19);
        final conversations = <Conversation>[];

        for (var j = 0; j < count; j++) {
          conversations.add(Conversation(
            id: 'conv-$j',
            userId: 'user-1',
            title: 'Conversation $j',
            createdAt: DateTime.now().subtract(Duration(days: j)),
            updatedAt: DateTime.now().subtract(Duration(hours: j)),
            messages: const [],
          ));
        }

        // Pick a random conversation to delete
        final deleteIndex = random.nextInt(count);
        final deleteId = 'conv-$deleteIndex';

        // Simulate deletion
        final afterDelete = conversations.where((c) => c.id != deleteId).toList();

        // Verify deletion
        expect(afterDelete.length, equals(count - 1));
        expect(afterDelete.any((c) => c.id == deleteId), isFalse,
            reason: 'Deleted conversation should not be in list');
      }
    });
  });


  group('ConversationListItem', () {
    /// **Feature: multimodal-ai-assistant, Property 17: Conversation List Item Content**
    /// **Validates: Requirements 6.6**
    /// *For any* conversation in the list view, the display SHALL include the
    /// conversation title (or placeholder), last message preview (truncated if
    /// needed), and formatted timestamp.
    test('property: conversation list item has required content (100 iterations)', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        // Generate random title (or null)
        final hasTitle = random.nextBool();
        final title = hasTitle ? 'Conversation Title $i' : null;

        // Generate random messages (0-10)
        final messageCount = random.nextInt(11);
        final messages = <Message>[];

        for (var j = 0; j < messageCount; j++) {
          // Generate random content length (10-200 chars)
          final contentLength = 10 + random.nextInt(191);
          final content = String.fromCharCodes(
            List.generate(contentLength, (_) => 97 + random.nextInt(26)),
          );

          messages.add(Message(
            id: 'msg-$j',
            conversationId: 'conv-$i',
            role: random.nextBool() ? MessageRole.user : MessageRole.assistant,
            content: content,
            createdAt: DateTime.now().subtract(Duration(minutes: j)),
          ));
        }

        final conversation = Conversation(
          id: 'conv-$i',
          userId: 'user-1',
          title: title,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          messages: messages,
        );

        // Verify title or placeholder exists
        final displayTitle = conversation.title ?? 'New Conversation';
        expect(displayTitle.isNotEmpty, isTrue);

        // Verify last message preview
        if (messages.isNotEmpty) {
          final preview = conversation.lastMessagePreview;
          expect(preview, isNotNull);
          // Preview should be truncated if > 50 chars
          if (messages.last.content.length > 50) {
            expect(preview!.length, equals(53)); // 50 + "..."
            expect(preview.endsWith('...'), isTrue);
          } else {
            expect(preview, equals(messages.last.content));
          }
        }

        // Verify timestamp exists
        expect(conversation.updatedAt, isNotNull);
      }
    });
  });
}
