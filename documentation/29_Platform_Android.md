# 29. Platform Android

## Permissions

```
INTERNET
POST_NOTIFICATIONS
CAMERA
FOREGROUND_SERVICE
FOREGROUND_SERVICE_DATA_SYNC
WAKE_LOCK
WRITE_EXTERNAL_STORAGE (maxSdkVersion 29 — gallery album writes on Android 10)
```

`application`: `requestLegacyExternalStorage=true` (MediaStore album on API 29). Label `Downivo`.

## Identity

- `applicationId` / `namespace`: `com.pm.downivo`
- Kotlin package: `com.pm.downivo`
- Method channel: `com.downivo.storage/disk`

## Activity

- `MainActivity` Flutter embedding v2
- `exported=true`
- `launchMode=singleTask`
- `enableOnBackInvokedCallback=true`
- Launch + Normal themes
- MAIN/LAUNCHER
- SEND text/plain, SEND */*, SEND_MULTIPLE */*

## Service

`com.pravera.flutter_foreground_task.service.ForegroundService`  
`exported=false`  
`foregroundServiceType="dataSync"`

## Queries

`PROCESS_TEXT` text/plain (Flutter engine).

## Release

- minify + shrink resources
- ProGuard rules for Flutter + plugins used
- signing via `key.properties` (example file only in git)
- versionName 1.2.0 versionCode 4 (`1.2.0+4`)

## minSdk

API 29 (Android 10) per ADR-006.

## Build toolchain

Match Flutter 3.47 templates:

- `:app` does **not** apply `kotlin-android` (built-in Kotlin via AGP 9).
- `android.builtInKotlin=true` after plugins that apply KGP were upgraded (`flutter_foreground_task` 11, `receive_sharing_intent` 1.9, `share_plus` 13, FlutterFire `firebase_core` 4.x / `firebase_remote_config` 6.x, and current Android implementations of `shared_preferences` / `webview_flutter` / `video_player`). `mobile_scanner` 7.4 still contains a conditional KGP apply for AGP &lt; 9, so Flutter may still print a KGP warning even though it does not apply KGP when built-in Kotlin is on.

- Gradle 9.4.1
- Android Gradle Plugin 9.2.1
- Kotlin 2.4.0
- compileSdk 37 (required by `receive_sharing_intent` 1.9); targetSdk from Flutter
- Java / Kotlin JVM 17
