import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/models/models.dart';

/// Message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.onSpeak,
    this.isSpeaking = false,
  });

  final Message message;
  final bool isUser;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(theme),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(theme),
                  const SizedBox(height: 4),
                  // Action buttons row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Copy button
                      GestureDetector(
                        onTap: () => _copyToClipboard(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: isUser
                                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUser
                                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Speaker button (TTS) - only for AI messages
                      if (!isUser && onSpeak != null) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: onSpeak,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSpeaking ? Icons.stop : Icons.volume_up,
                                size: 14,
                                color: isSpeaking 
                                    ? Colors.blue
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSpeaking ? 'Stop' : 'Speak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSpeaking 
                                      ? Colors.blue
                                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(theme),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }


  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    // Handle image messages
    if (message.type == MessageType.image && isUser) {
      final imagePath = message.metadata?['imagePath'] as String?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 100,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          if (imagePath != null) const SizedBox(height: 8),
          SelectableText(
            message.content,
            style: TextStyle(color: textColor),
          ),
        ],
      );
    }

    // Handle video messages
    if (message.type == MessageType.video && isUser) {
      final videoPath = message.metadata?['videoPath'] as String?;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.videocam, color: Colors.white54, size: 40),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      videoPath?.split('/').last ?? 'Video',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            message.content,
            style: TextStyle(color: textColor),
          ),
        ],
      );
    }

    // Use markdown rendering for assistant messages
    if (!isUser && message.type == MessageType.text) {
      return MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: textColor),
          code: TextStyle(
            backgroundColor: theme.colorScheme.surface,
            color: theme.colorScheme.primary,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          listBullet: TextStyle(color: textColor),
          h1: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          h2: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          h3: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        ),
        selectable: true,
      );
    }

    // User messages - also selectable
    return SelectableText(
      message.content,
      style: TextStyle(color: textColor),
    );
  }
}
