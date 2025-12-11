import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

/// Response from image upload/analysis API
class ImageUploadResponse {
  const ImageUploadResponse({
    required this.imageId,
    required this.imageUrl,
    required this.analysis,
  });

  /// Unique identifier for the uploaded image
  final String imageId;

  /// URL/path to the stored image
  final String imageUrl;

  /// Vision API analysis results
  final ImageAnalysis analysis;

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      imageId: json['image_id'] as String,
      imageUrl: json['image_url'] as String,
      analysis: ImageAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'image_id': imageId,
        'image_url': imageUrl,
        'analysis': analysis.toJson(),
      };
}

/// Exception thrown when image operations fail
class ImageException implements Exception {
  const ImageException(this.message);
  final String message;

  @override
  String toString() => 'ImageException: $message';
}

/// Abstract interface for image operations
abstract class ImageService {
  /// Pick an image from gallery or camera
  Future<File?> pickImage(ImageSource source);

  /// Upload image and get Vision API analysis
  Future<ImageUploadResponse> uploadImage(File image, String conversationId);

  /// Get upload progress stream
  Stream<double> get uploadProgress;
}

/// Implementation of ImageService
class ImageServiceImpl implements ImageService {
  ImageServiceImpl({
    required ApiService apiService,
    ImagePicker? imagePicker,
  })  : _apiService = apiService,
        _imagePicker = imagePicker ?? ImagePicker();

  final ApiService _apiService;
  final ImagePicker _imagePicker;
  final _progressController = StreamController<double>.broadcast();

  @override
  Stream<double> get uploadProgress => _progressController.stream;

  @override
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw ImageException('Failed to pick image: $e');
    }
  }

  @override
  Future<ImageUploadResponse> uploadImage(
    File image,
    String conversationId,
  ) async {
    try {
      // Validate file exists
      if (!await image.exists()) {
        throw const ImageException('Image file not found');
      }

      // Reset progress
      _progressController.add(0.0);

      // Upload image to /upload/image endpoint
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/upload/image',
        image.path,
        fieldName: 'image',
        additionalFields: {
          'conversation_id': conversationId,
        },
        onProgress: (sent, total) {
          if (total > 0) {
            _progressController.add(sent / total);
          }
        },
      );

      // Mark upload complete
      _progressController.add(1.0);

      if (response.data == null) {
        throw const ImageException('Empty response from server');
      }

      return ImageUploadResponse.fromJson(response.data!);
    } on OfflineException {
      throw const ImageException('Cannot upload image while offline');
    } catch (e) {
      if (e is ImageException) rethrow;
      if (e is ApiException) {
        throw ImageException('Image upload failed: ${e.message}');
      }
      throw ImageException('Failed to upload image: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// Creates a Message from an ImageUploadResponse
Message createMessageFromImage({
  required ImageUploadResponse imageResponse,
  required String conversationId,
  String? userCaption,
}) {
  return Message(
    id: imageResponse.imageId,
    conversationId: conversationId,
    role: MessageRole.user,
    content: userCaption ?? imageResponse.analysis.caption,
    type: MessageType.image,
    metadata: {
      'source': 'image',
      'caption': imageResponse.analysis.caption,
      'objects': imageResponse.analysis.filteredObjects
          .map((o) => {'label': o.label, 'confidence': o.confidence})
          .toList(),
      'ocr_text': imageResponse.analysis.ocrText,
    },
    media: [
      MediaReference(
        id: imageResponse.imageId,
        url: imageResponse.imageUrl,
        type: MediaType.image,
        analysis: imageResponse.analysis.toJson(),
      ),
    ],
    createdAt: DateTime.now(),
  );
}
