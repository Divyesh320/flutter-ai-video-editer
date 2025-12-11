import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../utils/clipboard_utils.dart';
import '../utils/email_share_utils.dart';

/// State for email draft operations
enum EmailDraftState {
  idle,
  loading,
  success,
  error,
}

/// Widget to display and interact with an email draft
class EmailDraftCard extends StatefulWidget {
  const EmailDraftCard({
    super.key,
    required this.draft,
    this.onRegenerate,
    this.onDismiss,
    this.isLoading = false,
    this.errorMessage,
  });

  /// The email draft to display
  final EmailDraft draft;

  /// Callback when user requests regeneration with instructions
  final void Function(String instructions)? onRegenerate;

  /// Callback when user dismisses the draft
  final VoidCallback? onDismiss;

  /// Whether a regeneration is in progress
  final bool isLoading;

  /// Error message to display
  final String? errorMessage;

  @override
  State<EmailDraftCard> createState() => _EmailDraftCardState();
}

class _EmailDraftCardState extends State<EmailDraftCard> {
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  final _instructionsController = TextEditingController();
  String? _operationMessage;
  bool _isOperationSuccess = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.draft.subject);
    _bodyController = TextEditingController(text: widget.draft.body);
  }

  @override
  void didUpdateWidget(EmailDraftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft) {
      _subjectController.text = widget.draft.subject;
      _bodyController.text = widget.draft.body;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  EmailDraft get _currentDraft => EmailDraft(
        subject: _subjectController.text,
        body: _bodyController.text,
        conversationId: widget.draft.conversationId,
      );

  Future<void> _copyToClipboard() async {
    final result = await EmailClipboardUtils.copyDraftToClipboard(_currentDraft);
    _showOperationResult(
      result.success,
      result.success ? 'Copied to clipboard' : result.errorMessage ?? 'Copy failed',
    );
  }

  Future<void> _shareEmail() async {
    final result = await EmailShareUtils.shareDraft(_currentDraft);
    if (!result.success && result.errorMessage != null) {
      _showOperationResult(false, result.errorMessage!);
    }
  }

  Future<void> _openEmailClient() async {
    final result = await EmailShareUtils.openEmailClient(_currentDraft);
    if (!result.success && result.errorMessage != null) {
      _showOperationResult(false, result.errorMessage!);
    }
  }

  void _showOperationResult(bool success, String message) {
    setState(() {
      _operationMessage = message;
      _isOperationSuccess = success;
    });

    // Clear message after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _operationMessage = null);
      }
    });

    // Also show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRegenerateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Draft'),
        content: TextField(
          controller: _instructionsController,
          decoration: const InputDecoration(
            hintText: 'Add instructions (e.g., "make it more formal")',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRegenerate?.call(_instructionsController.text);
              _instructionsController.clear();
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email Draft',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onDismiss,
                    tooltip: 'Dismiss',
                  ),
              ],
            ),

            const Divider(height: 24),

            // Error message
            if (widget.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Operation message
            if (_operationMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isOperationSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOperationSuccess ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: _isOperationSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _operationMessage!,
                      style: TextStyle(
                        color: _isOperationSuccess ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Loading indicator
            if (widget.isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],

            // Subject field
            Text(
              'Subject',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _subjectController,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),

            const SizedBox(height: 16),

            // Body field
            Text(
              'Body',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _bodyController,
              enabled: !widget.isLoading,
              maxLines: 8,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Copy button
                FilledButton.icon(
                  onPressed: widget.isLoading ? null : _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),

                // Share button
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : _shareEmail,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),

                // Open email client button
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : _openEmailClient,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Email App'),
                ),

                // Regenerate button
                if (widget.onRegenerate != null)
                  TextButton.icon(
                    onPressed: widget.isLoading ? null : _showRegenerateDialog,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Regenerate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
