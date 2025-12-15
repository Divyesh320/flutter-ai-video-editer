import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../services/chat_service.dart';
import 'chat_notifier.dart';
import 'conversation_state.dart';

/// Provider for ConversationNotifier
final conversationNotifierProvider =
    StateNotifierProvider<ConversationNotifier, ConversationListState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ConversationNotifier(chatService);
});

/// Notifier for managing conversation list
class ConversationNotifier extends StateNotifier<ConversationListState> {
  ConversationNotifier(this._chatService)
      : super(const ConversationListState.initial());

  final ChatService _chatService;

  /// Load all conversations for the current user from backend
  Future<void> loadConversations() async {
    state = const ConversationListState.loading();

    try {
      final conversations = await _chatService.getConversations();
      
      // Sort by most recent
      final sorted = List<Conversation>.from(conversations)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = ConversationListState.loaded(
        conversations: sorted,
        selectedConversationId: state.selectedConversationId,
      );
    } catch (e) {
      // If backend fails, use empty list
      state = ConversationListState.loaded(
        conversations: const [],
        selectedConversationId: null,
      );
    }
  }

  /// Create a new conversation via backend
  Future<Conversation?> createConversation() async {
    try {
      final conversation = await _chatService.createConversation();

      // Add to list and select it
      final updated = [conversation, ...state.conversations];
      state = state.copyWith(
        conversations: updated,
        selectedConversationId: conversation.id,
      );

      return conversation;
    } catch (e) {
      // Fallback to local conversation
      final conversation = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'local-user',
        title: 'New Chat',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = [conversation, ...state.conversations];
      state = state.copyWith(
        conversations: updated,
        selectedConversationId: conversation.id,
      );

      return conversation;
    }
  }


  /// Select a conversation
  void selectConversation(String conversationId) {
    state = state.copyWith(selectedConversationId: conversationId);
  }

  /// Rename a conversation
  Future<void> renameConversation(String conversationId, String newTitle) async {
    try {
      await _chatService.renameConversation(conversationId, newTitle);

      // Update in list
      final index = state.conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final updated = List<Conversation>.from(state.conversations);
        updated[index] = updated[index].copyWith(title: newTitle);
        state = state.copyWith(conversations: updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: _getErrorMessage(e));
    }
  }

  /// Delete a conversation and all associated data
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _chatService.deleteConversation(conversationId);

      // Remove from list
      final updated =
          state.conversations.where((c) => c.id != conversationId).toList();

      // Clear selection if deleted conversation was selected
      final newSelectedId = state.selectedConversationId == conversationId
          ? null
          : state.selectedConversationId;

      state = state.copyWith(
        conversations: updated,
        selectedConversationId: newSelectedId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: _getErrorMessage(e));
    }
  }

  /// Update a conversation in the list (e.g., after new message)
  void updateConversation(Conversation conversation) {
    final index = state.conversations.indexWhere((c) => c.id == conversation.id);
    if (index == -1) return;

    final updated = List<Conversation>.from(state.conversations);
    updated[index] = conversation;

    // Re-sort by most recent
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    state = state.copyWith(conversations: updated);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(selectedConversationId: null);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
      if (message.contains('Network')) {
        return 'Network error. Please check your connection.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
