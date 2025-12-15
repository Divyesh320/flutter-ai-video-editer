import 'package:equatable/equatable.dart';

import 'message.dart';

/// Conversation model representing a chat thread
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
  final String userId;

  /// Conversation title (auto-generated from first response)
  final String? title;

  /// Conversation creation timestamp
  final DateTime createdAt;

  /// Last activity timestamp
  final DateTime updatedAt;

  /// List of messages in this conversation
  final List<Message> messages;

  /// Creates a Conversation from JSON map - matches backend format
  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Backend returns _id, userId, createdAt, updatedAt
    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    return Conversation(
      id: id,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      title: json['title'] as String?,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      messages: _parseMessages(json['messages'], id),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static List<Message> _parseMessages(dynamic value, [String? conversationId]) {
    if (value == null) return const [];
    if (value is! List) return const [];
    return value.map((e) {
      final map = e as Map<String, dynamic>;
      // Add conversationId if not present
      if (conversationId != null && !map.containsKey('conversationId')) {
        map['conversationId'] = conversationId;
      }
      return Message.fromJson(map);
    }).toList();
  }

  /// Converts Conversation to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    if (title != null) 'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((e) => e.toJson()).toList(),
  };

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
