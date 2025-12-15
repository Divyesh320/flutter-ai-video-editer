import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Chat input widget with text field, send button, voice input, attachments, and suggestions
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendWithAttachment,
    this.isLoading = false,
    this.enabled = true,
    this.suggestions = const [],
    this.onSuggestionTap,
    this.onVoiceInput,
    this.isListening = false,
  });

  final void Function(String) onSend;
  final void Function(String message, File? image, File? video)? onSendWithAttachment;
  final bool isLoading;
  final bool enabled;
  final List<String> suggestions;
  final void Function(String)? onSuggestionTap;
  final VoidCallback? onVoiceInput;
  final bool isListening;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  
  File? _selectedImage;
  File? _selectedVideo;

  bool get _canSend =>
      widget.enabled && !widget.isLoading && 
      (_controller.text.trim().isNotEmpty || _selectedImage != null || _selectedVideo != null);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (!_canSend) return;

    final text = _controller.text.trim();
    
    if (widget.onSendWithAttachment != null && (_selectedImage != null || _selectedVideo != null)) {
      widget.onSendWithAttachment!(text, _selectedImage, _selectedVideo);
    } else {
      widget.onSend(text);
    }
    
    _controller.clear();
    _clearAttachments();
    _focusNode.requestFocus();
  }
  
  void _clearAttachments() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }
  
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedVideo = null; // Clear video if image selected
      });
    }
  }
  
  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
        _selectedImage = null; // Clear image if video selected
      });
    }
  }
  
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Image'),
              subtitle: const Text('Select from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Video'),
              subtitle: const Text('Select from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() {
                    _selectedImage = File(picked.path);
                    _selectedVideo = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment preview
            if (_selectedImage != null || _selectedVideo != null)
              _buildAttachmentPreview(theme),
            // Suggestion chips
            if (widget.suggestions.isNotEmpty) _buildSuggestions(theme),
            Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: widget.enabled ? _showAttachmentOptions : null,
                  icon: Icon(
                    Icons.attach_file,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                // Voice input button
                if (widget.onVoiceInput != null)
                  IconButton(
                    onPressed: widget.enabled ? widget.onVoiceInput : null,
                    icon: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none,
                      color: widget.isListening 
                          ? Colors.red 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: widget.isListening
                          ? Colors.red.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 150, // Max height for text input
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: widget.isListening 
                            ? 'Listening...' 
                            : 'Type or speak a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: 6, // Allow up to 6 lines, then scroll
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSendButton(theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = widget.suggestions[index];
          return ActionChip(
            label: Text(
              suggestion,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            onPressed: () {
              if (widget.onSuggestionTap != null) {
                widget.onSuggestionTap!(suggestion);
              } else {
                _controller.text = suggestion;
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAttachmentPreview(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.purple.withValues(alpha: 0.2),
                      child: const Icon(Icons.videocam, color: Colors.purple),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImage != null ? 'Image attached' : 'Video attached',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _selectedImage?.path.split('/').last ?? 
                  _selectedVideo?.path.split('/').last ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            onPressed: _clearAttachments,
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    if (widget.isLoading) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return IconButton(
      onPressed: _canSend ? _handleSend : null,
      icon: Icon(
        Icons.send,
        color: _canSend ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      style: IconButton.styleFrom(
        backgroundColor: _canSend
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
