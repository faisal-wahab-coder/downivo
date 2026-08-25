import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'foreground_host.dart';

class IoForegroundHost implements ForegroundHost {
  var _running = false;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'download_foreground_service',
        channelName: 'Background downloads',
        channelDescription:
            'Keeps downloads running when the app is in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  Future<void> start({
    required String title,
    required String text,
  }) async {
    if (!_running) {
      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: title,
        notificationText: text,
        callback: _foregroundTaskCallback,
      );
      _running = result is ServiceRequestSuccess;
      return;
    }
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  @override
  Future<void> update({
    required String title,
    required String text,
  }) async {
    if (!_running) {
      await start(title: title, text: text);
      return;
    }
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    await FlutterForegroundTask.stopService();
    _running = false;
  }
}

ForegroundHost createPlatformForegroundHost() => IoForegroundHost();

@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_DownloadForegroundHandler());
}

class _DownloadForegroundHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}

  @override
  void onNotificationPressed() {}
}
