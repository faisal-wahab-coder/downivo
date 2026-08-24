# 16. Background Downloads

**Packages:** `job_manager` (~7 Dart), `notifications` (~4 Dart), `app_core` `download_background_scope.dart`

## Behavior

- While tasks are active, run `flutter_foreground_task` service type `dataSync`
- Persistent notification with progress
- Notification actions: pause, cancel
- `WAKE_LOCK` + FG permissions in manifest
- `connectivity_plus`: offline → pause; online → resume
- Web: coordinator no-ops / no service

Do not use Android `DownloadManager` system service as the engine — app Dio is the source of truth.
