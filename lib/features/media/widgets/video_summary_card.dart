import 'package:flutter/material.dart';

import '../../../core/models/models.dart';

/// Widget to display a video summary with title, highlights, and transcript
class VideoSummaryCard extends StatelessWidget {
  const VideoSummaryCard({
    super.key,
    required this.summary,
    this.videoUrl,
    this.onAskFollowUp,
    this.onPlayVideo,
  });

  /// The video summary to display
  final VideoSummary summary;

  /// URL to the video (optional, for playback)
  final String? videoUrl;

  /// Callback when user wants to ask a follow-up question
  final VoidCallback? onAskFollowUp;

  /// Callback when user wants to play the video
  final VoidCallback? onPlayVideo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video icon and title
            Row(
              children: [
                Icon(
                  Icons.video_library,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onPlayVideo != null)
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: onPlayVideo,
                    tooltip: 'Play video',
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Duration
            Text(
              'Duration: ${_formatDuration(summary.durationObject)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const Divider(height: 24),
            
            // Highlights section
            Text(
              'Key Highlights',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.highlights.map((highlight) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      highlight,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
            
            const Divider(height: 24),
            
            // Transcript section (collapsible)
            _TranscriptSection(transcript: summary.transcript),
            
            // Follow-up button
            if (onAskFollowUp != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAskFollowUp,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ask a follow-up question'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    }
    return '${seconds}s';
  }
}

/// Collapsible transcript section
class _TranscriptSection extends StatefulWidget {
  const _TranscriptSection({required this.transcript});

  final String transcript;

  @override
  State<_TranscriptSection> createState() => _TranscriptSectionState();
}

class _TranscriptSectionState extends State<_TranscriptSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Text(
                'Transcript',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.transcript,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}
