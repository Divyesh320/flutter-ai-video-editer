import 'package:flutter/material.dart';

/// Button to trigger email draft generation from conversation
class EmailDraftButton extends StatelessWidget {
  const EmailDraftButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Whether draft generation is in progress
  final bool isLoading;

  /// Whether the button is enabled
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Generate email draft from conversation',
      child: IconButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.email_outlined),
      ),
    );
  }
}

/// Floating action button variant for email draft
class EmailDraftFAB extends StatelessWidget {
  const EmailDraftFAB({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.extended = false,
  });

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Whether draft generation is in progress
  final bool isLoading;

  /// Whether the button is enabled
  final bool isEnabled;

  /// Whether to show extended FAB with label
  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.email_outlined),
        label: const Text('Draft Email'),
      );
    }

    return FloatingActionButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      tooltip: 'Generate email draft',
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.email_outlined),
    );
  }
}
