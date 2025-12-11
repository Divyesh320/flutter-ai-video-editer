import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_service.dart';
import 'api_exceptions.dart';

/// Response from Speech-to-Text API
class TranscriptionResponse {
  const TranscriptionResponse({
    required this.text,
    required this.jobId,
    this.duration,
    this.language,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      text: json['text'] as String? ?? json['transcription'] as String? ?? '',
      jobId: json['jobId'] as String? ?? json['_id'] as String? ?? '',
      duration: (json['duration'] as num?)?.toDouble(),
      language: json['language'] as String?,
    );
  }

  final String text;
  final String jobId;
  final double? duration;
  final String? language;
}

/// Response from Vision API
class VisionResponse {
  const VisionResponse({
    required this.description,
    required this.jobId,
    this.labels,
    this.confidence,
  });

  factory VisionResponse.fromJson(Map<String, dynamic> json) {
    return VisionResponse(
      description: json['description'] as String? ?? json['analysis'] as String? ?? '',
      jobId: json['jobId'] as String? ?? json['_id'] as String? ?? '',
      labels: (json['labels'] as List?)?.cast<String>(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  final String description;
  final String jobId;
  final List<String>? labels;
  final double? confidence;
}

/// Response from Embedding API
class EmbeddingResponse {
  const EmbeddingResponse({
    required this.id,
    required this.embedding,
    this.tokensUsed,
  });

  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    return EmbeddingResponse(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      embedding: (json['embedding'] as List?)?.cast<double>() ?? [],
      tokensUsed: json['tokensUsed'] as int?,
    );
  }

  final String id;
  final List<double> embedding;
  final int? tokensUsed;
}

/// Search result from semantic search
class SearchResult {
  const SearchResult({
    required this.id,
    required this.text,
    required this.score,
    this.metadata,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String text;
  final double score;
  final Map<String, dynamic>? metadata;
}

/// AI Service for Speech-to-Text, Text-to-Speech, Vision, and Embeddings
class AIService {
  AIService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  // ===========================================
  // Speech-to-Text (Whisper)
  // ===========================================

  /// Transcribe audio file to text
  Future<TranscriptionResponse> transcribeAudio(File audioFile) async {
    try {
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/ai/speech-to-text',
        audioFile.path,
        fieldName: 'audio',
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return TranscriptionResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to transcribe audio: $e');
    }
  }

  // ===========================================
  // Text-to-Speech
  // ===========================================

  /// Synthesize speech from text
  /// Returns audio bytes (MP3 format)
  Future<Uint8List> synthesizeSpeech({
    required String text,
    String voice = 'alloy',
  }) async {
    try {
      final response = await _apiService.post<List<int>>(
        '/ai/text-to-speech',
        data: {'text': text, 'voice': voice},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      return Uint8List.fromList(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to synthesize speech: $e');
    }
  }

  // ===========================================
  // Vision (Image Analysis)
  // ===========================================

  /// Analyze image with GPT-4 Vision
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
  // Embeddings
  // ===========================================

  /// Create text embedding
  Future<EmbeddingResponse> createEmbedding({
    required String text,
    bool autoChunk = true,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/embeddings/create',
        data: {
          'text': text,
          'autoChunk': autoChunk,
          if (metadata != null) 'metadata': metadata,
        },
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      final data = response.data!['data'] ?? response.data!;
      return EmbeddingResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create embedding: $e');
    }
  }

  /// Semantic search for similar content
  Future<List<SearchResult>> searchSimilar({
    required String query,
    int limit = 10,
    double threshold = 0.7,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/embeddings/search',
        data: {
          'query': query,
          'limit': limit,
          'threshold': threshold,
        },
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data!['data'] ?? response.data!;
      final results = data['results'] as List? ?? [];
      return results
          .map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to search: $e');
    }
  }

  /// Get user's embeddings
  Future<List<Map<String, dynamic>>> getEmbeddings({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/embeddings',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data!['data'] ?? [];
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get embeddings: $e');
    }
  }

  /// Get embedding statistics
  Future<Map<String, dynamic>> getEmbeddingStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/embeddings/stats',
      );

      if (response.data == null) {
        return {};
      }

      return response.data!['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get embedding stats: $e');
    }
  }

  /// Delete embedding
  Future<void> deleteEmbedding(String id) async {
    try {
      await _apiService.delete<void>('/embeddings/$id');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete embedding: $e');
    }
  }

  /// Bulk delete embeddings
  Future<void> bulkDeleteEmbeddings(List<String> ids) async {
    try {
      await _apiService.post<void>(
        '/embeddings/bulk-delete',
        data: {'ids': ids},
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete embeddings: $e');
    }
  }
}
