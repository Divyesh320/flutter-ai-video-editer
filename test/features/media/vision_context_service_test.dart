import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/media/services/vision_context_service.dart';

void main() {
  late VisionContextService service;

  setUp(() {
    service = const VisionContextService();
  });

  group('VisionContextService', () {
    test('buildVisionContext returns null for empty messages', () {
      final context = service.buildVisionContext([]);
      expect(context, isNull);
    });

    test('buildVisionContext returns null for text-only messages', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Hello',
          type: MessageType.text,
          createdAt: DateTime.now(),
        ),
      ];

      final context = service.buildVisionContext(messages);
      expect(context, isNull);
    });

    test('buildVisionContext includes caption from image message', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Check this image',
          type: MessageType.image,
          metadata: {
            'caption': 'A cat sitting on a couch',
          },
          createdAt: DateTime.now(),
        ),
      ];

      final context = service.buildVisionContext(messages);
      
      expect(context, isNotNull);
      expect(context, contains('Image Caption: A cat sitting on a couch'));
    });

    test('buildVisionContext includes detected objects', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Check this image',
          type: MessageType.image,
          metadata: {
            'caption': 'A scene',
            'objects': [
              {'label': 'cat', 'confidence': 0.95},
              {'label': 'couch', 'confidence': 0.88},
            ],
          },
          createdAt: DateTime.now(),
        ),
      ];

      final context = service.buildVisionContext(messages);
      
      expect(context, isNotNull);
      expect(context, contains('Detected Objects: cat, couch'));
    });

    test('buildVisionContext includes OCR text', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Check this image',
          type: MessageType.image,
          metadata: {
            'caption': 'A sign',
            'ocr_text': 'Welcome to the park',
          },
          createdAt: DateTime.now(),
        ),
      ];

      final context = service.buildVisionContext(messages);
      
      expect(context, isNotNull);
      expect(context, contains('Text in Image (OCR): Welcome to the park'));
    });

    /// **Feature: multimodal-ai-assistant, Property 10: Vision Context Inclusion**
    /// **Validates: Requirements 4.4**
    test('property: vision context always includes caption when present (100 iterations)', () {
      final random = Random(42);
      final captions = [
        'A cat sitting on a couch',
        'A dog running in the park',
        'A person reading a book',
        'A car parked on the street',
        'A beautiful sunset over the ocean',
      ];

      for (var i = 0; i < 100; i++) {
        final caption = captions[random.nextInt(captions.length)];
        
        final messages = [
          Message(
            id: 'msg-${random.nextInt(10000)}',
            conversationId: 'conv-1',
            role: MessageRole.user,
            content: 'Image message',
            type: MessageType.image,
            metadata: {
              'caption': caption,
            },
            createdAt: DateTime.now(),
          ),
        ];

        final context = service.buildVisionContext(messages);
        
        expect(context, isNotNull,
            reason: 'Context should not be null when caption is present');
        expect(context!.contains(caption), isTrue,
            reason: 'Context should contain the caption: $caption');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 10: Vision Context Inclusion**
    /// **Validates: Requirements 4.4**
    test('property: vision context always includes labels when present (100 iterations)', () {
      final random = Random(42);
      final allLabels = ['cat', 'dog', 'person', 'car', 'tree', 'building', 'phone', 'book'];

      for (var i = 0; i < 100; i++) {
        // Generate random labels
        final labelCount = 1 + random.nextInt(5);
        final selectedLabels = <String>[];
        for (var j = 0; j < labelCount; j++) {
          final label = allLabels[random.nextInt(allLabels.length)];
          if (!selectedLabels.contains(label)) {
            selectedLabels.add(label);
          }
        }

        final objects = selectedLabels.map((label) {
          return {'label': label, 'confidence': 0.7 + random.nextDouble() * 0.3};
        }).toList();

        final messages = [
          Message(
            id: 'msg-${random.nextInt(10000)}',
            conversationId: 'conv-1',
            role: MessageRole.user,
            content: 'Image message',
            type: MessageType.image,
            metadata: {
              'caption': 'Test caption',
              'objects': objects,
            },
            createdAt: DateTime.now(),
          ),
        ];

        final context = service.buildVisionContext(messages);
        
        expect(context, isNotNull,
            reason: 'Context should not be null when labels are present');
        
        // Verify all labels are included
        for (final label in selectedLabels) {
          expect(context!.contains(label), isTrue,
              reason: 'Context should contain label: $label');
        }
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 10: Vision Context Inclusion**
    /// **Validates: Requirements 4.4**
    test('property: vision context always includes OCR text when present (100 iterations)', () {
      final random = Random(42);
      final ocrTexts = [
        'Welcome to the park',
        'Stop sign',
        'Open 24 hours',
        'Sale 50% off',
        'No parking',
        'Exit',
        'Enter here',
      ];

      for (var i = 0; i < 100; i++) {
        final ocrText = ocrTexts[random.nextInt(ocrTexts.length)];
        
        final messages = [
          Message(
            id: 'msg-${random.nextInt(10000)}',
            conversationId: 'conv-1',
            role: MessageRole.user,
            content: 'Image message',
            type: MessageType.image,
            metadata: {
              'caption': 'Test caption',
              'ocr_text': ocrText,
            },
            createdAt: DateTime.now(),
          ),
        ];

        final context = service.buildVisionContext(messages);
        
        expect(context, isNotNull,
            reason: 'Context should not be null when OCR text is present');
        expect(context!.contains(ocrText), isTrue,
            reason: 'Context should contain OCR text: $ocrText');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 10: Vision Context Inclusion**
    /// **Validates: Requirements 4.4**
    test('property: vision context includes all three components when all present (100 iterations)', () {
      final random = Random(42);
      final captions = ['A cat', 'A dog', 'A person', 'A car'];
      final labels = ['cat', 'dog', 'person', 'car', 'tree'];
      final ocrTexts = ['Hello', 'Welcome', 'Stop', 'Go'];

      for (var i = 0; i < 100; i++) {
        final caption = captions[random.nextInt(captions.length)];
        final selectedLabels = [
          labels[random.nextInt(labels.length)],
          labels[random.nextInt(labels.length)],
        ].toSet().toList(); // Remove duplicates
        final ocrText = ocrTexts[random.nextInt(ocrTexts.length)];

        final objects = selectedLabels.map((label) {
          return {'label': label, 'confidence': 0.85};
        }).toList();

        final messages = [
          Message(
            id: 'msg-${random.nextInt(10000)}',
            conversationId: 'conv-1',
            role: MessageRole.user,
            content: 'Image message',
            type: MessageType.image,
            metadata: {
              'caption': caption,
              'objects': objects,
              'ocr_text': ocrText,
            },
            createdAt: DateTime.now(),
          ),
        ];

        final context = service.buildVisionContext(messages);
        
        expect(context, isNotNull,
            reason: 'Context should not be null');
        expect(context!.contains(caption), isTrue,
            reason: 'Context should contain caption');
        for (final label in selectedLabels) {
          expect(context.contains(label), isTrue,
              reason: 'Context should contain label: $label');
        }
        expect(context.contains(ocrText), isTrue,
            reason: 'Context should contain OCR text');
      }
    });
  });

  group('hasImageContext', () {
    test('returns false for empty messages', () {
      expect(service.hasImageContext([]), isFalse);
    });

    test('returns false for text-only messages', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Hello',
          type: MessageType.text,
          createdAt: DateTime.now(),
        ),
      ];

      expect(service.hasImageContext(messages), isFalse);
    });

    test('returns true for image messages with metadata', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Image',
          type: MessageType.image,
          metadata: {'caption': 'A cat'},
          createdAt: DateTime.now(),
        ),
      ];

      expect(service.hasImageContext(messages), isTrue);
    });
  });

  group('getMostRecentImageContext', () {
    test('returns null for empty messages', () {
      expect(service.getMostRecentImageContext([]), isNull);
    });

    test('returns most recent image context', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'First image',
          type: MessageType.image,
          metadata: {'caption': 'First caption'},
          createdAt: DateTime.now().subtract(Duration(hours: 1)),
        ),
        Message(
          id: 'msg-2',
          conversationId: 'conv-1',
          role: MessageRole.user,
          content: 'Second image',
          type: MessageType.image,
          metadata: {'caption': 'Second caption'},
          createdAt: DateTime.now(),
        ),
      ];

      final context = service.getMostRecentImageContext(messages);
      
      expect(context, isNotNull);
      expect(context!.caption, equals('Second caption'));
    });
  });

  group('ImageContextData', () {
    test('hasData returns true when caption is present', () {
      final data = ImageContextData(caption: 'A cat');
      expect(data.hasData, isTrue);
    });

    test('hasData returns true when labels are present', () {
      final data = ImageContextData(labels: ['cat', 'dog']);
      expect(data.hasData, isTrue);
    });

    test('hasData returns true when OCR text is present', () {
      final data = ImageContextData(ocrText: 'Hello');
      expect(data.hasData, isTrue);
    });

    test('hasData returns false when all fields are empty', () {
      final data = ImageContextData();
      expect(data.hasData, isFalse);
    });

    test('toContextString formats all components', () {
      final data = ImageContextData(
        caption: 'A cat on a couch',
        labels: ['cat', 'couch'],
        ocrText: 'Welcome',
      );

      final contextString = data.toContextString();
      
      expect(contextString, contains('Caption: A cat on a couch'));
      expect(contextString, contains('Detected Objects: cat, couch'));
      expect(contextString, contains('Text in Image: Welcome'));
    });
  });
}
