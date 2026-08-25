import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'download_notification_actions.dart';

/// Shows download progress, completion, and failure notifications.
class DownloadNotificationService {
  DownloadNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _progressId = 1000;
  static const _progressChannelId = 'downloads_progress';
  static const _eventsChannelId = 'downloads_events';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: DownloadNotificationActions.dispatch,
      onDidReceiveBackgroundNotificationResponse:
          _backgroundNotificationTap,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _progressChannelId,
        'Download progress',
        description: 'Ongoing download progress',
        importance: Importance.low,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _eventsChannelId,
        'Download events',
        description: 'Completed and failed downloads',
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  Future<void> showProgress({
    required int activeCount,
    required String primaryFileName,
    required int progressPercent,
    String? primaryTaskId,
  }) async {
    if (!_initialized) return;

    final title = activeCount > 1
        ? 'Downloading $activeCount files'
        : 'Downloading file…';
    final body = '$primaryFileName — $progressPercent% completed';

    await _plugin.show(
      _progressId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _progressChannelId,
          'Download progress',
          channelDescription: 'Ongoing download progress',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progressPercent.clamp(0, 100),
          ongoing: true,
          actions: primaryTaskId == null
              ? null
              : [
                  const AndroidNotificationAction(
                    DownloadNotificationActions.pauseAction,
                    'Pause',
                    showsUserInterface: false,
                  ),
                  const AndroidNotificationAction(
                    DownloadNotificationActions.cancelAction,
                    'Cancel',
                    showsUserInterface: false,
                  ),
                ],
        ),
      ),
      payload: primaryTaskId,
    );
  }

  Future<void> dismissProgress() async {
    if (!_initialized) return;
    await _plugin.cancel(_progressId);
  }

  Future<void> showCompleted({
    required String fileName,
    required int notificationId,
  }) async {
    if (!_initialized) return;

    await _plugin.show(
      notificationId,
      'Download finished',
      fileName,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _eventsChannelId,
          'Download events',
          channelDescription: 'Completed and failed downloads',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> showFailed({
    required String fileName,
    required int notificationId,
    String? reason,
  }) async {
    if (!_initialized) return;

    await _plugin.show(
      notificationId,
      'Download failed',
      reason == null ? fileName : '$fileName — $reason',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _eventsChannelId,
          'Download events',
          channelDescription: 'Completed and failed downloads',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void _backgroundNotificationTap(NotificationResponse response) {
  DownloadNotificationActions.dispatch(response);
}
