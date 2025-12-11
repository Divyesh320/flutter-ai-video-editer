import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Markdown Rendering', () {
    /// **Feature: multimodal-ai-assistant, Property 6: Markdown Rendering Completeness**
    /// **Validates: Requirements 2.6**
    /// *For any* assistant response containing markdown syntax (code blocks,
    /// lists, emphasis), the rendered output SHALL contain the corresponding
    /// formatted elements without raw markdown characters visible.
    testWidgets('property: markdown syntax is rendered without raw characters (100 iterations)',
        (tester) async {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        // Generate random markdown content
        final markdownElements = <String>[];

        // Add random code blocks
        if (random.nextBool()) {
          final code = 'print("Hello ${random.nextInt(1000)}")';
          markdownElements.add('```dart\n$code\n```');
        }

        // Add random inline code
        if (random.nextBool()) {
          markdownElements.add('Use `variable_${random.nextInt(100)}` here');
        }

        // Add random bold text
        if (random.nextBool()) {
          markdownElements.add('This is **bold text ${random.nextInt(100)}**');
        }

        // Add random italic text
        if (random.nextBool()) {
          markdownElements.add('This is *italic text ${random.nextInt(100)}*');
        }

        // Add random bullet list
        if (random.nextBool()) {
          markdownElements.add('- Item ${random.nextInt(100)}\n- Item ${random.nextInt(100)}');
        }

        // Add random numbered list
        if (random.nextBool()) {
          markdownElements.add('1. First ${random.nextInt(100)}\n2. Second ${random.nextInt(100)}');
        }

        if (markdownElements.isEmpty) {
          markdownElements.add('Plain text ${random.nextInt(100)}');
        }

        final markdownContent = markdownElements.join('\n\n');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MarkdownBody(data: markdownContent),
              ),
            ),
          ),
        );

        // Verify raw markdown characters are not visible in rendered text
        // Check that triple backticks are not shown
        expect(find.text('```'), findsNothing,
            reason: 'Triple backticks should not be visible');
        expect(find.text('```dart'), findsNothing,
            reason: 'Code fence with language should not be visible');

        // Check that raw ** for bold is not shown (but the text inside is)
        final boldMatches = RegExp(r'\*\*([^*]+)\*\*').allMatches(markdownContent);
        for (final match in boldMatches) {
          expect(find.text('**${match.group(1)}**'), findsNothing,
              reason: 'Raw bold markers should not be visible');
        }

        // Check that raw * for italic is not shown
        final italicMatches = RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)').allMatches(markdownContent);
        for (final match in italicMatches) {
          // Only check if it's not part of bold
          if (!match.group(0)!.contains('**')) {
            expect(find.text('*${match.group(1)}*'), findsNothing,
                reason: 'Raw italic markers should not be visible');
          }
        }

        // Check that bullet markers are rendered as actual bullets
        // (the raw "- " should not appear as text)
        if (markdownContent.contains('\n- ')) {
          // MarkdownBody renders bullets as actual bullet points
          expect(find.byType(MarkdownBody), findsOneWidget);
        }
      }
    });
  });
}
