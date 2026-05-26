import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/notification_ids.dart';

/// Service for managing local push notifications.
/// Handles initialization, permission requests, and displaying notifications
/// when the app is in the background.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize the notification plugin with platform-specific settings.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const macosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macosSettings,
      );

      await _plugin.initialize(initSettings);
      _isInitialized = true;
    } catch (e) {
      // Silently fail - notifications are non-critical
      _isInitialized = false;
    }
  }

  /// Show a notification when a task/AI response completes.
  static Future<void> showTaskComplete(String taskName) async {
    try {
      if (!_isInitialized) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationIds.channelId,
          NotificationIds.channelName,
          channelDescription: NotificationIds.channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.show(
        NotificationIds.taskComplete,
        'Task Complete',
        '$taskName is ready',
        details,
      );
    } catch (_) {
      // Non-critical - silently ignore notification failures
    }
  }

  /// Show a notification when deep research completes.
  static Future<void> showResearchComplete(String topic) async {
    try {
      if (!_isInitialized) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationIds.channelId,
          NotificationIds.channelName,
          channelDescription: NotificationIds.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.show(
        NotificationIds.researchComplete,
        'Research Ready',
        'Your research on "$topic" is complete',
        details,
      );
    } catch (_) {
      // Non-critical - silently ignore notification failures
    }
  }

  /// Show a notification warning about token usage approaching limits.
  static Future<void> showTokenWarning(int percentUsed) async {
    try {
      if (!_isInitialized) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationIds.channelId,
          NotificationIds.channelName,
          channelDescription: NotificationIds.channelDescription,
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.show(
        NotificationIds.tokenWarning,
        'Token Usage Warning',
        'You have used $percentUsed% of your token limit',
        details,
      );
    } catch (_) {
      // Non-critical - silently ignore notification failures
    }
  }

  /// Request notification permission from the user.
  /// Returns true if permission was granted.
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        final granted = await macos.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
