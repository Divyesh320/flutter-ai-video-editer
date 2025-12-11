import '../../../core/models/models.dart';
import '../../../core/services/services.dart';

/// Request for generating an email draft
class EmailDraftRequest {
  const EmailDraftRequest({
    required this.conversationId,
    this.instructions,
  });

  /// The conversation to generate email from
  final String conversationId;

  /// Optional additional instructions for draft generation
  final String? instructions;

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        if (instructions != null) 'instructions': instructions,
      };
}

/// Exception thrown when email agent operations fail
class EmailAgentException implements Exception {
  const EmailAgentException(this.message);
  final String message;

  @override
  String toString() => 'EmailAgentException: $message';
}

/// Abstract interface for email agent operations
abstract class EmailAgentService {
  /// Generate an email draft from conversation context
  /// 
  /// POST to /agents/email/draft with conversation_id
  /// Returns EmailDraft with subject and body
  Future<EmailDraft> generateDraft(EmailDraftRequest request);

  /// Regenerate draft with additional instructions
  Future<EmailDraft> regenerateDraft(
    String conversationId,
    String instructions,
  );
}

/// Implementation of EmailAgentService using ApiService
class EmailAgentServiceImpl implements EmailAgentService {
  EmailAgentServiceImpl({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  @override
  Future<EmailDraft> generateDraft(EmailDraftRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/agents/email/draft',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw const EmailAgentException('Empty response from server');
      }

      final draft = EmailDraft.fromJson(response.data!);

      // Validate draft has required content (Property 18)
      if (!draft.isValid) {
        throw const EmailAgentException(
          'Invalid draft: subject and body are required',
        );
      }

      return draft;
    } on OfflineException {
      throw const EmailAgentException(
        'Cannot generate email draft while offline',
      );
    } catch (e) {
      if (e is EmailAgentException) rethrow;
      if (e is ApiException) {
        throw EmailAgentException('Email draft generation failed: ${e.message}');
      }
      throw EmailAgentException('Failed to generate email draft: $e');
    }
  }

  @override
  Future<EmailDraft> regenerateDraft(
    String conversationId,
    String instructions,
  ) async {
    return generateDraft(EmailDraftRequest(
      conversationId: conversationId,
      instructions: instructions,
    ));
  }
}
