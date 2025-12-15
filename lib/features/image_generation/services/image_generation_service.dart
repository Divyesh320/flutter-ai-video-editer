import '../../../core/services/services.dart';

/// Image generation request
class ImageGenerationRequest {
  const ImageGenerationRequest({
    required this.prompt,
    this.width = 512,
    this.height = 512,
    this.style = 'photographic',
    this.negativePrompt,
  });

  final String prompt;
  final int width;
  final int height;
  final String style;
  final String? negativePrompt;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'width': width,
    'height': height,
    'style': style,
    if (negativePrompt != null) 'negativePrompt': negativePrompt,
  };
}

/// Image generation response
class ImageGenerationResponse {
  const ImageGenerationResponse({
    required this.imageBase64,
    this.seed,
    this.prompt,
    this.style,
  });

  factory ImageGenerationResponse.fromJson(Map<String, dynamic> json) {
    return ImageGenerationResponse(
      imageBase64: json['image'] as String? ?? '',
      seed: json['seed'] as int?,
      prompt: json['prompt'] as String?,
      style: json['style'] as String?,
    );
  }

  final String imageBase64;
  final int? seed;
  final String? prompt;
  final String? style;
}

/// Image generation service
class ImageGenerationService {
  ImageGenerationService({required this.apiService});

  final ApiService apiService;

  /// Generate image from text prompt
  Future<ImageGenerationResponse> generateImage(ImageGenerationRequest request) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        '/images/generate',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return ImageGenerationResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to generate image: $e');
    }
  }

  /// Get available style presets
  Future<List<String>> getStyles() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>('/images/styles');
      
      if (response.data == null) return [];
      
      final data = response.data!['data'] ?? response.data!;
      final styles = data['styles'] as List?;
      return styles?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      return [
        'photographic', 'digital-art', 'anime', 'cinematic',
        'comic-book', 'fantasy-art', 'line-art', 'neon-punk',
      ];
    }
  }

  /// Check if image generation is available
  Future<bool> isAvailable() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>('/images/status');
      final data = response.data?['data'] ?? response.data;
      return data?['available'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get Stability AI credits
  /// Returns null if unable to fetch credits, otherwise returns the actual credit value
  Future<double?> getCredits() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>('/images/status');
      final data = response.data?['data'] ?? response.data;
      final credits = data?['credits'];
      if (credits is num) {
        return credits.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
