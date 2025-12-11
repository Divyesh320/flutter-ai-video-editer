import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/models/models.dart';

/// Message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  final Message message;
  final bool isUser;

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
              child: _buildContent(theme),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(theme),
        ],
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

    return Text(
      message.content,
      style: TextStyle(color: textColor),
    );
  }
}
