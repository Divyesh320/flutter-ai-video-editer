import '../../../core/models/models.dart';

/// Service for building vision context from image analysis data
/// to include in LLM requests for follow-up questions
class VisionContextService {
  const VisionContextService();

  /// Builds a context string from image analysis data in a conversation
  /// Returns null if no image analysis is found
  String? buildVisionContext(List<Message> messages) {
    final imageMessages = messages.where((m) => m.type == MessageType.image);
    
    if (imageMessages.isEmpty) {
      return null;
    }

    final contextParts = <String>[];

    for (final message in imageMessages) {
      final imageContext = _extractImageContext(message);
      if (imageContext != null) {
        contextParts.add(imageContext);
      }
    }

    if (contextParts.isEmpty) {
      return null;
    }

    return contextParts.join('\n\n');
  }

  /// Extracts vision context from a single image message
  String? _extractImageContext(Message message) {
    if (message.metadata == null) {
      return null;
    }

    final parts = <String>[];

    // Extract caption
    final caption = message.metadata!['caption'] as String?;
    if (caption != null && caption.isNotEmpty) {
      parts.add('Image Caption: $caption');
    }

    // Extract detected objects/labels
    final objects = message.metadata!['objects'] as List<dynamic>?;
    if (objects != null && objects.isNotEmpty) {
      final labels = objects
          .map((o) => o['label'] as String?)
          .where((l) => l != null && l.isNotEmpty)
          .toList();
      if (labels.isNotEmpty) {
        parts.add('Detected Objects: ${labels.join(', ')}');
      }
    }

    // Extract OCR text
    final ocrText = message.metadata!['ocr_text'] as String?;
    if (ocrText != null && ocrText.isNotEmpty) {
      parts.add('Text in Image (OCR): $ocrText');
    }

    if (parts.isEmpty) {
      return null;
    }

    return '[Image Analysis]\n${parts.join('\n')}';
  }

  /// Checks if a conversation contains any image messages with analysis
  bool hasImageContext(List<Message> messages) {
    return messages.any((m) => 
      m.type == MessageType.image && 
      m.metadata != null &&
      (m.metadata!['caption'] != null || 
       m.metadata!['objects'] != null || 
       m.metadata!['ocr_text'] != null)
    );
  }

  /// Gets the most recent image analysis from a conversation
  ImageContextData? getMostRecentImageContext(List<Message> messages) {
    final imageMessages = messages
        .where((m) => m.type == MessageType.image && m.metadata != null)
        .toList();
    
    if (imageMessages.isEmpty) {
      return null;
    }

    // Get the most recent image message
    final mostRecent = imageMessages.last;
    
    return ImageContextData(
      caption: mostRecent.metadata!['caption'] as String?,
      labels: _extractLabels(mostRecent.metadata!['objects']),
      ocrText: mostRecent.metadata!['ocr_text'] as String?,
      imageUrl: mostRecent.media?.firstOrNull?.url,
    );
  }

  List<String> _extractLabels(dynamic objects) {
    if (objects == null || objects is! List) {
      return [];
    }
    return objects
        .map((o) => o['label'] as String?)
        .where((l) => l != null && l.isNotEmpty)
        .cast<String>()
        .toList();
  }
}

/// Data class containing extracted image context
class ImageContextData {
  const ImageContextData({
    this.caption,
    this.labels = const [],
    this.ocrText,
    this.imageUrl,
  });

  final String? caption;
  final List<String> labels;
  final String? ocrText;
  final String? imageUrl;

  /// Returns true if any context data is available
  bool get hasData => 
      (caption != null && caption!.isNotEmpty) ||
      labels.isNotEmpty ||
      (ocrText != null && ocrText!.isNotEmpty);

  /// Formats the context for LLM inclusion
  String toContextString() {
    final parts = <String>[];

    if (caption != null && caption!.isNotEmpty) {
      parts.add('Caption: $caption');
    }

    if (labels.isNotEmpty) {
      parts.add('Detected Objects: ${labels.join(', ')}');
    }

    if (ocrText != null && ocrText!.isNotEmpty) {
      parts.add('Text in Image: $ocrText');
    }

    return parts.join('\n');
  }
}
