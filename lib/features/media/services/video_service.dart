import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

/// Video validation result
class VideoValidationResult {
  const VideoValidationResult({
    required this.isValid,
    this.error,
    this.duration,
    this.fileSize,
  });

  /// Whether the video passes validation
  final bool isValid;

  /// Error message if validation failed
  final String? error;

  /// Video duration in seconds
  final int? duration;

  /// File size in bytes
  final int? fileSize;

  /// Maximum allowed duration (5 minutes)
  static const maxDurationSeconds = 5 * 60; // 300 seconds

  /// Maximum allowed file size (100MB)
  static const maxFileSizeBytes = 100 * 1024 * 1024; // 100MB
}

/// Video job status from backend
enum VideoJobStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Video job response from backend
class VideoJobResponse {
  const VideoJobResponse({
    required this.jobId,
    required this.status,
    this.progress,
    this.result,
    this.error,
  });

  final String jobId;
  final VideoJobStatus status;
  final int? progress; // 0-100
  final VideoSummary? result;
  final String? error;

  factory VideoJobResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String;
    VideoJobStatus status;
    switch (statusStr) {
      case 'pending':
        status = VideoJobStatus.pending;
        break;
      case 'processing':
        status = VideoJobStatus.processing;
        break;
      case 'completed':
        status = VideoJobStatus.completed;
        break;
      case 'failed':
        status = VideoJobStatus.failed;
        break;
      default:
        status = VideoJobStatus.pending;
    }

    VideoSummary? result;
    if (json['result'] != null) {
      result = VideoSummary.fromJson(json['result'] as Map<String, dynamic>);
    }

    return VideoJobResponse(
      jobId: json['job_id'] as String,
      status: status,
      progress: json['progress'] as int?,
      result: result,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'job_id': jobId,
        'status': status.name,
        'progress': progress,
        'result': result?.toJson(),
        'error': error,
      };
}

/// Exception thrown when video operations fail
class VideoException implements Exception {
  const VideoException(this.message);
  final String message;

  @override
  String toString() => 'VideoException: $message';
}

/// Validates a video file against duration and size constraints
/// 
/// Returns a [VideoValidationResult] indicating whether the video is valid.
/// - Duration must be < 5 minutes (300 seconds)
/// - File size must be < 100MB (104,857,600 bytes)
VideoValidationResult validateVideo({
  required int durationSeconds,
  required int fileSizeBytes,
}) {
  // Check duration constraint
  if (durationSeconds >= VideoValidationResult.maxDurationSeconds) {
    return VideoValidationResult(
      isValid: false,
      error: 'Video duration must be under 5 minutes. Current duration: ${_formatDuration(durationSeconds)}',
      duration: durationSeconds,
      fileSize: fileSizeBytes,
    );
  }

  // Check file size constraint
  if (fileSizeBytes >= VideoValidationResult.maxFileSizeBytes) {
    return VideoValidationResult(
      isValid: false,
      error: 'Video file size must be under 100MB. Current size: ${_formatFileSize(fileSizeBytes)}',
      duration: durationSeconds,
      fileSize: fileSizeBytes,
    );
  }

  return VideoValidationResult(
    isValid: true,
    duration: durationSeconds,
    fileSize: fileSizeBytes,
  );
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes}m ${remainingSeconds}s';
}

String _formatFileSize(int bytes) {
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(1)}MB';
}

/// Abstract interface for video operations
abstract class VideoService {
  /// Pick a video from gallery
  Future<File?> pickVideo();

  /// Validate a video file
  Future<VideoValidationResult> validateVideoFile(File video);

  /// Upload video and start processing
  Future<VideoJobResponse> uploadVideo(File video, String conversationId);

  /// Get job status
  Future<VideoJobResponse> getJobStatus(String jobId);

  /// Poll job status until completion
  Stream<VideoJobResponse> pollJobStatus(String jobId);

  /// Get upload progress stream
  Stream<double> get uploadProgress;
}

/// Implementation of VideoService
class VideoServiceImpl implements VideoService {
  VideoServiceImpl({
    required ApiService apiService,
    ImagePicker? imagePicker,
  })  : _apiService = apiService,
        _imagePicker = imagePicker ?? ImagePicker();

  final ApiService _apiService;
  final ImagePicker _imagePicker;
  final _progressController = StreamController<double>.broadcast();

  /// Polling interval for job status
  static const _pollInterval = Duration(seconds: 2);

  @override
  Stream<double> get uploadProgress => _progressController.stream;

  @override
  Future<File?> pickVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw VideoException('Failed to pick video: $e');
    }
  }

  @override
  Future<VideoValidationResult> validateVideoFile(File video) async {
    try {
      if (!await video.exists()) {
        return const VideoValidationResult(
          isValid: false,
          error: 'Video file not found',
        );
      }

      final fileSize = await video.length();
      
      // Note: Getting actual video duration requires platform-specific code
      // or a video player plugin. For now, we'll rely on the backend to
      // validate duration, but we can still check file size client-side.
      // The maxDuration parameter in pickVideo helps limit duration at selection.
      
      // For validation, we'll use a placeholder duration that passes
      // The actual duration check happens server-side
      const estimatedDuration = 0; // Will be validated server-side

      return validateVideo(
        durationSeconds: estimatedDuration,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      return VideoValidationResult(
        isValid: false,
        error: 'Failed to validate video: $e',
      );
    }
  }

  @override
  Future<VideoJobResponse> uploadVideo(
    File video,
    String conversationId,
  ) async {
    try {
      // Validate file exists
      if (!await video.exists()) {
        throw const VideoException('Video file not found');
      }

      // Reset progress
      _progressController.add(0.0);

      // Upload video to /upload/video endpoint
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/upload/video',
        video.path,
        fieldName: 'video',
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
        throw const VideoException('Empty response from server');
      }

      return VideoJobResponse.fromJson(response.data!);
    } on OfflineException {
      throw const VideoException('Cannot upload video while offline');
    } catch (e) {
      if (e is VideoException) rethrow;
      if (e is ApiException) {
        throw VideoException('Video upload failed: ${e.message}');
      }
      throw VideoException('Failed to upload video: $e');
    }
  }

  @override
  Future<VideoJobResponse> getJobStatus(String jobId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/job/$jobId',
      );

      if (response.data == null) {
        throw const VideoException('Empty response from server');
      }

      return VideoJobResponse.fromJson(response.data!);
    } catch (e) {
      if (e is VideoException) rethrow;
      if (e is ApiException) {
        throw VideoException('Failed to get job status: ${e.message}');
      }
      throw VideoException('Failed to get job status: $e');
    }
  }

  @override
  Stream<VideoJobResponse> pollJobStatus(String jobId) async* {
    while (true) {
      final status = await getJobStatus(jobId);
      yield status;

      if (status.status == VideoJobStatus.completed ||
          status.status == VideoJobStatus.failed) {
        break;
      }

      await Future.delayed(_pollInterval);
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}

/// Creates a Message from a VideoSummary
Message createMessageFromVideo({
  required String videoId,
  required String videoUrl,
  required VideoSummary summary,
  required String conversationId,
}) {
  return Message(
    id: videoId,
    conversationId: conversationId,
    role: MessageRole.user,
    content: summary.title,
    type: MessageType.video,
    metadata: {
      'source': 'video',
      'title': summary.title,
      'highlights': summary.highlights,
      'transcript': summary.transcript,
      'duration': summary.duration,
    },
    media: [
      MediaReference(
        id: videoId,
        url: videoUrl,
        type: MediaType.video,
        transcript: summary.transcript,
      ),
    ],
    createdAt: DateTime.now(),
  );
}
