import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/services/services.dart';

/// Video generation request
class VideoGenerationRequest {
  const VideoGenerationRequest({
    required this.prompt,
    this.durationSeconds = 510,
    this.style = 'cinematic',
    this.imageCount,
    this.imageDuration = 5,
  });

  final String prompt;
  final int durationSeconds;
  final String style;
  final int? imageCount;
  final int imageDuration;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'durationSeconds': durationSeconds,
    'style': style,
    if (imageCount != null) 'imageCount': imageCount,
    'imageDuration': imageDuration,
  };
}

/// Video generation response
class VideoGenerationResponse {
  const VideoGenerationResponse({
    required this.downloadUrl,
    this.duration,
    this.imageCount,
    this.jobId,
  });

  factory VideoGenerationResponse.fromJson(Map<String, dynamic> json) {
    return VideoGenerationResponse(
      downloadUrl: json['downloadUrl'] as String? ?? '',
      duration: json['duration'] as int?,
      imageCount: json['imageCount'] as int?,
      jobId: json['jobId'] as String?,
    );
  }

  final String downloadUrl;
  final int? duration;
  final int? imageCount;
  final String? jobId;
}


/// Video generation service
class VideoGenerationService {
  VideoGenerationService({required this.apiService});

  final ApiService apiService;

  /// Generate video from text prompt
  Future<VideoGenerationResponse> generateVideo(VideoGenerationRequest request) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        '/ai-video/generate',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return VideoGenerationResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to generate video: $e');
    }
  }

  /// Enhance uploaded video
  Future<VideoGenerationResponse> enhanceVideo(File videoFile, {String? overlayText}) async {
    try {
      final config = ApiConfig.fromEnv();
      final uri = Uri.parse('${config.baseUrl}/ai-video/enhance');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${await _getToken()}';
      
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType('video', 'mp4'),
      ));
      
      if (overlayText != null) {
        request.fields['overlayText'] = overlayText;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw ApiException('Enhancement failed: ${response.body}');
      }

      final json = await apiService.parseJson(response.body);
      final data = json['data'] ?? json;
      return VideoGenerationResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to enhance video: $e');
    }
  }

  Future<String> _getToken() async {
    // Get token from secure storage
    return '';
  }

  /// Get available styles
  Future<List<String>> getStyles() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>('/ai-video/styles');
      final data = response.data?['data'] ?? response.data;
      final styles = data?['styles'] as List?;
      return styles?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      return ['cinematic', 'photographic', 'anime', 'digital-art'];
    }
  }

  /// Check if service is available
  Future<bool> isAvailable() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>('/ai-video/status');
      final data = response.data?['data'] ?? response.data;
      return data?['available'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get full download URL
  String getFullDownloadUrl(String downloadUrl) {
    final config = ApiConfig.fromEnv();
    return '${config.baseUrl}$downloadUrl';
  }
}
