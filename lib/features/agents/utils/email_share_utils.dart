import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';

/// Result of an email share operation
class EmailShareResult {
  const EmailShareResult({
    required this.success,
    this.errorMessage,
  });

  /// Whether the share operation succeeded
  final bool success;

  /// Error message if share failed
  final String? errorMessage;

  factory EmailShareResult.success() => const EmailShareResult(success: true);

  factory EmailShareResult.failure(String error) => EmailShareResult(
        success: false,
        errorMessage: error,
      );
}

/// Utility class for sharing email drafts
class EmailShareUtils {
  /// Share email draft using the system share sheet
  /// 
  /// Uses share_plus to open the native share dialog
  static Future<EmailShareResult> shareDraft(EmailDraft draft) async {
    try {
      final result = await Share.share(
        draft.formattedEmail,
        subject: draft.subject,
      );

      // ShareResult.status can be used to check if share was successful
      // but we consider the operation successful if no exception was thrown
      if (result.status == ShareResultStatus.dismissed) {
        return EmailShareResult.failure('Share was cancelled');
      }

      return EmailShareResult.success();
    } catch (e) {
      return EmailShareResult.failure('Failed to share: $e');
    }
  }

  /// Open email client with draft pre-filled using mailto: URL
  /// 
  /// This provides a more direct way to open the email client
  static Future<EmailShareResult> openEmailClient(
    EmailDraft draft, {
    String? recipientEmail,
  }) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail ?? '',
        query: _encodeQueryParameters({
          'subject': draft.subject,
          'body': draft.body,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return EmailShareResult.success();
      } else {
        return EmailShareResult.failure('No email client available');
      }
    } catch (e) {
      return EmailShareResult.failure('Failed to open email client: $e');
    }
  }

  /// Encode query parameters for mailto: URL
  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Share draft with specific app (if supported by platform)
  static Future<EmailShareResult> shareWithApp(
    EmailDraft draft,
    String appPackageName,
  ) async {
    try {
      // Note: share_plus doesn't support targeting specific apps directly
      // This is a fallback to the general share
      return shareDraft(draft);
    } catch (e) {
      return EmailShareResult.failure('Failed to share with app: $e');
    }
  }
}
