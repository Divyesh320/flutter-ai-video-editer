import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'env_config.dart';

/// Loads environment variables from .env file
class EnvLoader {
  EnvLoader._();
  
  /// Load environment configuration
  /// 
  /// Tries to load from:
  /// 1. .env file in project root (for development)
  /// 2. Compile-time environment variables (for production)
  /// 3. System environment variables
  static Future<void> load() async {
    final config = <String, String>{};
    
    // Try to load from .env file
    try {
      final envContent = await _loadEnvFile();
      if (envContent != null) {
        config.addAll(_parseEnvContent(envContent));
      }
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }
    
    // Add compile-time environment variables (from --dart-define)
    _addCompileTimeVariables(config);
    
    // Initialize the config singleton
    EnvConfig.instance.initialize(config);
  }
  
  /// Load .env file content
  static Future<String?> _loadEnvFile() async {
    // Try loading from assets first (for bundled apps)
    try {
      final content = await rootBundle.loadString('.env');
      return content;
    } catch (_) {
      // Not in assets, try file system
    }
    
    // Try loading from file system (for development)
    if (!kIsWeb) {
      try {
        final file = File('.env');
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (_) {
        // File not found or not accessible
      }
    }
    
    return null;
  }
  
  /// Parse .env file content into a map
  static Map<String, String> _parseEnvContent(String content) {
    final result = <String, String>{};
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Skip empty lines and comments
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      
      // Parse key=value
      final equalsIndex = trimmed.indexOf('=');
      if (equalsIndex > 0) {
        final key = trimmed.substring(0, equalsIndex).trim();
        var value = trimmed.substring(equalsIndex + 1).trim();
        
        // Remove quotes if present
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }
        
        // Handle inline comments
        final commentIndex = value.indexOf(' #');
        if (commentIndex > 0) {
          value = value.substring(0, commentIndex).trim();
        }
        
        result[key] = value;
      }
    }
    
    return result;
  }
  
  /// Add compile-time environment variables
  /// These are passed via --dart-define during build
  static void _addCompileTimeVariables(Map<String, String> config) {
    // API Configuration
    _addIfNotEmpty(config, 'API_BASE_URL', const String.fromEnvironment('API_BASE_URL'));
    _addIfNotEmpty(config, 'API_TIMEOUT_SECONDS', const String.fromEnvironment('API_TIMEOUT_SECONDS'));
    _addIfNotEmpty(config, 'API_MAX_RETRIES', const String.fromEnvironment('API_MAX_RETRIES'));
    
    // Authentication
    _addIfNotEmpty(config, 'JWT_SECRET_KEY', const String.fromEnvironment('JWT_SECRET_KEY'));
    _addIfNotEmpty(config, 'GOOGLE_CLIENT_ID', const String.fromEnvironment('GOOGLE_CLIENT_ID'));
    _addIfNotEmpty(config, 'GOOGLE_CLIENT_SECRET', const String.fromEnvironment('GOOGLE_CLIENT_SECRET'));
    _addIfNotEmpty(config, 'FACEBOOK_APP_ID', const String.fromEnvironment('FACEBOOK_APP_ID'));
    _addIfNotEmpty(config, 'FACEBOOK_APP_SECRET', const String.fromEnvironment('FACEBOOK_APP_SECRET'));
    
    // AI Services
    _addIfNotEmpty(config, 'OPENAI_API_KEY', const String.fromEnvironment('OPENAI_API_KEY'));
    _addIfNotEmpty(config, 'OPENAI_MODEL', const String.fromEnvironment('OPENAI_MODEL'));
    _addIfNotEmpty(config, 'GEMINI_API_KEY', const String.fromEnvironment('GEMINI_API_KEY'));
    
    // Speech Services
    _addIfNotEmpty(config, 'WHISPER_API_KEY', const String.fromEnvironment('WHISPER_API_KEY'));
    _addIfNotEmpty(config, 'TTS_API_KEY', const String.fromEnvironment('TTS_API_KEY'));
    
    // Vision API
    _addIfNotEmpty(config, 'VISION_API_KEY', const String.fromEnvironment('VISION_API_KEY'));
    _addIfNotEmpty(config, 'VISION_CONFIDENCE_THRESHOLD', const String.fromEnvironment('VISION_CONFIDENCE_THRESHOLD'));
    
    // Storage
    _addIfNotEmpty(config, 'AWS_ACCESS_KEY_ID', const String.fromEnvironment('AWS_ACCESS_KEY_ID'));
    _addIfNotEmpty(config, 'AWS_SECRET_ACCESS_KEY', const String.fromEnvironment('AWS_SECRET_ACCESS_KEY'));
    _addIfNotEmpty(config, 'AWS_REGION', const String.fromEnvironment('AWS_REGION'));
    _addIfNotEmpty(config, 'AWS_S3_BUCKET', const String.fromEnvironment('AWS_S3_BUCKET'));
    _addIfNotEmpty(config, 'FIREBASE_PROJECT_ID', const String.fromEnvironment('FIREBASE_PROJECT_ID'));
    _addIfNotEmpty(config, 'FIREBASE_STORAGE_BUCKET', const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'));
    
    // Database
    _addIfNotEmpty(config, 'DATABASE_URL', const String.fromEnvironment('DATABASE_URL'));
    _addIfNotEmpty(config, 'REDIS_URL', const String.fromEnvironment('REDIS_URL'));
    
    // Vector DB
    _addIfNotEmpty(config, 'PINECONE_API_KEY', const String.fromEnvironment('PINECONE_API_KEY'));
    _addIfNotEmpty(config, 'SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));
    _addIfNotEmpty(config, 'SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY'));
    
    // App Configuration
    _addIfNotEmpty(config, 'APP_ENVIRONMENT', const String.fromEnvironment('APP_ENVIRONMENT'));
    _addIfNotEmpty(config, 'DEBUG_MODE', const String.fromEnvironment('DEBUG_MODE'));
  }
  
  /// Add a value to config if it's not empty
  static void _addIfNotEmpty(Map<String, String> config, String key, String value) {
    if (value.isNotEmpty) {
      config[key] = value;
    }
  }
}
