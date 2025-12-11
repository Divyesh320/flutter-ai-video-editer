import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';

/// A button widget for voice recording with visual feedback
class VoiceRecordingButton extends StatefulWidget {
  const VoiceRecordingButton({
    super.key,
    required this.audioService,
    required this.onRecordingComplete,
    this.onError,
    this.size = 56.0,
    this.recordingColor = Colors.red,
    this.idleColor,
  });

  /// Audio service for recording operations
  final AudioService audioService;

  /// Callback when recording is complete with the audio file path
  final void Function(String filePath) onRecordingComplete;

  /// Callback when an error occurs
  final void Function(String error)? onError;

  /// Size of the button
  final double size;

  /// Color when recording
  final Color recordingColor;

  /// Color when idle (defaults to theme primary color)
  final Color? idleColor;

  @override
  State<VoiceRecordingButton> createState() => _VoiceRecordingButtonState();
}

class _VoiceRecordingButtonState extends State<VoiceRecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<RecordingState>? _stateSubscription;
  RecordingState _recordingState = RecordingState.idle;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _subscribeToState();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _subscribeToState() {
    _stateSubscription = widget.audioService.recordingStateStream.listen(
      (state) {
        if (mounted) {
          setState(() => _recordingState = state);
          _updateAnimation(state);
        }
      },
    );
    _recordingState = widget.audioService.recordingState;
  }

  void _updateAnimation(RecordingState state) {
    if (state == RecordingState.recording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_recordingState == RecordingState.recording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await widget.audioService.startRecording();
    } on PermissionDeniedException {
      _showPermissionDialog();
    } on AudioException catch (e) {
      widget.onError?.call(e.message);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final file = await widget.audioService.stopRecording();
      widget.onRecordingComplete(file.path);
    } on AudioException catch (e) {
      widget.onError?.call(e.message);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'To use voice input, please grant microphone permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could open app settings here
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = _recordingState == RecordingState.recording;
    final hasError = _recordingState == RecordingState.error;

    final buttonColor = isRecording
        ? widget.recordingColor
        : hasError
            ? Colors.orange
            : widget.idleColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isRecording ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Material(
              color: buttonColor,
              shape: const CircleBorder(),
              elevation: isRecording ? 8 : 4,
              child: InkWell(
                onTap: _handleTap,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A more comprehensive voice input widget with status display
class VoiceInputWidget extends StatefulWidget {
  const VoiceInputWidget({
    super.key,
    required this.audioService,
    required this.onRecordingComplete,
    this.onError,
  });

  final AudioService audioService;
  final void Function(String filePath) onRecordingComplete;
  final void Function(String error)? onError;

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  StreamSubscription<RecordingState>? _stateSubscription;
  RecordingState _recordingState = RecordingState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subscribeToState();
  }

  void _subscribeToState() {
    _stateSubscription = widget.audioService.recordingStateStream.listen(
      (state) {
        if (mounted) {
          setState(() {
            _recordingState = state;
            if (state == RecordingState.error) {
              _errorMessage = 'Recording failed. Please try again.';
            } else {
              _errorMessage = null;
            }
          });
        }
      },
    );
    _recordingState = widget.audioService.recordingState;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _handleError(String error) {
    setState(() => _errorMessage = error);
    widget.onError?.call(error);
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _getStatusText(),
            key: ValueKey(_recordingState),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _recordingState == RecordingState.recording
                      ? Colors.red
                      : null,
                ),
          ),
        ),
        const SizedBox(height: 16),

        // Recording button
        VoiceRecordingButton(
          audioService: widget.audioService,
          onRecordingComplete: (path) {
            _clearError();
            widget.onRecordingComplete(path);
          },
          onError: _handleError,
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _clearError,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText() {
    switch (_recordingState) {
      case RecordingState.idle:
        return 'Tap to record';
      case RecordingState.recording:
        return 'Recording... Tap to stop';
      case RecordingState.paused:
        return 'Paused';
      case RecordingState.error:
        return 'Error occurred';
    }
  }
}
