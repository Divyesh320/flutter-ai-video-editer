import 'package:flutter/material.dart';

/// Banner displaying quota warning or exceeded message
class QuotaWarningBanner extends StatelessWidget {
  const QuotaWarningBanner({
    super.key,
    required this.message,
    required this.isExceeded,
    this.onDismiss,
  });

  final String message;
  final bool isExceeded;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isExceeded ? Colors.red : Colors.orange;
    final icon = isExceeded ? Icons.error : Icons.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: backgroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: backgroundColor.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onDismiss != null && !isExceeded)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
                color: backgroundColor,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
