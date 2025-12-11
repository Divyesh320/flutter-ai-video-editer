import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_service.dart';
import 'api_exceptions.dart';

/// Video metadata from processing
class VideoMetadata {
  const VideoMetadata({
    this.duration,
    this.width,
    this.height,
    this.fps,
    this.codec,
    this.bitrate,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      duration: (json['duration'] as num?)?.toDouble(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      fps: (json['fps'] as num?)?.toDouble(),
      codec: json['codec'] as String?,
      bitrate: json['bitrate'] as int?,
    );
  }

  final double? duration;
  final int? width;
  final int? height;
  final double? fps;
  final String? codec;
  final int? bitrate;
}

/// Frame extracted from video
class VideoFrame {
  const VideoFrame({
    required this.timestamp,
    required this.filename,
    required this.filePath,
  });

  factory VideoFrame.fromJson(Map<String, dynamic> json) {
    return VideoFrame(
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      filename: json['filename'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
    );
  }

  final double timestamp;
  final String filename;
  final String filePath;
}

/// Video job status
enum VideoJobStatus {
  uploaded,
  processing,
  completed,
  failed,
}

/// Video job response
class VideoJob {
  const VideoJob({
    required this.id,
    required this.filename,
    required this.status,
    this.metadata,
    this.frames,
    this.thumbnailPath,
    this.error,
    this.createdAt,
    this.completedAt,
  });

  factory VideoJob.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'uploaded';
    final status = VideoJobStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => VideoJobStatus.uploaded,
    );

    return VideoJob(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      status: status,
      metadata: json['metadata'] != null
          ? VideoMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      frames: (json['frames'] as List?)
          ?.map((f) => VideoFrame.fromJson(f as Map<String, dynamic>))
          .toList(),
      thumbnailPath: json['thumbnailPath'] as String?,
      error: json['error'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  final String id;
  final String filename;
  final VideoJobStatus status;
  final VideoMetadata? metadata;
  final List<VideoFrame>? frames;
  final String? thumbnailPath;
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get isCompleted => status == VideoJobStatus.completed;
  bool get isFailed => status == VideoJobStatus.failed;
  bool get isProcessing => status == VideoJobStatus.processing;
}

/// Video upload response
class VideoUploadResponse {
  const VideoUploadResponse({
    required this.job,
    this.message,
  });

  factory VideoUploadResponse.fromJson(Map<String, dynamic> json) {
    return VideoUploadResponse(
      job: VideoJob.fromJson(json['job'] as Map<String, dynamic>? ?? json),
      message: json['message'] as String?,
    );
  }

  final VideoJob job;
  final String? message;
}

/// Video Service for upload and processing
class VideoService {
  VideoService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  /// Upload and process video
  Future<VideoUploadResponse> uploadVideo({
    required File videoFile,
    bool extractFrames = true,
    double frameInterval = 1.0,
    int maxFrames = 100,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/video/upload',
        videoFile.path,
        fieldName: 'video',
        additionalFields: {
          'extractFrames': extractFrames.toString(),
          'frameInterval': frameInterval.toString(),
          'maxFrames': maxFrames.toString(),
        },
        onProgress: onProgress,
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return VideoUploadResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to upload video: $e');
    }
  }

  /// Get video job status
  Future<VideoJob> getVideoJob(String jobId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/video/jobs/$jobId',
      );

      if (response.data == null) {
        throw ApiException('Video job not found');
      }

      final data = response.data!['data'] ?? response.data!;
      return VideoJob.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get video job: $e');
    }
  }

  /// Get list of user's video jobs
  Future<List<VideoJob>> getVideoJobs({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/video/jobs',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data!['data'] ?? [];
      return (data as List)
          .map((j) => VideoJob.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get video jobs: $e');
    }
  }

  /// Get extracted frame image
  Future<Uint8List> getFrame(String jobId, int frameIndex) async {
    try {
      final response = await _apiService.get<List<int>>(
        '/video/jobs/$jobId/frames/$frameIndex',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) {
        throw ApiException('Frame not found');
      }

      return Uint8List.fromList(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get frame: $e');
    }
  }

  /// Get video thumbnail
  Future<Uint8List> getThumbnail(String jobId, {double timestamp = 1.0}) async {
    try {
      final response = await _apiService.get<List<int>>(
        '/video/jobs/$jobId/thumbnail',
        queryParameters: {'timestamp': timestamp},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) {
        throw ApiException('Thumbnail not found');
      }

      return Uint8List.fromList(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get thumbnail: $e');
    }
  }

  /// Delete video job
  Future<void> deleteVideoJob(String jobId) async {
    try {
      await _apiService.delete<void>('/video/jobs/$jobId');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete video job: $e');
    }
  }

  /// Poll for job completion
  Future<VideoJob> waitForCompletion(
    String jobId, {
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final startTime = DateTime.now();
    
    while (true) {
      final job = await getVideoJob(jobId);
      
      if (job.isCompleted || job.isFailed) {
        return job;
      }
      
      if (DateTime.now().difference(startTime) > timeout) {
        throw ApiException('Video processing timeout');
      }
      
      await Future.delayed(pollInterval);
    }
  }
}
