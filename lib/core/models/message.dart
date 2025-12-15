import 'package:equatable/equatable.dart';

/// Role of the message sender
enum MessageRole {
  user,
  assistant,
  system,
}

/// Type of message content
enum MessageType {
  text,
  image,
  video,
  audio,
}

/// Message model representing a single message in a conversation
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.metadata,
    this.media,
    required this.createdAt,
  });

  /// Unique message identifier
  final String id;

  /// ID of the conversation this message belongs to
  final String conversationId;

  /// Role of the message sender (user, assistant, system)
  final MessageRole role;

  /// Text content of the message
  final String content;

  /// Type of message content
  final MessageType type;

  /// Additional metadata (e.g., vision results, transcription)
  final Map<String, dynamic>? metadata;

  /// Associated media assets
  final List<MediaReference>? media;

  /// Message creation timestamp
  final DateTime createdAt;

  /// Creates a Message from JSON map - matches backend format
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? 
                      json['conversation_id'] as String? ?? '',
      role: _parseRole(json['role']),
      content: json['content'] as String? ?? '',
      type: _parseType(json['type']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      media: _parseMedia(json['media']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static MessageRole _parseRole(dynamic value) {
    if (value == null) return MessageRole.user;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  static MessageType _parseType(dynamic value) {
    if (value == null) return MessageType.text;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static List<MediaReference>? _parseMedia(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value
        .map((e) => MediaReference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Converts Message to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'role': role.name,
    'content': content,
    'type': type.name,
    if (metadata != null) 'metadata': metadata,
    if (media != null) 'media': media!.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  /// Creates a copy of Message with optional field overrides
  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    MessageType? type,
    Map<String, dynamic>? metadata,
    List<MediaReference>? media,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, type, metadata, media, createdAt];
}

/// Reference to a media asset
class MediaReference extends Equatable {
  const MediaReference({
    required this.id,
    required this.url,
    required this.type,
    this.analysis,
    this.transcript,
  });

  /// Unique media identifier
  final String id;

  /// URL or S3 path to the media asset
  final String url;

  /// Type of media (image, video, audio)
  final MediaType type;

  /// Analysis results (for images)
  final Map<String, dynamic>? analysis;

  /// Transcript (for audio/video)
  final String? transcript;

  /// Creates a MediaReference from JSON map
  factory MediaReference.fromJson(Map<String, dynamic> json) {
    return MediaReference(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: _parseMediaType(json['type']),
      analysis: json['analysis'] as Map<String, dynamic>?,
      transcript: json['transcript'] as String?,
    );
  }

  static MediaType _parseMediaType(dynamic value) {
    if (value == null) return MediaType.image;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      default:
        return MediaType.image;
    }
  }

  /// Converts MediaReference to JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'type': type.name,
    if (analysis != null) 'analysis': analysis,
    if (transcript != null) 'transcript': transcript,
  };

  @override
  List<Object?> get props => [id, url, type, analysis, transcript];
}

/// Type of media asset
enum MediaType {
  image,
  video,
  audio,
}
