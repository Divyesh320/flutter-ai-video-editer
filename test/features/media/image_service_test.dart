import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/core/models/models.dart';
import 'package:multimodal_ai_assistant/features/media/services/image_service.dart';

void main() {
  group('ImageUploadResponse', () {
    test('fromJson creates valid response', () {
      final json = {
        'image_id': 'img-123',
        'image_url': 'https://storage.example.com/images/img-123.jpg',
        'analysis': {
          'caption': 'A cat sitting on a couch',
          'objects': [
            {'label': 'cat', 'confidence': 0.95},
            {'label': 'couch', 'confidence': 0.88},
          ],
          'ocr_text': null,
        },
      };

      final response = ImageUploadResponse.fromJson(json);

      expect(response.imageId, equals('img-123'));
      expect(response.imageUrl, equals('https://storage.example.com/images/img-123.jpg'));
      expect(response.analysis.caption, equals('A cat sitting on a couch'));
      expect(response.analysis.objects.length, equals(2));
    });

    test('toJson produces valid JSON', () {
      final response = ImageUploadResponse(
        imageId: 'img-456',
        imageUrl: 'https://storage.example.com/images/img-456.jpg',
        analysis: ImageAnalysis(
          caption: 'A dog in a park',
          objects: [
            DetectedObject(label: 'dog', confidence: 0.92),
          ],
        ),
      );

      final json = response.toJson();

      expect(json['image_id'], equals('img-456'));
      expect(json['image_url'], equals('https://storage.example.com/images/img-456.jpg'));
      expect(json['analysis']['caption'], equals('A dog in a park'));
    });
  });

  group('ImageAnalysis', () {
    /// **Feature: multimodal-ai-assistant, Property 9: Image Upload and Analysis Pipeline**
    /// **Validates: Requirements 4.1, 4.2**
    test('property: valid ImageAnalysis always has non-empty caption (100 iterations)', () {
      final random = Random(42);
      final words = ['cat', 'dog', 'person', 'car', 'tree', 'building', 'sky', 'grass'];
      final actions = ['sitting', 'standing', 'running', 'walking', 'lying'];
      final locations = ['on a couch', 'in a park', 'near a tree', 'by the road', 'in the sky'];

      for (var i = 0; i < 100; i++) {
        // Generate random caption
        final subject = words[random.nextInt(words.length)];
        final action = actions[random.nextInt(actions.length)];
        final location = locations[random.nextInt(locations.length)];
        final caption = 'A $subject $action $location';

        // Generate random objects
        final objectCount = 1 + random.nextInt(5);
        final objects = List.generate(objectCount, (j) {
          return DetectedObject(
            label: words[random.nextInt(words.length)],
            confidence: 0.5 + random.nextDouble() * 0.5, // 0.5 to 1.0
          );
        });

        // Create ImageAnalysis
        final analysis = ImageAnalysis(
          caption: caption,
          objects: objects,
          ocrText: random.nextBool() ? 'Some text' : null,
        );

        // Property: caption is always non-empty
        expect(analysis.caption.isNotEmpty, isTrue,
            reason: 'ImageAnalysis should always have non-empty caption');

        // Property: objects list exists (may be empty but not null)
        expect(analysis.objects, isNotNull,
            reason: 'ImageAnalysis should always have objects list');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 9: Image Upload and Analysis Pipeline**
    /// **Validates: Requirements 4.1, 4.2**
    test('property: ImageUploadResponse round-trip preserves all fields (100 iterations)', () {
      final random = Random(42);
      final words = ['cat', 'dog', 'person', 'car', 'tree', 'building'];

      for (var i = 0; i < 100; i++) {
        // Generate random image ID
        final imageId = 'img-${random.nextInt(100000)}';
        final imageUrl = 'https://storage.example.com/images/$imageId.jpg';

        // Generate random caption
        final caption = 'A ${words[random.nextInt(words.length)]} in the image';

        // Generate random objects
        final objectCount = random.nextInt(5);
        final objects = List.generate(objectCount, (j) {
          return DetectedObject(
            label: words[random.nextInt(words.length)],
            confidence: (50 + random.nextInt(50)) / 100.0, // 0.50 to 0.99
          );
        });

        // Create original response
        final original = ImageUploadResponse(
          imageId: imageId,
          imageUrl: imageUrl,
          analysis: ImageAnalysis(
            caption: caption,
            objects: objects,
            ocrText: random.nextBool() ? 'OCR text ${random.nextInt(100)}' : null,
          ),
        );

        // Round-trip through JSON
        final json = original.toJson();
        final restored = ImageUploadResponse.fromJson(json);

        // Verify all fields preserved
        expect(restored.imageId, equals(original.imageId),
            reason: 'imageId should be preserved');
        expect(restored.imageUrl, equals(original.imageUrl),
            reason: 'imageUrl should be preserved');
        expect(restored.analysis.caption, equals(original.analysis.caption),
            reason: 'caption should be preserved');
        expect(restored.analysis.objects.length, equals(original.analysis.objects.length),
            reason: 'objects count should be preserved');
        expect(restored.analysis.ocrText, equals(original.analysis.ocrText),
            reason: 'ocrText should be preserved');

        // Verify each object preserved
        for (var j = 0; j < original.analysis.objects.length; j++) {
          expect(restored.analysis.objects[j].label,
              equals(original.analysis.objects[j].label),
              reason: 'object label should be preserved');
          expect(restored.analysis.objects[j].confidence,
              equals(original.analysis.objects[j].confidence),
              reason: 'object confidence should be preserved');
        }
      }
    });
  });

  group('createMessageFromImage', () {
    test('creates valid message with image metadata', () {
      final response = ImageUploadResponse(
        imageId: 'img-123',
        imageUrl: 'https://storage.example.com/images/img-123.jpg',
        analysis: ImageAnalysis(
          caption: 'A cat on a couch',
          objects: [
            DetectedObject(label: 'cat', confidence: 0.95),
            DetectedObject(label: 'couch', confidence: 0.88),
            DetectedObject(label: 'pillow', confidence: 0.65), // Below threshold
          ],
          ocrText: 'Welcome',
        ),
      );

      final message = createMessageFromImage(
        imageResponse: response,
        conversationId: 'conv-456',
      );

      expect(message.id, equals('img-123'));
      expect(message.conversationId, equals('conv-456'));
      expect(message.role, equals(MessageRole.user));
      expect(message.type, equals(MessageType.image));
      expect(message.content, equals('A cat on a couch'));
      expect(message.metadata!['caption'], equals('A cat on a couch'));
      expect(message.metadata!['ocr_text'], equals('Welcome'));
      
      // Only filtered objects (>= 0.70) should be in metadata
      final objects = message.metadata!['objects'] as List;
      expect(objects.length, equals(2)); // cat and couch, not pillow
    });

    test('uses custom caption when provided', () {
      final response = ImageUploadResponse(
        imageId: 'img-123',
        imageUrl: 'https://storage.example.com/images/img-123.jpg',
        analysis: ImageAnalysis(
          caption: 'Auto-generated caption',
          objects: [],
        ),
      );

      final message = createMessageFromImage(
        imageResponse: response,
        conversationId: 'conv-456',
        userCaption: 'What is in this image?',
      );

      expect(message.content, equals('What is in this image?'));
      expect(message.metadata!['caption'], equals('Auto-generated caption'));
    });
  });

  group('ImageException', () {
    test('toString returns formatted message', () {
      const exception = ImageException('Test error message');
      expect(exception.toString(), equals('ImageException: Test error message'));
    });
  });

  group('Object Detection Confidence Filtering', () {
    /// **Feature: multimodal-ai-assistant, Property 11: Object Detection Confidence Filtering**
    /// **Validates: Requirements 4.6**
    test('property: filteredObjects only includes objects with confidence >= 0.70 (100 iterations)', () {
      final random = Random(42);
      final labels = ['cat', 'dog', 'person', 'car', 'tree', 'building', 'bird', 'phone'];

      for (var i = 0; i < 100; i++) {
        // Generate random objects with various confidence levels
        final objectCount = 1 + random.nextInt(10);
        final objects = List.generate(objectCount, (j) {
          return DetectedObject(
            label: labels[random.nextInt(labels.length)],
            confidence: random.nextDouble(), // 0.0 to 1.0
          );
        });

        final analysis = ImageAnalysis(
          caption: 'Test caption',
          objects: objects,
        );

        final filtered = analysis.filteredObjects;

        // Property: All filtered objects have confidence >= 0.70
        for (final obj in filtered) {
          expect(obj.confidence >= 0.70, isTrue,
              reason: 'Filtered object ${obj.label} has confidence ${obj.confidence} which is below 0.70');
        }

        // Property: No objects with confidence >= 0.70 are excluded
        final expectedCount = objects.where((o) => o.confidence >= 0.70).length;
        expect(filtered.length, equals(expectedCount),
            reason: 'Expected $expectedCount objects with confidence >= 0.70, got ${filtered.length}');
      }
    });

    /// **Feature: multimodal-ai-assistant, Property 11: Object Detection Confidence Filtering**
    /// **Validates: Requirements 4.6**
    test('property: objects below 0.70 threshold are always excluded (100 iterations)', () {
      final random = Random(42);
      final labels = ['cat', 'dog', 'person', 'car', 'tree'];

      for (var i = 0; i < 100; i++) {
        // Generate objects with confidence below threshold
        final lowConfidenceCount = 1 + random.nextInt(5);
        final lowConfidenceObjects = List.generate(lowConfidenceCount, (j) {
          return DetectedObject(
            label: labels[random.nextInt(labels.length)],
            confidence: random.nextDouble() * 0.69, // 0.0 to 0.69
          );
        });

        // Generate objects with confidence at or above threshold
        final highConfidenceCount = random.nextInt(5);
        final highConfidenceObjects = List.generate(highConfidenceCount, (j) {
          return DetectedObject(
            label: labels[random.nextInt(labels.length)],
            confidence: 0.70 + random.nextDouble() * 0.30, // 0.70 to 1.0
          );
        });

        final allObjects = [...lowConfidenceObjects, ...highConfidenceObjects];
        allObjects.shuffle(random);

        final analysis = ImageAnalysis(
          caption: 'Test caption',
          objects: allObjects,
        );

        final filtered = analysis.filteredObjects;

        // Property: Filtered count equals high confidence count
        expect(filtered.length, equals(highConfidenceCount),
            reason: 'Expected $highConfidenceCount high-confidence objects, got ${filtered.length}');

        // Property: No low confidence objects in filtered list
        for (final obj in filtered) {
          expect(obj.confidence >= 0.70, isTrue,
              reason: 'Low confidence object ${obj.label} (${obj.confidence}) should not be in filtered list');
        }
      }
    });

    test('boundary case: exactly 0.70 confidence is included', () {
      final analysis = ImageAnalysis(
        caption: 'Test',
        objects: [
          DetectedObject(label: 'exact', confidence: 0.70),
          DetectedObject(label: 'below', confidence: 0.699),
          DetectedObject(label: 'above', confidence: 0.701),
        ],
      );

      final filtered = analysis.filteredObjects;

      expect(filtered.length, equals(2));
      expect(filtered.map((o) => o.label), containsAll(['exact', 'above']));
      expect(filtered.map((o) => o.label), isNot(contains('below')));
    });
  });
}
