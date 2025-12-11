import 'package:flutter/services.dart';

import '../../../core/models/models.dart';

/// Result of a clipboard copy operation
class ClipboardCopyResult {
  const ClipboardCopyResult({
    required this.success,
    required this.copiedContent,
    this.errorMessage,
  });

  /// Whether the copy operation succeeded
  final bool success;

  /// The content that was copied to clipboard
  final String copiedContent;

  /// Error message if copy failed
  final String? errorMessage;

  factory ClipboardCopyResult.success(String content) => ClipboardCopyResult(
        success: true,
        copiedContent: content,
      );

  factory ClipboardCopyResult.failure(String error) => ClipboardCopyResult(
        success: false,
        copiedContent: '',
        errorMessage: error,
      );
}

/// Utility class for clipboard operations with email drafts
class EmailClipboardUtils {
  /// Copy email draft to clipboard
  /// 
  /// Copies the formatted email (subject + body) to the system clipboard.
  /// Returns a result indicating success/failure.
  static Future<ClipboardCopyResult> copyDraftToClipboard(
    EmailDraft draft,
  ) async {
    try {
      final content = draft.formattedEmail;
      await Clipboard.setData(ClipboardData(text: content));
      return ClipboardCopyResult.success(content);
    } catch (e) {
      return ClipboardCopyResult.failure('Failed to copy to clipboard: $e');
    }
  }

  /// Copy just the subject to clipboard
  static Future<ClipboardCopyResult> copySubjectToClipboard(
    EmailDraft draft,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: draft.subject));
      return ClipboardCopyResult.success(draft.subject);
    } catch (e) {
      return ClipboardCopyResult.failure('Failed to copy subject: $e');
    }
  }

  /// Copy just the body to clipboard
  static Future<ClipboardCopyResult> copyBodyToClipboard(
    EmailDraft draft,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: draft.body));
      return ClipboardCopyResult.success(draft.body);
    } catch (e) {
      return ClipboardCopyResult.failure('Failed to copy body: $e');
    }
  }

  /// Verify clipboard contains expected content
  /// 
  /// Used for testing to verify clipboard operations
  static Future<bool> verifyClipboardContent(String expectedContent) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text == expectedContent;
    } catch (e) {
      return false;
    }
  }
}
