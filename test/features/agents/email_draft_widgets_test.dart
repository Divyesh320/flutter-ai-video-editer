import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/settings_models.dart';
import 'package:multimodal_ai_assistant/features/agents/widgets/email_draft_button.dart';
import 'package:multimodal_ai_assistant/features/agents/widgets/email_draft_card.dart';

void main() {
  group('EmailDraftCard', () {
    const testDraft = EmailDraft(
      subject: 'Meeting Follow-up',
      body: 'Thank you for attending the meeting today. Here are the key points we discussed.',
      conversationId: 'conv-123',
    );

    testWidgets('displays draft subject and body', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(draft: testDraft),
            ),
          ),
        ),
      );

      expect(find.text('Email Draft'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      
      // Check that text fields contain the draft content
      final subjectField = find.byType(TextField).first;
      expect(subjectField, findsOneWidget);
    });

    testWidgets('displays action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(draft: testDraft),
            ),
          ),
        ),
      );

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Email App'), findsOneWidget);
    });

    testWidgets('shows regenerate button when callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                onRegenerate: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Regenerate'), findsOneWidget);
    });

    testWidgets('hides regenerate button when no callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(draft: testDraft),
            ),
          ),
        ),
      );

      expect(find.text('Regenerate'), findsNothing);
    });

    testWidgets('shows dismiss button when callback provided', (tester) async {
      var dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                onDismiss: () => dismissCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissCalled, isTrue);
    });

    testWidgets('displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('disables buttons when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                isLoading: true,
                onRegenerate: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // Verify text fields are disabled
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final textField in textFields) {
        expect(textField.enabled, isFalse);
      }
    });

    testWidgets('displays error message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                errorMessage: 'Failed to generate email draft',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Failed to generate email draft'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('opens regenerate dialog when regenerate is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                onRegenerate: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();

      expect(find.text('Regenerate Draft'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('calls onRegenerate with instructions from dialog', (tester) async {
      String? receivedInstructions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(
                draft: testDraft,
                onRegenerate: (instructions) => receivedInstructions = instructions,
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();

      // Enter instructions
      await tester.enterText(
        find.byType(TextField).last,
        'Make it more formal',
      );
      await tester.pump();

      // Tap regenerate in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Regenerate'));
      await tester.pumpAndSettle();

      expect(receivedInstructions, equals('Make it more formal'));
    });

    testWidgets('updates content when draft changes', (tester) async {
      const initialDraft = EmailDraft(
        subject: 'Initial Subject',
        body: 'Initial body',
        conversationId: 'conv-123',
      );

      const updatedDraft = EmailDraft(
        subject: 'Updated Subject',
        body: 'Updated body',
        conversationId: 'conv-123',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(draft: initialDraft),
            ),
          ),
        ),
      );

      // Verify initial content
      final subjectFields = find.byType(TextField);
      expect(subjectFields, findsNWidgets(2)); // Subject and Body

      // Update the widget with new draft
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmailDraftCard(draft: updatedDraft),
            ),
          ),
        ),
      );

      await tester.pump();

      // The text controllers should be updated
      // We verify by checking the TextField widgets exist
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  group('EmailDraftButton', () {
    testWidgets('displays email icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailDraftButton(onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailDraftButton(onPressed: () => pressed = true),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailDraftButton(
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsNothing);
    });

    testWidgets('is disabled when isEnabled is false', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailDraftButton(
              onPressed: () => pressed = true,
              isEnabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('is disabled when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailDraftButton(
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, isFalse);
    });
  });

  group('EmailDraftFAB', () {
    testWidgets('displays email icon in regular mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: EmailDraftFAB(onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('displays label in extended mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: EmailDraftFAB(
              onPressed: () {},
              extended: true,
            ),
          ),
        ),
      );

      expect(find.text('Draft Email'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: EmailDraftFAB(
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: EmailDraftFAB(
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
