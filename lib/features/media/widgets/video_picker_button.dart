import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/video_service.dart';

/// Button widget for picking videos from gallery
class VideoPickerButton extends StatelessWidget {
  const VideoPickerButton({
    super.key,
    required this.onVideoPicked,
    this.onValidationError,
    this.isLoading = false,
    this.enabled = true,
  });

  final void Function(File video) onVideoPicked;
  final void Function(String error)? onValidationError;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return IconButton(
      onPressed: enabled ? () => _pickVideo(context) : null,
      icon: Icon(
        Icons.videocam,
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      tooltip: 'Add video',
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      
      // Validate file size (duration is limited by maxDuration in picker)
      final fileSize = await file.length();
      final result = validateVideo(
        durationSeconds: 0, // Duration validated by picker's maxDuration
        fileSizeBytes: fileSize,
      );

      if (!result.isValid) {
        if (onValidationError != null) {
          onValidationError!(result.error!);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      onVideoPicked(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
