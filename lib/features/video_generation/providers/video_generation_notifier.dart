import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/services.dart';
import '../../chat/providers/chat_notifier.dart';
import '../services/video_generation_service.dart';

/// State for video generation
class VideoGenerationState {
  const VideoGenerationState({
    this.isLoading = false,
    this.isGenerating = false,
    this.progress = 0,
    this.statusMessage,
    this.downloadUrl,
    this.errorMessage,
    this.prompt,
    this.duration = 510,
    this.style = 'cinematic',
    this.availableStyles = const [],
    this.selectedVideo,
  });

  final bool isLoading;
  final bool isGenerating;
  final double progress;
  final String? statusMessage;
  final String? downloadUrl;
  final String? errorMessage;
  final String? prompt;
  final int duration;
  final String style;
  final List<String> availableStyles;
  final File? selectedVideo;

  VideoGenerationState copyWith({
    bool? isLoading,
    bool? isGenerating,
    double? progress,
    String? statusMessage,
    String? downloadUrl,
    String? errorMessage,
    String? prompt,
    int? duration,
    String? style,
    List<String>? availableStyles,
    File? selectedVideo,
  }) {
    return VideoGenerationState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      statusMessage: statusMessage,
      downloadUrl: downloadUrl,
      errorMessage: errorMessage,
      prompt: prompt ?? this.prompt,
      duration: duration ?? this.duration,
      style: style ?? this.style,
      availableStyles: availableStyles ?? this.availableStyles,
      selectedVideo: selectedVideo,
    );
  }
}
