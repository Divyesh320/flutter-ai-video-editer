import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/models/models.dart';

/// Message bubble with ChatGPT-style typing animation
class AnimatedTextBubble extends StatefulWidget {
  const AnimatedTextBubble({
    super.key,
    required this.message,
    this.animateText = false,
    this.onAnimationComplete,
    this.onSpeak,
    this.isSpeaking = false,
  });

  final Message message;
  final bool animateText;
  final VoidCallback? onAnimationComplete;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  @override
  State<AnimatedTextBubble> createState() => _AnimatedTextBubbleState();
}

class _AnimatedTextBubbleState extends State<AnimatedTextBubble> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateText) {
      _startTypingAnimation();
    } else {
      _displayedText = widget.message.content;
    }
  }

  @override
  void didUpdateWidget(AnimatedTextBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.content != oldWidget.message.content) {
      if (widget.animateText) {
        _startTypingAnimation();
      } else {
        setState(() {
          _displayedText = widget.message.content;
        });
      }
    }
  }

  void _startTypingAnimation() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = '';
    _isAnimating = true;

    final content = widget.message.content;
    const typingSpeed = Duration(milliseconds: 15); // Fast typing

    _timer = Timer.periodic(typingSpeed, (timer) {
      if (_currentIndex < content.length) {
        setState(() {
          // Add multiple characters at once for faster effect
          final charsToAdd = (_currentIndex + 3 <= content.length) ? 3 : content.length - _currentIndex;
          _displayedText = content.substring(0, _currentIndex + charsToAdd);
          _currentIndex += charsToAdd;
        });
      } else {
        timer.cancel();
        _isAnimating = false;
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Message content
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: _displayedText,
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
                  ),
                  // Blinking cursor while typing
                  if (_isAnimating) _buildBlinkingCursor(theme),
                  // Action buttons (show after animation completes)
                  if (!_isAnimating) ...[
                    const SizedBox(height: 4),
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
                                color: textColor.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Speaker button (TTS)
                        if (widget.onSpeak != null) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: widget.onSpeak,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isSpeaking ? Icons.stop : Icons.volume_up,
                                  size: 14,
                                  color: widget.isSpeaking 
                                      ? Colors.blue
                                      : textColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isSpeaking ? 'Stop' : 'Speak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isSpeaking 
                                        ? Colors.blue
                                        : textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildBlinkingCursor(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2).floor() % 2 == 0 ? 1 : 0,
          child: Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.only(left: 2),
            color: theme.colorScheme.primary,
          ),
        );
      },
    );
  }
}
