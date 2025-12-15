import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../auth/providers/auth_notifier.dart';
import '../services/chat_service.dart';
import 'chat_state.dart';

/// Provider for ApiService - uses environment config and shares auth token
final chatApiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService(
    config: ApiConfig.fromEnv(),
  );
  
  // Get auth service and copy token if available
  final authService = ref.watch(authServiceProvider);
  
  // Set up token sync - when auth changes, update chat api service
  authService.getStoredToken().then((token) {
    if (token != null) {
      apiService.setToken(token);
    }
  });
  
  return apiService;
});

/// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return ChatServiceImpl(apiService: apiService);
});

/// Provider for ChatNotifier
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService);
});

/// Notifier for managing chat state
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._chatService) : super(const ChatState.initial());

  final ChatService _chatService;
  final _uuid = const Uuid();
  String? _currentConversationId;

  /// Create new conversation via backend
  Future<void> startNewConversation() async {
    state = const ChatState.loading();
    
    try {
      final conversation = await _chatService.createConversation();
      _currentConversationId = conversation.id;
      
      state = ChatState.loaded(
        messages: [],
        conversationId: conversation.id,
      );
    } catch (e) {
      // Fallback to local conversation
      final localId = _uuid.v4();
      _currentConversationId = localId;
      
      state = ChatState.loaded(
        messages: [],
        conversationId: localId,
      );
    }
  }

  /// Load messages for a conversation from backend
  Future<void> loadConversation(String conversationId) async {
    state = const ChatState.loading();
    _currentConversationId = conversationId;

    try {
      final conversation = await _chatService.getConversation(conversationId);
      
      state = ChatState.loaded(
        messages: conversation.messages,
        conversationId: conversationId,
      );
    } catch (e) {
      // Start fresh if load fails
      state = ChatState.loaded(
        messages: [],
        conversationId: conversationId,
      );
    }
  }

  /// Send a message with optimistic update
  Future<void> sendMessage(String content) async {
    // Auto-create conversation if none exists
    if (state.conversationId == null || _currentConversationId == null) {
      await startNewConversation();
    }

    final conversationId = state.conversationId ?? _currentConversationId!;

    // Create optimistic user message
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: content,
      type: MessageType.text,
      createdAt: DateTime.now(),
    );

    // Add user message optimistically
    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isSending: true,
    );

    try {
      final response = await _chatService.sendMessage(
        ChatRequest(
          conversationId: conversationId,
          message: content,
        ),
      );

      // Create assistant message from response
      final assistantMessage = Message(
        id: response.jobId.isNotEmpty ? response.jobId : _uuid.v4(),
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: response.response,
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      // Add assistant message
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );

      // Fetch suggestions in background (don't await)
      _fetchSuggestions(content, response.response);
    } on OfflineException {
      // Message queued for later, keep optimistic update
      state = state.copyWith(isSending: false);
    } catch (e) {
      // Remove optimistic message on error
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != userMessage.id).toList(),
        isSending: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Clear current conversation
  void clearConversation() {
    _currentConversationId = null;
    state = const ChatState.initial();
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = const ChatState.initial();
    } else {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Fetch AI-powered suggestions based on last message
  Future<void> _fetchSuggestions(String lastMessage, String lastResponse) async {
    try {
      final suggestions = await _chatService.getSuggestions(lastMessage, lastResponse);
      if (suggestions.isNotEmpty) {
        state = state.copyWith(suggestions: suggestions);
      }
    } catch (e) {
      // Ignore errors - suggestions are optional
    }
  }

  /// Clear suggestions
  void clearSuggestions() {
    state = state.copyWith(suggestions: []);
  }

  /// Send message with image attachment
  Future<void> sendMessageWithImage(String content, File imageFile) async {
    if (state.conversationId == null || _currentConversationId == null) {
      await startNewConversation();
    }

    final conversationId = state.conversationId ?? _currentConversationId!;

    // Create optimistic user message with image path in metadata
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: content.isEmpty ? 'Analyze this image' : content,
      type: MessageType.image,
      metadata: {'imagePath': imageFile.path},
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isSending: true,
    );

    try {
      final response = await _chatService.sendMessageWithImage(
        conversationId: conversationId,
        message: content.isEmpty ? 'Analyze this image' : content,
        imageFile: imageFile,
      );

      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: response.response,
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != userMessage.id).toList(),
        isSending: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Send message with video attachment
  Future<void> sendMessageWithVideo(String content, File videoFile) async {
    if (state.conversationId == null || _currentConversationId == null) {
      await startNewConversation();
    }

    final conversationId = state.conversationId ?? _currentConversationId!;

    // Create optimistic user message with video path in metadata
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: content.isEmpty ? 'Analyze this video' : content,
      type: MessageType.video,
      metadata: {'videoPath': videoFile.path},
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: updatedMessages,
      isSending: true,
    );

    try {
      final response = await _chatService.sendMessageWithVideo(
        conversationId: conversationId,
        message: content.isEmpty ? 'Analyze this video' : content,
        videoFile: videoFile,
      );

      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: response.response,
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != userMessage.id).toList(),
        isSending: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is OfflineException) {
      return 'You are offline. Message will be sent when connected.';
    }
    if (error is ApiException) {
      return error.message;
    }
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
