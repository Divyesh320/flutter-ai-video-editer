import 'package:equatable/equatable.dart';

import '../../../core/models/models.dart';

/// Conversation list state status types
enum ConversationListStatus {
  /// Initial state
  initial,

  /// Loading conversations
  loading,

  /// Conversations loaded successfully
  loaded,

  /// Error occurred
  error,
}

/// Conversation list state
class ConversationListState extends Equatable {
  const ConversationListState({
    this.status = ConversationListStatus.initial,
    this.conversations = const [],
    this.selectedConversationId,
    this.errorMessage,
  });

  /// Current status
  final ConversationListStatus status;

  /// List of conversations sorted by most recent
  final List<Conversation> conversations;

  /// Currently selected conversation ID
  final String? selectedConversationId;

  /// Error message if any
  final String? errorMessage;

  /// Initial state
  const ConversationListState.initial()
      : status = ConversationListStatus.initial,
        conversations = const [],
        selectedConversationId = null,
        errorMessage = null;

  /// Loading state
  const ConversationListState.loading()
      : status = ConversationListStatus.loading,
        conversations = const [],
        selectedConversationId = null,
        errorMessage = null;

  /// Loaded state with conversations
  ConversationListState.loaded({
    required List<Conversation> this.conversations,
    this.selectedConversationId,
  })  : status = ConversationListStatus.loaded,
        errorMessage = null;


  /// Error state
  ConversationListState.error(String this.errorMessage)
      : status = ConversationListStatus.error,
        conversations = const [],
        selectedConversationId = null;

  /// Whether list is loading
  bool get isLoading => status == ConversationListStatus.loading;

  /// Whether there's an error
  bool get hasError => status == ConversationListStatus.error;

  /// Whether list is ready
  bool get isReady => status == ConversationListStatus.loaded;

  /// Get selected conversation
  Conversation? get selectedConversation {
    if (selectedConversationId == null) return null;
    try {
      return conversations.firstWhere((c) => c.id == selectedConversationId);
    } catch (_) {
      return null;
    }
  }

  /// Create copy with updated fields
  ConversationListState copyWith({
    ConversationListStatus? status,
    List<Conversation>? conversations,
    String? selectedConversationId,
    String? errorMessage,
  }) {
    return ConversationListState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      selectedConversationId:
          selectedConversationId ?? this.selectedConversationId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, conversations, selectedConversationId, errorMessage];
}
