import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper class for managing app permissions
class PermissionHelper {
  PermissionHelper._();

  /// Request all required permissions for the app
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ];

    final statuses = await permissions.request();
    return statuses;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request photo library permission
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Request storage permission (for older Android versions)
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if photos permission is granted
  static Future<bool> hasPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  /// Check all permissions status
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'microphone': await Permission.microphone.isGranted,
      'camera': await Permission.camera.isGranted,
      'photos': await Permission.photos.isGranted || await Permission.photos.isLimited,
      'storage': await Permission.storage.isGranted,
    };
  }

  /// Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Show permission denied dialog
  static void showPermissionDeniedDialog(
    BuildContext context, {
    required String permissionName,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

/// Widget that requests permissions on first launch
class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({
    super.key,
    required this.onPermissionsGranted,
    this.onSkip,
  });

  final VoidCallback onPermissionsGranted;
  final VoidCallback? onSkip;

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  Map<String, bool> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = await PermissionHelper.checkAllPermissions();
    setState(() {
      _permissions = permissions;
      _isLoading = false;
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);
    
    await PermissionHelper.requestAllPermissions();
    await _checkPermissions();
    
    // Check if all critical permissions are granted
    if (_permissions['microphone'] == true && _permissions['camera'] == true) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestPermission(String name) async {
    bool granted = false;
    
    switch (name) {
      case 'microphone':
        granted = await PermissionHelper.requestMicrophonePermission();
        break;
      case 'camera':
        granted = await PermissionHelper.requestCameraPermission();
        break;
      case 'photos':
        granted = await PermissionHelper.requestPhotosPermission();
        break;
      case 'storage':
        granted = await PermissionHelper.requestStoragePermission();
        break;
    }
    
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
        actions: [
          if (widget.onSkip != null)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app needs the following permissions to work properly:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            _PermissionTile(
              icon: Icons.mic,
              title: 'Microphone',
              description: 'For voice recording and speech-to-text',
              isGranted: _permissions['microphone'] ?? false,
              onRequest: () => _requestPermission('microphone'),
            ),
            
            _PermissionTile(
              icon: Icons.camera_alt,
              title: 'Camera',
              description: 'For taking photos and videos',
              isGranted: _permissions['camera'] ?? false,
              onRequest: () => _requestPermission('camera'),
            ),
            
            _PermissionTile(
              icon: Icons.photo_library,
              title: 'Photo Library',
              description: 'For selecting images and videos',
              isGranted: _permissions['photos'] ?? false,
              onRequest: () => _requestPermission('photos'),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestAllPermissions,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Grant All Permissions'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => PermissionHelper.openSettings(),
                child: const Text('Open App Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: isGranted ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: onRequest,
                child: const Text('Grant'),
              ),
      ),
    );
  }
}
