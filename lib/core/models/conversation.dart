import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'message.dart';

part 'conversation.g.dart';

/// Conversation model representing a chat thread
@JsonSerializable()
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  /// Unique conversation identifier
  final String id;

  /// ID of the user who owns this conversation
  @JsonKey(name: 'user_id')
  final String userId;

  /// Conversation title (auto-generated from first response)
  final String? title;

  /// Conversation creation timestamp
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Last activity timestamp
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// List of messages in this conversation
  final List<Message> messages;

  /// Creates a Conversation from JSON map
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  /// Converts Conversation to JSON map
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  /// Creates a copy of Conversation with optional field overrides
  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  /// Returns the last message preview (truncated)
  String? get lastMessagePreview {
    if (messages.isEmpty) return null;
    final lastContent = messages.last.content;
    return lastContent.length > 50
        ? '${lastContent.substring(0, 50)}...'
        : lastContent;
  }

  /// Returns message count
  int get messageCount => messages.length;

  @override
  List<Object?> get props =>
      [id, userId, title, createdAt, updatedAt, messages];
}
