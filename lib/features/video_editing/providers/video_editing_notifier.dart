import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/services.dart' hide VideoMetadata;
import '../../chat/providers/chat_notifier.dart';
import '../services/video_editing_service.dart';

/// State for video editing
class VideoEditingState {
  const VideoEditingState({
    this.isLoading = false,
    this.selectedVideo,
    this.metadata,
    this.downloadUrl,
    this.errorMessage,
    this.availableFilters = const [],
    this.currentOperation,
  });

  final bool isLoading;
  final File? selectedVideo;
  final VideoMetadata? metadata;
  final String? downloadUrl;
  final String? errorMessage;
  final List<String> availableFilters;
  final String? currentOperation;

  VideoEditingState copyWith({
    bool? isLoading,
    File? selectedVideo,
    VideoMetadata? metadata,
    String? downloadUrl,
    String? errorMessage,
    List<String>? availableFilters,
    String? currentOperation,
  }) {
    return VideoEditingState(
      isLoading: isLoading ?? this.isLoading,
      selectedVideo: selectedVideo ?? this.selectedVideo,
      metadata: metadata ?? this.metadata,
      downloadUrl: downloadUrl,
      errorMessage: errorMessage,
      availableFilters: availableFilters ?? this.availableFilters,
      currentOperation: currentOperation,
    );
  }
}

/// Provider for VideoEditingService
final videoEditingServiceProvider = Provider<VideoEditingService>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return VideoEditingService(apiService: apiService);
});

/// Provider for VideoEditingNotifier
final videoEditingNotifierProvider =
    StateNotifierProvider<VideoEditingNotifier, VideoEditingState>((ref) {
  final service = ref.watch(videoEditingServiceProvider);
  return VideoEditingNotifier(service);
});

/// Notifier for video editing
class VideoEditingNotifier extends StateNotifier<VideoEditingState> {
  VideoEditingNotifier(this._service) : super(const VideoEditingState()) {
    _loadFilters();
  }

  final VideoEditingService _service;

  Future<void> _loadFilters() async {
    final filters = await _service.getFilters();
    state = state.copyWith(availableFilters: filters);
  }

  /// Select video file
  Future<void> selectVideo(File video) async {
    state = state.copyWith(
      selectedVideo: video,
      isLoading: true,
      downloadUrl: null,
      errorMessage: null,
    );

    try {
      final metadata = await _service.getMetadata(video);
      state = state.copyWith(
        metadata: metadata,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load video metadata',
      );
    }
  }

  /// Trim video
  Future<void> trimVideo(double startTime, double endTime) async {
    if (state.selectedVideo == null) return;

    state = state.copyWith(
      isLoading: true,
      currentOperation: 'Trimming video...',
      errorMessage: null,
    );

    try {
      final result = await _service.trimVideo(
        state.selectedVideo!,
        startTime,
        endTime,
      );
      state = state.copyWith(
        isLoading: false,
        downloadUrl: result.downloadUrl,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
        currentOperation: null,
      );
    }
  }

  /// Apply filter
  Future<void> applyFilter(String filterType, {double intensity = 1}) async {
    if (state.selectedVideo == null) return;

    state = state.copyWith(
      isLoading: true,
      currentOperation: 'Applying $filterType filter...',
      errorMessage: null,
    );

    try {
      final result = await _service.applyFilter(
        state.selectedVideo!,
        filterType,
        intensity: intensity,
      );
      state = state.copyWith(
        isLoading: false,
        downloadUrl: result.downloadUrl,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
        currentOperation: null,
      );
    }
  }

  /// Add text overlay
  Future<void> addTextOverlay(
    String text, {
    String position = 'bottom',
    int fontSize = 24,
    String fontColor = 'white',
  }) async {
    if (state.selectedVideo == null) return;

    state = state.copyWith(
      isLoading: true,
      currentOperation: 'Adding text overlay...',
      errorMessage: null,
    );

    try {
      final result = await _service.addTextOverlay(
        state.selectedVideo!,
        text,
        position: position,
        fontSize: fontSize,
        fontColor: fontColor,
      );
      state = state.copyWith(
        isLoading: false,
        downloadUrl: result.downloadUrl,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
        currentOperation: null,
      );
    }
  }

  /// Resize video
  Future<void> resizeVideo(int width, {int? height}) async {
    if (state.selectedVideo == null) return;

    state = state.copyWith(
      isLoading: true,
      currentOperation: 'Resizing video...',
      errorMessage: null,
    );

    try {
      final result = await _service.resizeVideo(
        state.selectedVideo!,
        width,
        height: height,
      );
      state = state.copyWith(
        isLoading: false,
        downloadUrl: result.downloadUrl,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
        currentOperation: null,
      );
    }
  }

  /// Extract audio
  Future<void> extractAudio({String format = 'mp3'}) async {
    if (state.selectedVideo == null) return;

    state = state.copyWith(
      isLoading: true,
      currentOperation: 'Extracting audio...',
      errorMessage: null,
    );

    try {
      final result = await _service.extractAudio(
        state.selectedVideo!,
        format: format,
      );
      state = state.copyWith(
        isLoading: false,
        downloadUrl: result.downloadUrl,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
        currentOperation: null,
      );
    }
  }

  /// Convert format
  Future<void> convertFormat(String format) async {
    if (state.selectedVideo == null) return;

    state = state.copyWith(
      isLoading: true,
      currentOperation: 'Converting to $format...',
      errorMessage: null,
    );

    try {
      final result = await _service.convertFormat(
        state.selectedVideo!,
        format,
      );
      state = state.copyWith(
        isLoading: false,
        downloadUrl: result.downloadUrl,
        currentOperation: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
        currentOperation: null,
      );
    }
  }

  /// Clear state
  void clear() {
    state = VideoEditingState(availableFilters: state.availableFilters);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Operation failed. Please try again.';
  }
}
