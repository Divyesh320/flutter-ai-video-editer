import 'dart:io';

import 'api_service.dart';
import 'api_exceptions.dart';

/// Response from Vision API (Google Gemini FREE)
class VisionResponse {
  const VisionResponse({
    required this.description,
    required this.jobId,
    this.confidence,
  });

  factory VisionResponse.fromJson(Map<String, dynamic> json) {
    return VisionResponse(
      description: json['description'] as String? ?? json['analysis'] as String? ?? '',
      jobId: json['jobId'] as String? ?? json['_id'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  final String description;
  final String jobId;
  final double? confidence;
}

/// Chat response from AI
class ChatResponse {
  const ChatResponse({
    required this.response,
    required this.jobId,
    this.tokensUsed,
    this.model,
    this.conversationId,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      tokensUsed: json['tokensUsed'] as int?,
      model: json['model'] as String?,
      conversationId: json['conversationId'] as String?,
    );
  }

  final String response;
  final String jobId;
  final int? tokensUsed;
  final String? model;
  final String? conversationId;
}

/// AI Service - FREE APIs Only
/// 
/// Features:
/// - Chat completion (Google Gemini FREE)
/// - Image analysis (Google Gemini Vision FREE)
/// 
/// Removed (PAID):
/// - Speech-to-Text (OpenAI Whisper)
/// - Text-to-Speech (OpenAI TTS)
/// - Embeddings (OpenAI)
class AIService {
  AIService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  // ===========================================
  // Chat Completion (Google Gemini FREE)
  // ===========================================

  /// Send chat message to AI
  Future<ChatResponse> chat({
    required String message,
    String? conversationId,
    int? maxTokens,
    double? temperature,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/ai/chat',
        data: {
          'message': message,
          if (conversationId != null) 'conversationId': conversationId,
          if (maxTokens != null) 'maxTokens': maxTokens,
          if (temperature != null) 'temperature': temperature,
        },
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to send chat message: $e');
    }
  }

  // ===========================================
  // Vision (Image Analysis) - Google Gemini FREE
  // ===========================================

  /// Analyze image with AI Vision
  Future<VisionResponse> analyzeImage({
    required File imageFile,
    String? prompt,
  }) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/ai/analyze-image',
        imageFile.path,
        fieldName: 'image',
        additionalFields: prompt != null ? {'prompt': prompt} : null,
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return VisionResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to analyze image: $e');
    }
  }

  // ===========================================
  // AI Jobs
  // ===========================================

  /// Get AI job history
  Future<List<Map<String, dynamic>>> getJobs({
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/ai/jobs',
        queryParameters: {
          if (type != null) 'type': type,
          if (status != null) 'status': status,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data!['data'] ?? [];
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get AI jobs: $e');
    }
  }

  /// Get specific AI job details
  Future<Map<String, dynamic>> getJob(String jobId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/ai/jobs/$jobId',
      );

      if (response.data == null) {
        throw ApiException('Job not found');
      }

      return response.data!['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get AI job: $e');
    }
  }

  /// Get available AI providers info
  Future<Map<String, dynamic>> getProviders() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/ai/providers',
      );

      if (response.data == null) {
        return {};
      }

      return response.data!['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get AI providers: $e');
    }
  }
}
