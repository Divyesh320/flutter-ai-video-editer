import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../services/chat_service.dart';
import 'chat_state.dart';

/// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    config: const ApiConfig(baseUrl: 'https://api.example.com'),
  );
});

/// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
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

  /// Load messages for a conversation
  Future<void> loadConversation(String conversationId) async {
    state = const ChatState.loading();

    try {
      final conversation = await _chatService.getConversation(conversationId);
      state = ChatState.loaded(
        messages: conversation.messages,
        conversationId: conversationId,
      );
    } catch (e) {
      state = ChatState.error(_getErrorMessage(e));
    }
  }


  /// Send a message with optimistic update
  Future<void> sendMessage(String content) async {
    if (state.conversationId == null) {
      state = ChatState.error('No conversation selected');
      return;
    }

    // Create optimistic user message
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: state.conversationId!,
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
          conversationId: state.conversationId!,
          message: content,
        ),
      );

      // Create assistant message from response
      final assistantMessage = Message(
        id: response.jobId,
        conversationId: state.conversationId!,
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

  /// Start a new conversation
  Future<void> startNewConversation() async {
    state = const ChatState.loading();

    try {
      final conversation = await _chatService.createConversation();
      state = ChatState.loaded(
        messages: [],
        conversationId: conversation.id,
      );
    } catch (e) {
      state = ChatState.error(_getErrorMessage(e));
    }
  }

  /// Clear current conversation
  void clearConversation() {
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
