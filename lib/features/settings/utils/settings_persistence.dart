import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/models/settings_models.dart';

/// Utility class for persisting and retrieving user settings
class SettingsPersistence {
  SettingsPersistence({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _settingsKey = 'user_settings';

  /// Save settings to secure storage
  Future<void> saveSettings(UserSettings settings) async {
    final json = settings.toJson();
    final encoded = jsonEncode(json);
    await _secureStorage.write(key: _settingsKey, value: encoded);
  }

  /// Load settings from secure storage
  Future<UserSettings> loadSettings() async {
    final encoded = await _secureStorage.read(key: _settingsKey);
    if (encoded == null) {
      return const UserSettings();
    }

    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return UserSettings.fromJson(json);
    } catch (_) {
      // If parsing fails, return defaults
      return const UserSettings();
    }
  }

  /// Clear settings from secure storage
  Future<void> clearSettings() async {
    await _secureStorage.delete(key: _settingsKey);
  }

  /// Check if settings exist in storage
  Future<bool> hasSettings() async {
    final value = await _secureStorage.read(key: _settingsKey);
    return value != null;
  }
}
