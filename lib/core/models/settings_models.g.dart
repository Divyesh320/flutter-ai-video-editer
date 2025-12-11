// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailDraft _$EmailDraftFromJson(Map<String, dynamic> json) => EmailDraft(
  subject: json['subject'] as String,
  body: json['body'] as String,
  conversationId: json['conversation_id'] as String,
);

Map<String, dynamic> _$EmailDraftToJson(EmailDraft instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'body': instance.body,
      'conversation_id': instance.conversationId,
    };

UsageStats _$UsageStatsFromJson(Map<String, dynamic> json) => UsageStats(
  messageCount: (json['message_count'] as num).toInt(),
  mediaUploads: (json['media_uploads'] as num).toInt(),
  quotaLimit: (json['quota_limit'] as num).toInt(),
  quotaUsed: (json['quota_used'] as num).toInt(),
  resetDate: DateTime.parse(json['reset_date'] as String),
);

Map<String, dynamic> _$UsageStatsToJson(UsageStats instance) =>
    <String, dynamic>{
      'message_count': instance.messageCount,
      'media_uploads': instance.mediaUploads,
      'quota_limit': instance.quotaLimit,
      'quota_used': instance.quotaUsed,
      'reset_date': instance.resetDate.toIso8601String(),
    };

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
  ttsEnabled: json['tts_enabled'] as bool? ?? false,
  preferredVoice: json['preferred_voice'] as String?,
  darkMode: json['dark_mode'] as bool? ?? false,
);

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'tts_enabled': instance.ttsEnabled,
      if (instance.preferredVoice case final value?) 'preferred_voice': value,
      'dark_mode': instance.darkMode,
    };
