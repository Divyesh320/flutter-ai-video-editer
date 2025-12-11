import 'dart:io';

import '../../../core/services/services.dart';
import '../../../core/models/models.dart';

/// Response from voice/STT API
class VoiceResponse {
  const VoiceResponse({
    required this.transcript,
    required this.response,
    required this.messageId,
  });

  /// Transcribed text from audio
  final String transcript;

  /// AI response to the transcribed message
  final String response;

  /// ID of the created message
  final String messageId;

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    return VoiceResponse(
      transcript: json['transcript'] as String,
      response: json['response'] as String,
      messageId: json['message_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'transcript': transcript,
        'response': response,
        'message_id': messageId,
      };
}

/// Exception thrown when STT processing fails
class STTException implements Exception {
  const STTException(this.message);
  final String message;

  @override
  String toString() => 'STTException: $message';
}

/// Abstract interface for voice operations
abstract class VoiceService {
  /// Upload audio file and get STT transcript with AI response
  /// Returns VoiceResponse containing transcript and AI response
  Future<VoiceResponse> sendVoice(File audioFile, String conversationId);

  /// Get TTS audio URL for text
  Future<String> getTTSAudio(String text);
}

/// Implementation of VoiceService using ApiService
class VoiceServiceImpl implements VoiceService {
  VoiceServiceImpl({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  @override
  Future<VoiceResponse> sendVoice(File audioFile, String conversationId) async {
    try {
      // Validate file exists
      if (!await audioFile.exists()) {
        throw const STTException('Audio file not found');
      }

      // Upload audio file to /voice endpoint
      final response = await _apiService.uploadFile<Map<String, dynamic>>(
        '/voice',
        audioFile.path,
        fieldName: 'audio',
        additionalFields: {
          'conversation_id': conversationId,
        },
      );

      if (response.data == null) {
        throw const STTException('Empty response from server');
      }

      return VoiceResponse.fromJson(response.data!);
    } on OfflineException {
      throw const STTException('Cannot process voice while offline');
    } catch (e) {
      if (e is STTException) rethrow;
      if (e is ApiException) {
        throw STTException('Voice processing failed: ${e.message}');
      }
      throw STTException('Failed to process voice: $e');
    }
  }

  @override
  Future<String> getTTSAudio(String text) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/tts',
        data: {'text': text},
      );

      if (response.data == null || response.data!['audio_url'] == null) {
        throw const STTException('No audio URL in response');
      }

      return response.data!['audio_url'] as String;
    } catch (e) {
      if (e is STTException) rethrow;
      if (e is ApiException) {
        throw STTException('TTS generation failed: ${e.message}');
      }
      throw STTException('Failed to generate TTS: $e');
    }
  }
}

/// Creates a Message from a VoiceResponse
Message createMessageFromVoice({
  required VoiceResponse voiceResponse,
  required String conversationId,
}) {
  return Message(
    id: voiceResponse.messageId,
    conversationId: conversationId,
    role: MessageRole.user,
    content: voiceResponse.transcript,
    type: MessageType.audio,
    metadata: {
      'source': 'voice',
      'transcript': voiceResponse.transcript,
    },
    createdAt: DateTime.now(),
  );
}
