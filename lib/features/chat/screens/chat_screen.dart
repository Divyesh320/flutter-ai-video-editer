import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/models/models.dart';
import '../providers/chat_notifier.dart';
import '../providers/chat_state.dart';
import '../providers/conversation_notifier.dart';
import '../widgets/animated_text_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Main chat screen with message list and input
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId,
  });

  final String? conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  String? _currentConversationId;
  String _conversationTitle = 'New Chat';
  
  // Speech-to-Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  
  // Text-to-Speech
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    
    // Initialize speech & TTS
    _initSpeech();
    _initTts();
    
    // Delay to avoid modifying provider during build
    Future.microtask(() {
      if (mounted) _loadConversation();
    });
  }
  
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } catch (e) {
      // Speech not available on this device/simulator
      _speechAvailable = false;
      debugPrint('Speech-to-text not available: $e');
    }
    if (mounted) setState(() {});
  }
  
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      // TTS not available on this device/simulator
      debugPrint('Text-to-speech not available: $e');
    }
  }
  
  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (_speechAvailable) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _handleSendMessage(result.recognizedWords);
              setState(() => _isListening = false);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US', // Will auto-detect language
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    }
  }
  
  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationId != oldWidget.conversationId) {
      _currentConversationId = widget.conversationId;
      // Delay to avoid modifying provider during build
      Future.microtask(() {
        if (mounted) _loadConversation();
      });
    }
  }

  void _loadConversation() {
    if (_currentConversationId != null) {
      ref.read(chatNotifierProvider.notifier).loadConversation(
            _currentConversationId!,
          );
      // Load conversation details for title
      _loadConversationTitle();
    } else {
      ref.read(chatNotifierProvider.notifier).startNewConversation();
      setState(() => _conversationTitle = 'New Chat');
    }
  }

  Future<void> _loadConversationTitle() async {
    final conversations = ref.read(conversationNotifierProvider).conversations;
    final conv = conversations.where((c) => c.id == _currentConversationId).firstOrNull;
    if (conv != null) {
      setState(() => _conversationTitle = conv.title ?? 'New Chat');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    // Update conversation ID when created
    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (next.conversationId != null && _currentConversationId == null) {
        _currentConversationId = next.conversationId;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showRenameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _conversationTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _startNewChat();
                  break;
                case 'rename':
                  _showRenameDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('New Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(chatState),
          ),
          if (chatState.errorMessage != null)
            _buildErrorBanner(chatState.errorMessage!),
          ChatInput(
            onSend: _handleSendMessage,
            onSendWithAttachment: _handleSendWithAttachment,
            isLoading: chatState.isSending,
            enabled: chatState.isReady,
            suggestions: chatState.suggestions,
            onSuggestionTap: (suggestion) {
              ref.read(chatNotifierProvider.notifier).clearSuggestions();
              _handleSendMessage(suggestion);
            },
            onVoiceInput: _speechAvailable ? _toggleListening : null,
            isListening: _isListening,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversation,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Calculate item count: messages + typing indicator if sending
    final itemCount = state.messages.length + (state.isSending ? 1 : 0);

    // Use reverse: true for bottom-to-top chat like ChatGPT
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      reverse: true, // Bottom to top
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Reverse index for correct order
        final reversedIndex = itemCount - 1 - index;
        
        // Show typing indicator at the end (which is index 0 in reversed list)
        if (state.isSending && reversedIndex == state.messages.length) {
          return const TypingIndicator();
        }

        final message = state.messages[reversedIndex];
        final isUser = message.role == MessageRole.user;
        
        // Check if this is the last assistant message (for animation)
        final isLastAssistantMessage = !isUser && 
            reversedIndex == state.messages.length - 1 &&
            !state.isSending;

        // Use animated bubble for the latest AI response
        if (!isUser && isLastAssistantMessage) {
          return AnimatedTextBubble(
            key: ValueKey('animated_${message.id}'),
            message: message,
            animateText: _shouldAnimateMessage(message.id),
            onAnimationComplete: () {
              _markMessageAnimated(message.id);
            },
            onSpeak: () => _speakText(message.content),
            isSpeaking: _isSpeaking,
          );
        }

        return MessageBubble(
          message: message,
          isUser: isUser,
          onSpeak: isUser ? null : () => _speakText(message.content),
          isSpeaking: _isSpeaking,
        );
      },
    );
  }

  // Track which messages have been animated
  final Set<String> _animatedMessageIds = {};

  bool _shouldAnimateMessage(String messageId) {
    return !_animatedMessageIds.contains(messageId);
  }

  void _markMessageAnimated(String messageId) {
    _animatedMessageIds.add(messageId);
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  void _handleSendMessage(String content) {
    if (content.trim().isEmpty) return;
    ref.read(chatNotifierProvider.notifier).sendMessage(content);
  }
  
  void _handleSendWithAttachment(String message, File? image, File? video) {
    if (image != null) {
      // Send message with image
      ref.read(chatNotifierProvider.notifier).sendMessageWithImage(
        message.isEmpty ? 'Analyze this image' : message,
        image,
      );
    } else if (video != null) {
      // Send message with video
      ref.read(chatNotifierProvider.notifier).sendMessageWithVideo(
        message.isEmpty ? 'Analyze this video' : message,
        video,
      );
    } else if (message.isNotEmpty) {
      ref.read(chatNotifierProvider.notifier).sendMessage(message);
    }
  }

  void _startNewChat() {
    ref.read(chatNotifierProvider.notifier).startNewConversation();
    setState(() {
      _currentConversationId = null;
      _conversationTitle = 'New Chat';
    });
    _animatedMessageIds.clear();
  }

  void _showRenameDialog() {
    if (_currentConversationId == null) return;
    
    final controller = TextEditingController(text: _conversationTitle);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Chat Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && _currentConversationId != null) {
                await ref.read(conversationNotifierProvider.notifier)
                    .renameConversation(_currentConversationId!, newTitle);
                setState(() => _conversationTitle = newTitle);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    if (_currentConversationId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_currentConversationId != null) {
                await ref.read(conversationNotifierProvider.notifier)
                    .deleteConversation(_currentConversationId!);
                _startNewChat();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
