import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

/// Role of the message sender
enum MessageRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('system')
  system,
}

/// Type of message content
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
}

/// Message model representing a single message in a conversation
@JsonSerializable()
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
  @JsonKey(name: 'conversation_id')
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
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Creates a Message from JSON map
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  /// Converts Message to JSON map
  Map<String, dynamic> toJson() => _$MessageToJson(this);

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
@JsonSerializable()
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
  factory MediaReference.fromJson(Map<String, dynamic> json) =>
      _$MediaReferenceFromJson(json);

  /// Converts MediaReference to JSON map
  Map<String, dynamic> toJson() => _$MediaReferenceToJson(this);

  @override
  List<Object?> get props => [id, url, type, analysis, transcript];
}

/// Type of media asset
enum MediaType {
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
}
