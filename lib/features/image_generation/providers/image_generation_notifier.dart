import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/services.dart';
import '../../chat/providers/chat_notifier.dart';
import '../services/image_generation_service.dart';

/// State for image generation
class ImageGenerationState {
  const ImageGenerationState({
    this.isLoading = false,
    this.generatedImage,
    this.prompt,
    this.style = 'photographic',
    this.errorMessage,
    this.availableStyles = const [],
    this.credits,
  });

  final bool isLoading;
  final Uint8List? generatedImage;
  final String? prompt;
  final String style;
  final String? errorMessage;
  final List<String> availableStyles;
  final double? credits;

  ImageGenerationState copyWith({
    bool? isLoading,
    Uint8List? generatedImage,
    String? prompt,
    String? style,
    String? errorMessage,
    List<String>? availableStyles,
    double? credits,
  }) {
    return ImageGenerationState(
      isLoading: isLoading ?? this.isLoading,
      generatedImage: generatedImage ?? this.generatedImage,
      prompt: prompt ?? this.prompt,
      style: style ?? this.style,
      errorMessage: errorMessage,
      availableStyles: availableStyles ?? this.availableStyles,
      credits: credits ?? this.credits,
    );
  }
}

/// Provider for ImageGenerationService
final imageGenerationServiceProvider = Provider<ImageGenerationService>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return ImageGenerationService(apiService: apiService);
});

/// Provider for ImageGenerationNotifier
final imageGenerationNotifierProvider =
    StateNotifierProvider<ImageGenerationNotifier, ImageGenerationState>((ref) {
  final service = ref.watch(imageGenerationServiceProvider);
  return ImageGenerationNotifier(service);
});

/// Notifier for image generation
class ImageGenerationNotifier extends StateNotifier<ImageGenerationState> {
  ImageGenerationNotifier(this._service) : super(const ImageGenerationState()) {
    _loadStyles();
    loadCredits();
  }

  final ImageGenerationService _service;

  Future<void> _loadStyles() async {
    final styles = await _service.getStyles();
    state = state.copyWith(availableStyles: styles);
  }

  /// Load credits from Stability AI
  Future<void> loadCredits() async {
    try {
      final credits = await _service.getCredits();
      if (credits != null) {
        state = state.copyWith(credits: credits);
      }
    } catch (e) {
      // Ignore errors - credits are optional info
    }
  }

  /// Generate image from prompt
  Future<void> generateImage(String prompt, {String? style}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      prompt: prompt,
    );

    try {
      final response = await _service.generateImage(
        ImageGenerationRequest(
          prompt: prompt,
          style: style ?? state.style,
        ),
      );

      // Decode base64 image (remove data:image/png;base64, prefix if present)
      String base64Data = response.imageBase64;
      if (base64Data.contains(',')) {
        base64Data = base64Data.split(',').last;
      }
      
      final imageBytes = base64Decode(base64Data);

      state = state.copyWith(
        isLoading: false,
        generatedImage: imageBytes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Set style
  void setStyle(String style) {
    state = state.copyWith(style: style);
  }

  /// Clear generated image
  void clearImage() {
    state = state.copyWith(
      generatedImage: null,
      prompt: null,
      errorMessage: null,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Failed to generate image. Please try again.';
  }
}
