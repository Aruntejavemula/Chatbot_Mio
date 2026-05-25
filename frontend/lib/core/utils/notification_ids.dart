/// Static notification channel and ID constants.
/// Each notification type has a unique ID to prevent collisions.
class NotificationIds {
  NotificationIds._();

  static const int taskComplete = 1;
  static const int researchComplete = 2;
  static const int tokenWarning = 3;
  static const int general = 100;

  static const String channelId = 'mio_notifications';
  static const String channelName = 'Mio Notifications';
  static const String channelDescription = 'Notifications from Mio AI assistant';
}
