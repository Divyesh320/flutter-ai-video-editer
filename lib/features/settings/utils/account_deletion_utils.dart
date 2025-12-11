import 'package:flutter/material.dart';

/// Utility class for account deletion operations
class AccountDeletionUtils {
  AccountDeletionUtils._();

  /// Show confirmation dialog for account deletion
  /// Returns true if user confirms, false otherwise
  static Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show success message after account deletion
  static void showDeletionSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your account has been deleted successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show error message if account deletion fails
  static void showDeletionErrorMessage(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to delete account: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// List of data types that will be deleted
  static const List<String> deletedDataTypes = [
    'User profile and credentials',
    'All conversations and messages',
    'Uploaded media files (images, videos, audio)',
    'Generated embeddings and context data',
    'Settings and preferences',
    'Usage statistics',
  ];

  /// Get formatted list of data that will be deleted
  static String getDeletedDataDescription() {
    return deletedDataTypes.map((type) => '• $type').join('\n');
  }
}
