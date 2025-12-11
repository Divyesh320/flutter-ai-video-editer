import 'package:equatable/equatable.dart';

import '../../../core/models/settings_models.dart';

/// State for settings management
class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const UserSettings(),
    this.usageStats,
    this.isLoading = false,
    this.error,
    this.showQuotaWarning = false,
    this.isQuotaExceeded = false,
  });

  /// Current user settings
  final UserSettings settings;

  /// Current usage statistics
  final UsageStats? usageStats;

  /// Whether settings are being loaded/saved
  final bool isLoading;

  /// Error message if any
  final String? error;

  /// Whether to show quota warning (>= 80%)
  final bool showQuotaWarning;

  /// Whether quota is exceeded (>= 100%)
  final bool isQuotaExceeded;

  /// Initial state
  const SettingsState.initial()
      : settings = const UserSettings(),
        usageStats = null,
        isLoading = false,
        error = null,
        showQuotaWarning = false,
        isQuotaExceeded = false;

  /// Loading state
  SettingsState.loading()
      : settings = const UserSettings(),
        usageStats = null,
        isLoading = true,
        error = null,
        showQuotaWarning = false,
        isQuotaExceeded = false;

  /// Check if there's an error
  bool get hasError => error != null;

  /// Check if usage stats are loaded
  bool get hasUsageStats => usageStats != null;

  SettingsState copyWith({
    UserSettings? settings,
    UsageStats? usageStats,
    bool? isLoading,
    String? error,
    bool? showQuotaWarning,
    bool? isQuotaExceeded,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      usageStats: usageStats ?? this.usageStats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showQuotaWarning: showQuotaWarning ?? this.showQuotaWarning,
      isQuotaExceeded: isQuotaExceeded ?? this.isQuotaExceeded,
    );
  }

  @override
  List<Object?> get props => [
        settings,
        usageStats,
        isLoading,
        error,
        showQuotaWarning,
        isQuotaExceeded,
      ];
}
