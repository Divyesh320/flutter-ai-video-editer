import 'package:equatable/equatable.dart';

import '../../../core/models/models.dart';

/// Chat state status types
enum ChatStatus {
  /// Initial state
  initial,

  /// Loading messages or sending
  loading,

  /// Messages loaded successfully
  loaded,

  /// Error occurred
  error,
}

/// Chat state containing messages and status
class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.conversationId,
    this.errorMessage,
    this.isSending = false,
  });

  /// Current chat status
  final ChatStatus status;

  /// List of messages in current conversation
  final List<Message> messages;

  /// Current conversation ID
  final String? conversationId;

  /// Error message if any
  final String? errorMessage;

  /// Whether a message is being sent
  final bool isSending;

  /// Initial state
  const ChatState.initial()
      : status = ChatStatus.initial,
        messages = const [],
        conversationId = null,
        errorMessage = null,
        isSending = false;

  /// Loading state
  const ChatState.loading()
      : status = ChatStatus.loading,
        messages = const [],
        conversationId = null,
        errorMessage = null,
        isSending = false;


  /// Loaded state with messages
  ChatState.loaded({
    required List<Message> this.messages,
    required String this.conversationId,
    this.isSending = false,
  })  : status = ChatStatus.loaded,
        errorMessage = null;

  /// Error state
  ChatState.error(String this.errorMessage)
      : status = ChatStatus.error,
        messages = const [],
        conversationId = null,
        isSending = false;

  /// Whether chat is loading
  bool get isLoading => status == ChatStatus.loading;

  /// Whether there's an error
  bool get hasError => status == ChatStatus.error;

  /// Whether chat is ready for interaction
  bool get isReady => status == ChatStatus.loaded;

  /// Create copy with updated fields
  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? conversationId,
    String? errorMessage,
    bool? isSending,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: errorMessage ?? this.errorMessage,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props =>
      [status, messages, conversationId, errorMessage, isSending];
}
