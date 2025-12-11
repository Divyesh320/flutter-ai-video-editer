import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/models/settings_models.dart';
import '../../../core/services/api_service.dart';

/// Abstract interface for settings operations
abstract class SettingsService {
  /// Get user usage statistics
  Future<UsageStats> getUsageStats();

  /// Update user settings
  Future<void> updateSettings(UserSettings settings);

  /// Get current user settings
  Future<UserSettings> getSettings();

  /// Delete user account and all associated data
  Future<void> deleteAccount();

  /// Check if user is near quota limit (>= 80%)
  bool isNearQuotaLimit(UsageStats stats);

  /// Check if user has exceeded quota
  bool isQuotaExceeded(UsageStats stats);

  /// Clear all local data (for account deletion)
  Future<void> clearLocalData();
}

/// Implementation of SettingsService
class SettingsServiceImpl implements SettingsService {
  SettingsServiceImpl({
    ApiService? apiService,
    FlutterSecureStorage? secureStorage,
  })  : _apiService = apiService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiService? _apiService;
  final FlutterSecureStorage _secureStorage;

  static const _settingsKey = 'user_settings';
  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  @override
  Future<UsageStats> getUsageStats() async {
    if (_apiService == null) {
      // Return mock data for testing/development
      return UsageStats(
        messageCount: 50,
        mediaUploads: 10,
        quotaLimit: 100,
        quotaUsed: 60,
        resetDate: DateTime.now().add(const Duration(days: 30)),
      );
    }

    final response = await _apiService!.get<Map<String, dynamic>>('/user/usage');
    return UsageStats.fromJson(response.data!);
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    // Persist locally first
    await _persistSettingsLocally(settings);

    // Then sync to server if available
    if (_apiService != null) {
      await _apiService!.put<Map<String, dynamic>>(
        '/user/settings',
        data: settings.toJson(),
      );
    }
  }

  @override
  Future<UserSettings> getSettings() async {
    // Try to get from local storage first
    final storedSettings = await _secureStorage.read(key: _settingsKey);
    if (storedSettings != null) {
      try {
        return _parseSettings(storedSettings);
      } catch (_) {
        // If parsing fails, return defaults
      }
    }
    return const UserSettings();
  }

  @override
  Future<void> deleteAccount() async {
    // Call API to delete account on server
    if (_apiService != null) {
      await _apiService!.delete<Map<String, dynamic>>('/user/delete');
    }

    // Clear all local data
    await clearLocalData();
  }

  @override
  bool isNearQuotaLimit(UsageStats stats) {
    return stats.usagePercentage >= 0.80;
  }

  @override
  bool isQuotaExceeded(UsageStats stats) {
    return stats.quotaUsed >= stats.quotaLimit;
  }

  @override
  Future<void> clearLocalData() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _settingsKey);
  }

  Future<void> _persistSettingsLocally(UserSettings settings) async {
    final json = settings.toJson();
    await _secureStorage.write(
      key: _settingsKey,
      value: _encodeSettings(json),
    );
  }

  String _encodeSettings(Map<String, dynamic> json) {
    // Simple encoding: key=value pairs separated by |
    final parts = <String>[];
    parts.add('tts_enabled=${json['tts_enabled']}');
    parts.add('dark_mode=${json['dark_mode']}');
    if (json['preferred_voice'] != null) {
      parts.add('preferred_voice=${json['preferred_voice']}');
    }
    return parts.join('|');
  }

  UserSettings _parseSettings(String encoded) {
    final parts = encoded.split('|');
    final map = <String, String>{};
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        map[kv[0]] = kv[1];
      }
    }
    return UserSettings(
      ttsEnabled: map['tts_enabled'] == 'true',
      darkMode: map['dark_mode'] == 'true',
      preferredVoice: map['preferred_voice'],
    );
  }
}
