// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  content: json['content'] as String,
  type:
      $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
      MessageType.text,
  metadata: json['metadata'] as Map<String, dynamic>?,
  media: (json['media'] as List<dynamic>?)
      ?.map((e) => MediaReference.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'conversation_id': instance.conversationId,
  'role': _$MessageRoleEnumMap[instance.role]!,
  'content': instance.content,
  'type': _$MessageTypeEnumMap[instance.type]!,
  if (instance.metadata case final value?) 'metadata': value,
  if (instance.media?.map((e) => e.toJson()).toList() case final value?)
    'media': value,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.video: 'video',
  MessageType.audio: 'audio',
};

MediaReference _$MediaReferenceFromJson(Map<String, dynamic> json) =>
    MediaReference(
      id: json['id'] as String,
      url: json['url'] as String,
      type: $enumDecode(_$MediaTypeEnumMap, json['type']),
      analysis: json['analysis'] as Map<String, dynamic>?,
      transcript: json['transcript'] as String?,
    );

Map<String, dynamic> _$MediaReferenceToJson(MediaReference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'type': _$MediaTypeEnumMap[instance.type]!,
      if (instance.analysis case final value?) 'analysis': value,
      if (instance.transcript case final value?) 'transcript': value,
    };

const _$MediaTypeEnumMap = {
  MediaType.image: 'image',
  MediaType.video: 'video',
  MediaType.audio: 'audio',
};
