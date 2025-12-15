import '../../../core/services/services.dart';

/// Response from a single AI model
class ModelResponse {
  const ModelResponse({
    required this.model,
    required this.provider,
    required this.content,
    required this.responseTime,
    this.tokensUsed = 0,
    this.isBest = false,
    this.error,
  });

  factory ModelResponse.fromJson(Map<String, dynamic> json) {
    return ModelResponse(
      model: json['model'] as String? ?? json['displayName'] as String? ?? 'Unknown',
      provider: json['provider'] as String? ?? '',
      content: json['content'] as String? ?? '',
      responseTime: json['responseTime'] as int? ?? 0,
      tokensUsed: json['tokensUsed'] as int? ?? 0,
      isBest: json['isBest'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  final String model;
  final String provider;
  final String content;
  final int responseTime;
  final int tokensUsed;
  final bool isBest;
  final String? error;

  bool get hasError => error != null;
}

/// Multi-model comparison result
class MultiModelResult {
  const MultiModelResult({
    required this.responses,
    required this.failed,
    required this.totalTime,
    this.bestResponse,
  });

  factory MultiModelResult.fromJson(Map<String, dynamic> json) {
    final responses = (json['responses'] as List?)
        ?.map((e) => ModelResponse.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    
    final failed = (json['failed'] as List?)
        ?.map((e) => ModelResponse.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return MultiModelResult(
      responses: responses,
      failed: failed,
      totalTime: json['totalTime'] as int? ?? 0,
      bestResponse: responses.firstWhere(
        (r) => r.isBest,
        orElse: () => responses.isNotEmpty ? responses.first : const ModelResponse(
          model: 'None',
          provider: '',
          content: 'No response',
          responseTime: 0,
        ),
      ),
    );
  }

  final List<ModelResponse> responses;
  final List<ModelResponse> failed;
  final int totalTime;
  final ModelResponse? bestResponse;
}

/// Available AI model info
class AIModelInfo {
  const AIModelInfo({
    required this.name,
    required this.displayName,
    required this.provider,
    required this.enabled,
  });

  factory AIModelInfo.fromJson(Map<String, dynamic> json) {
    return AIModelInfo(
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final String name;
  final String displayName;
  final String provider;
  final bool enabled;
}

/// Multi-model AI service
class MultiModelService {
  MultiModelService({required this.apiService});

  final ApiService apiService;

  /// Query all models and get best response
  Future<ModelResponse> chat(String message) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        '/multi-model/chat',
        data: {'message': message, 'returnAll': false},
      );

      if (response.data == null) {
        throw ApiException('Empty response');
      }

      final data = response.data!['data'] ?? response.data!;
      return ModelResponse(
        model: data['model'] as String? ?? 'AI',
        provider: data['provider'] as String? ?? '',
        content: data['response'] as String? ?? '',
        responseTime: data['responseTime'] as int? ?? 0,
        tokensUsed: data['tokensUsed'] as int? ?? 0,
        isBest: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get response: $e');
    }
  }

  /// Compare responses from all models
  Future<MultiModelResult> compare(String message) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        '/multi-model/compare',
        data: {'message': message},
      );

      if (response.data == null) {
        throw ApiException('Empty response');
      }

      final data = response.data!['data'] ?? response.data!;
      return MultiModelResult.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to compare models: $e');
    }
  }

  /// Get available models
  Future<List<AIModelInfo>> getModels() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/multi-model/models',
      );

      if (response.data == null) return [];

      final data = response.data!['data'] ?? response.data!;
      final models = data['models'] as List?;
      return models
          ?.map((e) => AIModelInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
    } catch (e) {
      return [];
    }
  }
}
