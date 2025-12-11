import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/media/widgets/image_message_bubble.dart';
import 'package:multimodal_ai_assistant/features/media/widgets/image_picker_button.dart';

void main() {
  group('ImagePickerButton', () {
    testWidgets('displays image icon when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePickerButton(
              onImagePicked: (_) {},
              enabled: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePickerButton(
              onImagePicked: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.image), findsNothing);
    });

    testWidgets('shows bottom sheet when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePickerButton(
              onImagePicked: (_) {},
              enabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.image));
      await tester.pumpAndSettle();

      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePickerButton(
              onImagePicked: (_) {},
              enabled: false,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });
  });

  group('ImageMessageBubble', () {
    testWidgets('displays caption when present', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Image message',
        type: MessageType.image,
        metadata: {
          'caption': 'A cat sitting on a couch',
        },
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageMessageBubble(message: message),
            ),
          ),
        ),
      );

      expect(find.text('A cat sitting on a couch'), findsOneWidget);
    });

    testWidgets('displays detected object labels as chips', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Image message',
        type: MessageType.image,
        metadata: {
          'caption': 'A scene',
          'objects': [
            {'label': 'cat', 'confidence': 0.95},
            {'label': 'couch', 'confidence': 0.88},
          ],
        },
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageMessageBubble(message: message),
            ),
          ),
        ),
      );

      expect(find.text('cat'), findsOneWidget);
      expect(find.text('couch'), findsOneWidget);
    });

    testWidgets('displays OCR text when present', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Image message',
        type: MessageType.image,
        metadata: {
          'caption': 'A sign',
          'ocr_text': 'Welcome to the park',
        },
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageMessageBubble(message: message),
            ),
          ),
        ),
      );

      expect(find.text('Welcome to the park'), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('displays placeholder when no image URL', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Image message',
        type: MessageType.image,
        metadata: {'caption': 'Test'},
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageMessageBubble(message: message),
            ),
          ),
        ),
      );

      // Should show placeholder icon
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('shows user avatar for user messages', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Image message',
        type: MessageType.image,
        metadata: {'caption': 'Test'},
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageMessageBubble(message: message, isUser: true),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows assistant avatar for assistant messages', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'Image message',
        type: MessageType.image,
        metadata: {'caption': 'Test'},
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageMessageBubble(message: message, isUser: false),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });
  });

  group('ImageUploadError', () {
    late File mockFile;

    setUpAll(() {
      // Create a temporary file for testing
      mockFile = File('/tmp/test_image.jpg');
    });

    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageUploadError(
                errorMessage: 'Upload failed: Network error',
                imageFile: mockFile,
                onRetry: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Upload failed: Network error'), findsOneWidget);
    });

    testWidgets('displays retry and cancel buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageUploadError(
                errorMessage: 'Upload failed',
                imageFile: mockFile,
                onRetry: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is tapped', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageUploadError(
                errorMessage: 'Upload failed',
                imageFile: mockFile,
                onRetry: () => retryCalled = true,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button is tapped', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageUploadError(
                errorMessage: 'Upload failed',
                imageFile: mockFile,
                onRetry: () {},
                onCancel: () => cancelCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelCalled, isTrue);
    });

    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImageUploadError(
                errorMessage: 'Upload failed',
                imageFile: mockFile,
                onRetry: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
