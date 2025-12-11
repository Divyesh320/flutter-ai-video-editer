import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../services/video_service.dart';
import 'video_summary_card.dart';

/// State of video upload/processing
enum VideoUploadState {
  idle,
  uploading,
  processing,
  completed,
  failed,
}

/// Widget to display video upload progress and processing status
class VideoUploadCard extends StatelessWidget {
  const VideoUploadCard({
    super.key,
    required this.state,
    this.uploadProgress = 0.0,
    this.processingProgress = 0,
    this.summary,
    this.videoUrl,
    this.errorMessage,
    this.onRetry,
    this.onCancel,
    this.onAskFollowUp,
  });

  /// Current state of the upload/processing
  final VideoUploadState state;

  /// Upload progress (0.0 to 1.0)
  final double uploadProgress;

  /// Processing progress (0 to 100)
  final int processingProgress;

  /// Video summary (when completed)
  final VideoSummary? summary;

  /// URL to the video
  final String? videoUrl;

  /// Error message (when failed)
  final String? errorMessage;

  /// Callback for retry action
  final VoidCallback? onRetry;

  /// Callback for cancel action
  final VoidCallback? onCancel;

  /// Callback for follow-up questions
  final VoidCallback? onAskFollowUp;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case VideoUploadState.idle:
        return const SizedBox.shrink();
      
      case VideoUploadState.uploading:
        return _buildUploadingCard(context);
      
      case VideoUploadState.processing:
        return _buildProcessingCard(context);
      
      case VideoUploadState.completed:
        if (summary != null) {
          return VideoSummaryCard(
            summary: summary!,
            videoUrl: videoUrl,
            onAskFollowUp: onAskFollowUp,
          );
        }
        return const SizedBox.shrink();
      
      case VideoUploadState.failed:
        return _buildErrorCard(context);
    }
  }

  Widget _buildUploadingCard(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (uploadProgress * 100).toInt();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Uploading video...',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'Cancel',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% uploaded',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing video...',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: processingProgress / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '$processingProgress% - Extracting audio and generating summary',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Video processing failed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Dismiss'),
                  ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Creates a VideoUploadCard from a VideoJobResponse
VideoUploadCard createVideoUploadCardFromJob({
  required VideoJobResponse job,
  double uploadProgress = 1.0,
  String? videoUrl,
  VoidCallback? onRetry,
  VoidCallback? onCancel,
  VoidCallback? onAskFollowUp,
}) {
  VideoUploadState state;
  switch (job.status) {
    case VideoJobStatus.pending:
    case VideoJobStatus.processing:
      state = VideoUploadState.processing;
      break;
    case VideoJobStatus.completed:
      state = VideoUploadState.completed;
      break;
    case VideoJobStatus.failed:
      state = VideoUploadState.failed;
      break;
  }

  return VideoUploadCard(
    state: state,
    uploadProgress: uploadProgress,
    processingProgress: job.progress ?? 0,
    summary: job.result,
    videoUrl: videoUrl,
    errorMessage: job.error,
    onRetry: onRetry,
    onCancel: onCancel,
    onAskFollowUp: onAskFollowUp,
  );
}
