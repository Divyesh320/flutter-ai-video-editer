import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/services/services.dart';

/// Video editing operations
enum VideoOperation {
  trim,
  filter,
  text,
  resize,
  extractAudio,
  convert,
}

/// Video editing request
class VideoEditRequest {
  const VideoEditRequest({
    required this.videoFile,
    required this.operation,
    this.startTime,
    this.endTime,
    this.filterType,
    this.filterIntensity,
    this.text,
    this.textPosition,
    this.fontSize,
    this.fontColor,
    this.width,
    this.height,
    this.outputFormat,
    this.audioFormat,
  });

  final File videoFile;
  final VideoOperation operation;
  final double? startTime;
  final double? endTime;
  final String? filterType;
  final double? filterIntensity;
  final String? text;
  final String? textPosition;
  final int? fontSize;
  final String? fontColor;
  final int? width;
  final int? height;
  final String? outputFormat;
  final String? audioFormat;
}

/// Video editing response
class VideoEditResponse {
  const VideoEditResponse({
    required this.downloadUrl,
    this.outputPath,
    this.operation,
  });

  factory VideoEditResponse.fromJson(Map<String, dynamic> json) {
    return VideoEditResponse(
      downloadUrl: json['downloadUrl'] as String? ?? '',
      outputPath: json['outputPath'] as String?,
      operation: json['operation'] as String?,
    );
  }

  final String downloadUrl;
  final String? outputPath;
  final String? operation;
}

/// Video metadata
class VideoMetadata {
  const VideoMetadata({
    this.duration,
    this.width,
    this.height,
    this.format,
    this.bitrate,
    this.hasAudio = false,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    final video = json['video'] as Map<String, dynamic>?;
    return VideoMetadata(
      duration: (json['duration'] as num?)?.toDouble(),
      width: video?['width'] as int?,
      height: video?['height'] as int?,
      format: json['format'] as String?,
      bitrate: json['bitrate'] as int?,
      hasAudio: json['audio'] != null,
    );
  }

  final double? duration;
  final int? width;
  final int? height;
  final String? format;
  final int? bitrate;
  final bool hasAudio;
}

/// Video editing service
class VideoEditingService {
  VideoEditingService({required this.apiService});

  final ApiService apiService;

  /// Get available filters
  Future<List<String>> getFilters() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>('/video-edit/filters');
      final data = response.data?['data'] ?? response.data;
      final filters = data?['filters'] as List?;
      return filters?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      return [
        'brightness', 'contrast', 'saturation', 'blur', 'sharpen',
        'grayscale', 'sepia', 'vintage', 'vignette', 'negative'
      ];
    }
  }

  /// Trim video
  Future<VideoEditResponse> trimVideo(File video, double startTime, double endTime) async {
    return _uploadAndProcess('/video-edit/trim', video, {
      'startTime': startTime.toString(),
      'endTime': endTime.toString(),
    });
  }

  /// Apply filter to video
  Future<VideoEditResponse> applyFilter(File video, String filterType, {double intensity = 1}) async {
    return _uploadAndProcess('/video-edit/filter', video, {
      'filterType': filterType,
      'intensity': intensity.toString(),
    });
  }

  /// Add text overlay
  Future<VideoEditResponse> addTextOverlay(
    File video,
    String text, {
    String position = 'bottom',
    int fontSize = 24,
    String fontColor = 'white',
  }) async {
    return _uploadAndProcess('/video-edit/text', video, {
      'text': text,
      'position': position,
      'fontSize': fontSize.toString(),
      'fontColor': fontColor,
    });
  }

  /// Resize video
  Future<VideoEditResponse> resizeVideo(File video, int width, {int? height}) async {
    return _uploadAndProcess('/video-edit/resize', video, {
      'width': width.toString(),
      if (height != null) 'height': height.toString(),
    });
  }

  /// Extract audio from video
  Future<VideoEditResponse> extractAudio(File video, {String format = 'mp3'}) async {
    return _uploadAndProcess('/video-edit/extract-audio', video, {
      'format': format,
    });
  }

  /// Convert video format
  Future<VideoEditResponse> convertFormat(File video, String format) async {
    return _uploadAndProcess('/video-edit/convert', video, {
      'format': format,
    });
  }

  /// Get video metadata
  Future<VideoMetadata> getMetadata(File video) async {
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(video.path),
    });

    final response = await apiService.post<Map<String, dynamic>>(
      '/video-edit/metadata',
      data: formData,
    );

    final data = response.data?['data'] ?? response.data;
    return VideoMetadata.fromJson(data as Map<String, dynamic>);
  }

  /// Helper to upload video and process
  Future<VideoEditResponse> _uploadAndProcess(
    String endpoint,
    File video,
    Map<String, String> fields,
  ) async {
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(video.path),
      ...fields,
    });

    final response = await apiService.post<Map<String, dynamic>>(
      endpoint,
      data: formData,
    );

    if (response.data == null) {
      throw ApiException('Empty response from server');
    }

    final data = response.data!['data'] ?? response.data!;
    return VideoEditResponse.fromJson(data as Map<String, dynamic>);
  }
}
