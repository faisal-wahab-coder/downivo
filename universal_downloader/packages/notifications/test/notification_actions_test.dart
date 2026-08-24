import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

void main() {
  tearDown(() {
    DownloadNotificationActions.handler = null;
  });

  NotificationResponse response({
    String? actionId,
    String? payload,
  }) {
    return NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: actionId,
      payload: payload,
    );
  }

  test('NP-001 dispatch pause includes task id', () {
    String? action;
    String? taskId;
    DownloadNotificationActions.handler = (id, payload) {
      action = id;
      taskId = payload;
    };

    DownloadNotificationActions.dispatch(
      response(
        actionId: DownloadNotificationActions.pauseAction,
        payload: 'task-1',
      ),
    );
    expect(action, 'pause');
    expect(taskId, 'task-1');
  });

  test('NP-002 dispatch cancel', () {
    String? action;
    DownloadNotificationActions.handler = (id, _) => action = id;
    DownloadNotificationActions.dispatch(
      response(actionId: DownloadNotificationActions.cancelAction),
    );
    expect(action, 'cancel');
  });

  test('NP-003 missing action id is ignored', () {
    var called = false;
    DownloadNotificationActions.handler = (_, __) => called = true;
    DownloadNotificationActions.dispatch(response());
    expect(called, isFalse);
  });

  test('NP-004 progress before initialize is a no-op', () async {
    final service = DownloadNotificationService();
    await service.showProgress(
      activeCount: 1,
      primaryFileName: 'a.bin',
      progressPercent: 10,
    );
    await service.dismissProgress();
    await service.showCompleted(fileName: 'a.bin', notificationId: 1);
    await service.showFailed(fileName: 'a.bin', notificationId: 2);
  });
}
