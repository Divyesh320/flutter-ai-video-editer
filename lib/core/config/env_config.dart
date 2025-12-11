/// Environment configuration for the Multimodal AI Assistant
/// 
/// This class provides type-safe access to environment variables.
/// Values are loaded from .env file or system environment.
library;

/// Environment configuration singleton
class EnvConfig {
  EnvConfig._();
  
  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;
  
  // Internal storage for config values
  final Map<String, String> _config = {};
  
  /// Initialize configuration from a map (typically from .env file)
  void initialize(Map<String, String> config) {
    _config.clear();
    _config.addAll(config);
  }
  
  /// Get a string value, throws if not found
  String getString(String key) {
    final value = _config[key];
    if (value == null || value.isEmpty) {
      throw EnvConfigException('Missing required environment variable: $key');
    }
    return value;
  }
  
  /// Get a string value with default
  String getStringOrDefault(String key, String defaultValue) {
    return _config[key]?.isNotEmpty == true ? _config[key]! : defaultValue;
  }
  
  /// Get an optional string value
  String? getStringOrNull(String key) {
    final value = _config[key];
    return value?.isNotEmpty == true ? value : null;
  }
  
  /// Get an integer value, throws if not found or invalid
  int getInt(String key) {
    final value = getString(key);
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw EnvConfigException('Invalid integer for $key: $value');
    }
    return parsed;
  }
  
  /// Get an integer value with default
  int getIntOrDefault(String key, int defaultValue) {
    final value = _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  /// Get a double value, throws if not found or invalid
  double getDouble(String key) {
    final value = getString(key);
    final parsed = double.tryParse(value);
    if (parsed == null) {
      throw EnvConfigException('Invalid double for $key: $value');
    }
    return parsed;
  }
  
  /// Get a double value with default
  double getDoubleOrDefault(String key, double defaultValue) {
    final value = _config[key];
    if (value == null || value.isEmpty) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }
  
  /// Get a boolean value
  bool getBool(String key) {
    final value = _config[key]?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }
  
  /// Get a boolean value with default
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
  
  /// Base URL for backend API (e.g., http://10.0.2.2:3000/api for Android emulator)
  String get apiBaseUrl => getStringOrDefault('API_BASE_URL', 'http://10.0.2.2:3000/api');
  int get apiTimeoutSeconds => getIntOrDefault('API_TIMEOUT_SECONDS', 30);
  int get apiMaxRetries => getIntOrDefault('API_MAX_RETRIES', 3);
  
  // ===========================================
  // OAuth Configuration (for social login)
  // ===========================================
  
  String? get googleClientId => getStringOrNull('GOOGLE_CLIENT_ID');
  String? get facebookAppId => getStringOrNull('FACEBOOK_APP_ID');
  
  // ===========================================
  // AI Services Configuration
  // ===========================================
  
  /// Default chat model
  String get aiChatModel => getStringOrDefault('AI_CHAT_MODEL', 'gpt-4');
  
  /// Speech-to-Text model
  String get sttModel => getStringOrDefault('STT_MODEL', 'whisper-1');
  
  /// Text-to-Speech settings
  String get ttsVoice => getStringOrDefault('TTS_VOICE', 'alloy');
  String get ttsModel => getStringOrDefault('TTS_MODEL', 'tts-1');
  
  /// Vision model
  String get visionModel => getStringOrDefault('VISION_MODEL', 'gpt-4-vision-preview');
  
  /// Embedding model
  String get embeddingModel => getStringOrDefault('EMBEDDING_MODEL', 'text-embedding-ada-002');
  
  // ===========================================
  // File Upload Limits
  // ===========================================
  
  int get maxImageSizeMB => getIntOrDefault('MAX_IMAGE_SIZE_MB', 5);
  int get maxAudioSizeMB => getIntOrDefault('MAX_AUDIO_SIZE_MB', 25);
  int get maxAudioDurationMinutes => getIntOrDefault('MAX_AUDIO_DURATION_MINUTES', 10);
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
  
  String? get privacyPolicyUrl => getStringOrNull('PRIVACY_POLICY_URL');
  String? get termsOfServiceUrl => getStringOrNull('TERMS_OF_SERVICE_URL');
  
  /// Check if running in production
  bool get isProduction => appEnvironment.toLowerCase() == 'production';
  
  /// Check if running in development
  bool get isDevelopment => appEnvironment.toLowerCase() == 'development';
}

/// Exception thrown when environment configuration is invalid
class EnvConfigException implements Exception {
  const EnvConfigException(this.message);
  final String message;
  
  @override
  String toString() => 'EnvConfigException: $message';
}
