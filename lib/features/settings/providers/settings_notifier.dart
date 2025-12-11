import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/settings_models.dart';
import '../services/settings_service.dart';
import 'settings_state.dart';

/// Provider for SettingsService
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsServiceImpl();
});

/// Provider for SettingsNotifier
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return SettingsNotifier(settingsService);
});

/// Notifier for managing settings state
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._settingsService) : super(const SettingsState.initial());

  final SettingsService _settingsService;

  /// Load settings and usage stats
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final settings = await _settingsService.getSettings();
      final usageStats = await _settingsService.getUsageStats();

      final showQuotaWarning = _settingsService.isNearQuotaLimit(usageStats);
      final isQuotaExceeded = _settingsService.isQuotaExceeded(usageStats);

      state = state.copyWith(
        settings: settings,
        usageStats: usageStats,
        isLoading: false,
        showQuotaWarning: showQuotaWarning,
        isQuotaExceeded: isQuotaExceeded,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  /// Refresh usage stats only
  Future<void> refreshUsageStats() async {
    try {
      final usageStats = await _settingsService.getUsageStats();

      final showQuotaWarning = _settingsService.isNearQuotaLimit(usageStats);
      final isQuotaExceeded = _settingsService.isQuotaExceeded(usageStats);

      state = state.copyWith(
        usageStats: usageStats,
        showQuotaWarning: showQuotaWarning,
        isQuotaExceeded: isQuotaExceeded,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to refresh usage stats: $e');
    }
  }

  /// Toggle TTS setting
  Future<void> toggleTts() async {
    final newSettings = state.settings.copyWith(
      ttsEnabled: !state.settings.ttsEnabled,
    );
    await updateSettings(newSettings);
  }

  /// Toggle dark mode setting
  Future<void> toggleDarkMode() async {
    final newSettings = state.settings.copyWith(
      darkMode: !state.settings.darkMode,
    );
    await updateSettings(newSettings);
  }

  /// Update preferred voice
  Future<void> setPreferredVoice(String? voice) async {
    final newSettings = state.settings.copyWith(
      preferredVoice: voice,
    );
    await updateSettings(newSettings);
  }

  /// Update settings
  Future<void> updateSettings(UserSettings settings) async {
    // Optimistically update state
    final previousSettings = state.settings;
    state = state.copyWith(settings: settings);

    try {
      await _settingsService.updateSettings(settings);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(
        settings: previousSettings,
        error: 'Failed to save settings: $e',
      );
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _settingsService.deleteAccount();
      state = const SettingsState.initial();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: $e',
      );
      return false;
    }
  }

  /// Check if a request should be blocked due to quota
  bool shouldBlockRequest() {
    return state.isQuotaExceeded;
  }

  /// Clear any error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Dismiss quota warning
  void dismissQuotaWarning() {
    state = state.copyWith(showQuotaWarning: false);
  }
}
