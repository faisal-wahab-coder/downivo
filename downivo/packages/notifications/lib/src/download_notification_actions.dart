import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global notification action dispatch for download controls.
class DownloadNotificationActions {
  DownloadNotificationActions._();

  static void Function(String actionId, String? taskId)? handler;

  static const pauseAction = 'pause';
  static const cancelAction = 'cancel';

  static void dispatch(NotificationResponse response) {
    final action = response.actionId;
    if (action == null) return;
    handler?.call(action, response.payload);
  }
}
