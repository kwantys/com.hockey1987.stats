import 'package:permission_handler/permission_handler.dart';
import '../shared/services/logger.dart';

/// Service for handling notification permission requests and status checks.
class NotificationPermissionService {
  /// Check current notification permission status.
  static Future<PermissionStatus> checkStatus() async {
    final status = await Permission.notification.status;
    AppLogger.d('Notification permission status: $status');
    return status;
  }

  /// Request notification permission from user.
  /// Returns the resulting permission status.
  static Future<PermissionStatus> requestPermission() async {
    AppLogger.i('Requesting notification permission');
    final status = await Permission.notification.request();
    AppLogger.i('Notification permission result: $status');
    return status;
  }

  /// Check if notification permission is permanently denied.
  /// When permanently denied, user must go to app settings to enable.
  static Future<bool> isPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  /// Check if notification permission is granted.
  static Future<bool> isGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings so user can manually enable notifications.
  /// Returns true if settings were opened successfully.
  static Future<bool> openSettings() async {
    AppLogger.i('Opening app settings for notification permission');
    return openAppSettings();
  }
}
