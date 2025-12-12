/// Environment configuration for the Multimodal AI Assistant
/// FREE APIs Only Version
/// 
/// This class provides type-safe access to environment variables.
library;

/// Environment configuration singleton
class EnvConfig {
  EnvConfig._();
  
  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;
  
  final Map<String, String> _config = {};
  
  /// Initialize configuration from a map
  void initialize(Map<String, String> config) {
    _config.clear();
    _config.addAll(config);
  }
  
  String getString(String key) {
    final value = _config[key];
    if (value == null || value.isEmpty) {
      throw EnvConfigException('Missing required environment variable: $key');
    }
    return value;
  }
  
  String getStringOrDefault(String key, String defaultValue) {
    return _config[key]?.isNotEmpty == true ? _config[key]! : defaultValue;
  }
  
  String? getStringOrNull(String key) {
    final value = _config[key];
    return value?.isNotEmpty == true ? value : null;
  }
  
  int getInt(String key) {
    final value = getString(key);
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw EnvConfigException('Invalid integer for $key: $value');
    }
    return parsed;
  }
  
  int getIntOrDefault(String key, int defaultValue) {
    final value = _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  double getDouble(String key) {
    final value = getString(key);
    final parsed = double.tryParse(value);
    if (parsed == null) {
      throw EnvConfigException('Invalid double for $key: $value');
    }
    return parsed;
  }
  
  double getDoubleOrDefault(String key, double defaultValue) {
    final value = _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }
  
  bool getBool(String key) {
    final value = _config[key]?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }
  
  bool getBoolOrDefault(String key, bool defaultValue) {
    final value = _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
    return defaultValue;
  }

  // ===========================================
  // Backend API Configuration
  // ===========================================
  
  String get apiBaseUrl => getStringOrDefault('API_BASE_URL', 'http://10.0.2.2:3000/api');
  int get apiTimeoutSeconds => getIntOrDefault('API_TIMEOUT_SECONDS', 30);
  int get apiMaxRetries => getIntOrDefault('API_MAX_RETRIES', 3);
  
  // ===========================================
  // AI Services Configuration (Google Gemini FREE)
  // ===========================================
  
  /// Chat model (Google Gemini FREE)
  String get aiChatModel => getStringOrDefault('AI_CHAT_MODEL', 'gemini-1.5-flash');
  
  /// Vision model (Google Gemini FREE)
  String get visionModel => getStringOrDefault('VISION_MODEL', 'gemini-1.5-flash');
  
  // ===========================================
  // File Upload Limits
  // ===========================================
  
  int get maxImageSizeMB => getIntOrDefault('MAX_IMAGE_SIZE_MB', 5);
  int get maxVideoSizeMB => getIntOrDefault('MAX_VIDEO_SIZE_MB', 100);
  int get maxVideoDurationSeconds => getIntOrDefault('MAX_VIDEO_DURATION_SECONDS', 300);
  
  // ===========================================
  // Quota Settings
  // ===========================================
  
  int get defaultQuotaLimit => getIntOrDefault('DEFAULT_QUOTA_LIMIT', 100);
  double get quotaWarningThreshold => getDoubleOrDefault('QUOTA_WARNING_THRESHOLD', 0.80);
  
  // ===========================================
  // App Configuration
  // ===========================================
  
  String get appName => getStringOrDefault('APP_NAME', 'Multimodal AI Assistant');
  String get appVersion => getStringOrDefault('APP_VERSION', '1.0.0');
  String get appEnvironment => getStringOrDefault('APP_ENVIRONMENT', 'development');
  bool get debugMode => getBoolOrDefault('DEBUG_MODE', false);
  
  bool get isProduction => appEnvironment.toLowerCase() == 'production';
  bool get isDevelopment => appEnvironment.toLowerCase() == 'development';
}

/// Exception thrown when environment configuration is invalid
class EnvConfigException implements Exception {
  const EnvConfigException(this.message);
  final String message;
  
  @override
  String toString() => 'EnvConfigException: $message';
}
