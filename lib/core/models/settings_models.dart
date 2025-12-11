import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_models.g.dart';

/// Email draft generated from conversation
@JsonSerializable()
class EmailDraft extends Equatable {
  const EmailDraft({
    required this.subject,
    required this.body,
    required this.conversationId,
  });

  /// Email subject line
  final String subject;

  /// Email body content
  final String body;

  /// Source conversation ID
  @JsonKey(name: 'conversation_id')
  final String conversationId;

  factory EmailDraft.fromJson(Map<String, dynamic> json) =>
      _$EmailDraftFromJson(json);

  Map<String, dynamic> toJson() => _$EmailDraftToJson(this);

  /// Returns formatted email for clipboard
  String get formattedEmail => 'Subject: $subject\n\n$body';

  /// Validates draft has required content
  bool get isValid => subject.isNotEmpty && body.isNotEmpty;

  @override
  List<Object?> get props => [subject, body, conversationId];
}

/// User usage statistics
@JsonSerializable()
class UsageStats extends Equatable {
  const UsageStats({
    required this.messageCount,
    required this.mediaUploads,
    required this.quotaLimit,
    required this.quotaUsed,
    required this.resetDate,
  });

  /// Total messages sent
  @JsonKey(name: 'message_count')
  final int messageCount;

  /// Total media files uploaded
  @JsonKey(name: 'media_uploads')
  final int mediaUploads;

  /// Maximum quota allowed
  @JsonKey(name: 'quota_limit')
  final int quotaLimit;

  /// Current quota used
  @JsonKey(name: 'quota_used')
  final int quotaUsed;

  /// Date when quota resets
  @JsonKey(name: 'reset_date')
  final DateTime resetDate;

  factory UsageStats.fromJson(Map<String, dynamic> json) =>
      _$UsageStatsFromJson(json);

  Map<String, dynamic> toJson() => _$UsageStatsToJson(this);

  /// Returns remaining quota
  int get quotaRemaining => quotaLimit - quotaUsed;

  /// Returns usage percentage (0.0 to 1.0)
  double get usagePercentage =>
      quotaLimit > 0 ? quotaUsed / quotaLimit : 0.0;

  /// Returns true if user is at or above 80% quota
  bool get isNearQuotaLimit => usagePercentage >= 0.80;

  /// Returns true if user has exceeded quota
  bool get isQuotaExceeded => quotaUsed >= quotaLimit;

  @override
  List<Object?> get props =>
      [messageCount, mediaUploads, quotaLimit, quotaUsed, resetDate];
}

/// User settings and preferences
@JsonSerializable()
class UserSettings extends Equatable {
  const UserSettings({
    this.ttsEnabled = false,
    this.preferredVoice,
    this.darkMode = false,
  });

  /// Whether text-to-speech is enabled
  @JsonKey(name: 'tts_enabled')
  final bool ttsEnabled;

  /// Preferred TTS voice
  @JsonKey(name: 'preferred_voice')
  final String? preferredVoice;

  /// Dark mode preference
  @JsonKey(name: 'dark_mode')
  final bool darkMode;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  UserSettings copyWith({
    bool? ttsEnabled,
    String? preferredVoice,
    bool? darkMode,
  }) {
    return UserSettings(
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      preferredVoice: preferredVoice ?? this.preferredVoice,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  @override
  List<Object?> get props => [ttsEnabled, preferredVoice, darkMode];
}
