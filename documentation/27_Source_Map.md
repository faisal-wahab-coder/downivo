# 27. Source Map

Recreate this tree. Omit `build/`, `.dart_tool/`.

```
downivo/
├── melos.yaml
├── pubspec.yaml
├── README.md
├── RELEASE.md
├── CHANGELOG.md
├── QA_CHECKLIST.md
├── scripts/ci.sh
├── apps/mobile/
│   ├── pubspec.yaml
│   ├── lib/main.dart
│   ├── test/widget_test.dart
│   ├── test/bootstrap_test.dart
│   └── android/app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/pm/downivo/MainActivity.kt
├── apps/web/
│   ├── pubspec.yaml
│   └── lib/main.dart
└── packages/
    ├── app_core/lib/          # see 26 — 50 lib files
    ├── browser/lib/
    ├── content_intake/lib/
    ├── database/lib/src/
    │   ├── app_database.dart
    │   ├── database_provider.dart
    │   ├── sqflite_init.dart
    │   ├── sqflite_init_io.dart
    │   ├── sqflite_init_stub.dart
    │   ├── sqflite_init_web.dart
    │   └── models/download_record.dart
    ├── design_system/lib/src/
    ├── download_engine/lib/src/
    │   ├── download_manager.dart
    │   ├── download_repository.dart
    │   ├── models/download_task.dart
    │   └── content_providers/
    │       ├── content_provider_registry.dart
    │       ├── social_platform.dart
    │       ├── youtube_resolver.dart
    │       ├── tiktok_resolver.dart
    │       ├── instagram_graphql_resolver.dart
    │       ├── facebook_resolver.dart
    │       ├── twitter_resolver.dart
    │       ├── reddit_resolver.dart
    │       ├── pinterest_resolver.dart
    │       ├── linkedin_resolver.dart
    │       ├── threads_resolver.dart
    │       ├── soundcloud_resolver.dart
    │       ├── vimeo_resolver.dart
    │       ├── twitch_resolver.dart
    │       ├── telegram_resolver.dart
    │       ├── snapchat_resolver.dart
    │       ├── whatsapp_resolver.dart
    │       ├── dailymotion_resolver.dart
    │       ├── dailymotion_uri.dart
    │       ├── media_extractor.dart
    │       ├── platform_social_resolver.dart
    │       ├── social_http_headers.dart
    │       ├── social_url_utils.dart
    │       └── models/discovered_resource.dart
    ├── job_manager/lib/
    ├── media_library/lib/
    ├── navigation/lib/
    ├── notifications/lib/
    ├── performance/lib/
    ├── permissions/lib/
    ├── search/lib/
    ├── shared_types/lib/src/
    │   ├── app_identity.dart
    │   ├── app_routes.dart
    │   ├── download_status.dart
    │   └── theme_mode_preference.dart
    ├── shared_utils/lib/
    ├── storage/lib/src/
    │   ├── storage_category.dart
    │   ├── storage_paths.dart
    │   ├── storage_initializer.dart
    │   ├── storage_info.dart
    │   └── file_store/
    └── universal_viewer/lib/
```

## apps/mobile/lib/main.dart (behavior)

```dart
Future<void> main() async {
  FlutterForegroundTask.initCommunicationPort();
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: WithForegroundTask(
        child: const DownivoApp(),
      ),
    ),
  );
}
```

## ApplicationId

`applicationId` / namespace `com.pm.downivo`. Label `Downivo`.
