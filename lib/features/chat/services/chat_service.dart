import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

/// Request for sending a chat message
class ChatRequest {
  const ChatRequest({
    required this.message,
    this.conversationId,
    this.model = 'gemini-1.5-flash', // Google Gemini FREE model
  });

  final String message;
  final String? conversationId;
  final String model;

  Map<String, dynamic> toJson() => {
    'message': message,
    if (conversationId != null) 'conversationId': conversationId,
    'model': model,
  };
}

/// Response from chat API
class ChatResponse {
  const ChatResponse({
    required this.response,
    required this.jobId,
    this.conversationId,
    this.tokensUsed,
    this.processingTime,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String? ?? 
                json['analysis'] as String? ?? 
                json['message'] as String? ?? '',
      jobId: json['jobId'] as String? ?? json['_id'] as String? ?? '',
      conversationId: json['conversationId'] as String?,
      tokensUsed: json['tokensUsed'] as int?,
      processingTime: json['processingTime'] as int?,
    );
  }

  final String response;
  final String jobId;
  final String? conversationId;
  final int? tokensUsed;
  final int? processingTime;
}

/// Abstract interface for chat operations
abstract class ChatService {
  /// Send a text message and get AI response
  Future<ChatResponse> sendMessage(ChatRequest request);

  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations();

  /// Get a specific conversation with all messages
  Future<Conversation> getConversation(String id);

  /// Create a new conversation
  Future<Conversation> createConversation();

  /// Rename a conversation
  Future<void> renameConversation(String id, String newTitle);

  /// Delete a conversation and all associated data
  Future<void> deleteConversation(String id);

  /// Get AI job history
  Future<List<Map<String, dynamic>>> getAIJobs({int page = 1, int limit = 20});

  /// Get specific AI job details
  Future<Map<String, dynamic>> getAIJob(String jobId);

  /// Get AI-powered suggestions based on conversation
  Future<List<String>> getSuggestions(String lastMessage, String? lastResponse);

  /// Send message with image attachment
  Future<ChatResponse> sendMessageWithImage({
    required String conversationId,
    required String message,
    required File imageFile,
  });

  /// Send message with video attachment
  Future<ChatResponse> sendMessageWithVideo({
    required String conversationId,
    required String message,
    required File videoFile,
  });
}

/// Implementation of ChatService using backend API
class ChatServiceImpl implements ChatService {
  ChatServiceImpl({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/ai/chat',
        data: request.toJson(),
        queueIfOffline: true,
      );

      if (response.data == null) {
        throw ApiException('Empty response from server');
      }

      // Backend returns { success: true, data: { ... } }
      final data = response.data!['data'] ?? response.data!;
      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } on OfflineException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to send message: $e');
    }
  }

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/conversations');

      if (response.data == null) {
        return [];
      }

      // Backend returns { success: true, data: [...] }
      final data = response.data!['data'] ?? response.data!;
      if (data is List) {
        return data
            .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load conversations: $e');
    }
  }

  @override
  Future<Conversation> getConversation(String id) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/conversations/$id',
      );

      if (response.data == null) {
        throw ApiException('Conversation not found');
      }

      final data = response.data!['data'] ?? response.data!;
      return Conversation.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load conversation: $e');
    }
  }

  @override
  Future<Conversation> createConversation() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/conversations',
        data: {},
      );

      if (response.data == null) {
        throw ApiException('Failed to create conversation');
      }

      final data = response.data!['data'] ?? response.data!;
      return Conversation.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create conversation: $e');
    }
  }

  @override
  Future<void> renameConversation(String id, String newTitle) async {
    try {
      await _apiService.patch<void>(
        '/conversations/$id',
        data: {'title': newTitle},
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to rename conversation: $e');
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      await _apiService.delete<void>('/conversations/$id');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete conversation: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAIJobs({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/ai/jobs',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data!['data'] ?? [];
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load AI jobs: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAIJob(String jobId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/ai/jobs/$jobId',
      );

      if (response.data == null) {
        throw ApiException('AI job not found');
      }

      return response.data!['data'] as Map<String, dynamic>? ?? response.data!;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load AI job: $e');
    }
  }

  @override
  Future<List<String>> getSuggestions(String lastMessage, String? lastResponse) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/ai/suggestions',
        data: {
          'lastMessage': lastMessage,
          if (lastResponse != null) 'lastResponse': lastResponse,
        },
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data!['data'] ?? response.data!;
      final suggestions = data['suggestions'] as List?;
      return suggestions?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      // Return empty on error - suggestions are optional
      return [];
    }
  }

  @override
  Future<ChatResponse> sendMessageWithImage({
    required String conversationId,
    required String message,
    required File imageFile,
  }) async {
    try {
      final config = ApiConfig.fromEnv();
      final uri = Uri.parse('${config.baseUrl}/ai/analyze-image');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      final token = _apiService.currentToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add fields
      request.fields['message'] = message;
      request.fields['conversationId'] = conversationId;
      
      // Add image file
      final mimeType = _getMimeType(imageFile.path);
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: http_parser.MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw ApiException('Image analysis failed: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] ?? json;
      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to analyze image: $e');
    }
  }

  @override
  Future<ChatResponse> sendMessageWithVideo({
    required String conversationId,
    required String message,
    required File videoFile,
  }) async {
    try {
      final config = ApiConfig.fromEnv();
      final uri = Uri.parse('${config.baseUrl}/ai/analyze-video');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      final token = _apiService.currentToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add fields
      request.fields['message'] = message;
      request.fields['conversationId'] = conversationId;
      
      // Add video file
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: http_parser.MediaType('video', 'mp4'),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw ApiException('Video analysis failed: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] ?? json;
      return ChatResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to analyze video: $e');
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
