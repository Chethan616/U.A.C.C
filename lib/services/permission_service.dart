import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  
  /// Request all permissions needed for automation features
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.microphone, // For call recording
      Permission.storage, // For storing recordings
      Permission.calendar, // For calendar integration
      Permission.notification, // For notification management
    ];

    Map<Permission, PermissionStatus> statuses = {};
    
    for (Permission permission in permissions) {
      final status = await permission.request();
      statuses[permission] = status;
    }
    
    return statuses;
  }
  
  /// Check if all critical permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final micPermission = await Permission.microphone.isGranted;
    final storagePermission = await Permission.storage.isGranted;
    final calendarPermission = await Permission.calendar.isGranted;
    
    return micPermission && storagePermission && calendarPermission;
  }
  
  /// Request specific permission with user-friendly explanation
  static Future<bool> requestPermissionWithDialog(
    BuildContext context,
    Permission permission,
    String title,
    String description,
  ) async {
    // Check if already granted
    if (await permission.isGranted) return true;
    
    // Show explanation dialog first
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
    
    if (shouldRequest != true) return false;
    
    // Request permission
    final status = await permission.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      // Show settings dialog if permanently denied
      if (status.isPermanentlyDenied) {
        await _showSettingsDialog(context, title);
      }
      return false;
    }
    
    return status.isGranted;
  }
  
  /// Show dialog to open app settings for permanently denied permissions
  static Future<void> _showSettingsDialog(BuildContext context, String permissionName) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: const Text(
          'This permission is required for the app to function properly. '
          'Please enable it in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Request microphone permission for call recording
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      Permission.microphone,
      'Microphone Access',
      'The app needs microphone access to record and analyze your calls for automated task creation and meeting scheduling.',
    );
  }
  
  /// Request storage permission for saving recordings
  static Future<bool> requestStoragePermission(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      Permission.storage,
      'Storage Access',
      'The app needs storage access to save call recordings and analysis data.',
    );
  }
  
  /// Request calendar permission for Google Workspace integration
  static Future<bool> requestCalendarPermission(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      Permission.calendar,
      'Calendar Access',
      'The app needs calendar access to automatically schedule meetings and sync with Google Workspace.',
    );
  }
  
  /// Request notification permission for smart automation
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      Permission.notification,
      'Notification Access',
      'The app needs notification access to provide smart replies and notification automation for messaging apps.',
    );
  }
  
  /// Get permission status summary for UI display
  static Future<Map<String, bool>> getPermissionSummary() async {
    return {
      'microphone': await Permission.microphone.isGranted,
      'storage': await Permission.storage.isGranted,
      'calendar': await Permission.calendar.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }
  
  /// Check if the app has notification listener access (Android specific)
  static Future<bool> hasNotificationListenerAccess() async {
    // This would need platform-specific code to check
    // For now, return true as a placeholder
    return true;
  }
  
  /// Request notification listener access (opens system settings)
  static Future<void> requestNotificationListenerAccess() async {
    // This would open Android's notification listener settings
    await openAppSettings();
  }
}