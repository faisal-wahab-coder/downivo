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

`application`: `requestLegacyExternalStorage=true` (MediaStore album on API 29).

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
- Keep `android.builtInKotlin=false` so third-party plugins that still apply `kotlin-android` can build. Flutter warns about those plugins; they are not a current failure.

- Gradle 9.3.1
- Android Gradle Plugin 9.1.0
- Kotlin 2.4.0
- compileSdk / targetSdk from Flutter (36)
- Java / Kotlin JVM 17
