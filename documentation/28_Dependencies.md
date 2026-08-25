# 28. Dependencies

Pin to these ranges unless a security patch requires a bump. Do not add GetIt, Drift, Hive, Bloc, or extra social SDKs.

Firebase Crashlytics, Firebase Remote Config, Firebase Performance, and PostHog are added via the `analytics` package. They no-op until `google-services.json` and `POSTHOG_API_KEY` are configured. See [31_Observability_Analytics.md](31_Observability_Analytics.md).

| Package | Version |
|---------|---------|
| SDK | ^3.10.0 |
| Flutter | >=3.24.0 |
| flutter_riverpod | ^2.6.1 |
| go_router | ^16.2.0 |
| dio | ^5.9.0 |
| uuid | ^4.5.1 |
| path | ^1.9.1 |
| sqflite | ^2.4.2 |
| sqflite_common_ffi | ^2.3.6 (dev/tests) |
| sqflite_common_ffi_web | ^1.0.4 |
| path_provider | ^2.1.5 |
| shared_preferences | ^2.5.3 |
| flutter_foreground_task | ^11.0.1 |
| flutter_local_notifications | ^19.0.0 |
| connectivity_plus | ^6.1.4 |
| permission_handler | ^12.0.1 |
| webview_flutter | ^4.14.0 |
| webview_flutter_web | ^0.2.3+4 |
| receive_sharing_intent | ^1.9.0 |
| mobile_scanner | ^7.0.1 |
| video_player | ^2.14.0 |
| open_filex | ^4.7.0 |
| share_plus | ^13.2.1 |
| gal | ^2.3.3 |
| mime | ^2.0.0 |
| web | ^1.1.1 |
| cupertino_icons | ^1.0.8 |
| flutter_lints | ^6.0.0 |
| melos | ^8.2.2 (workspace dev) |

Path deps between workspace packages as in [26](26_Package_Catalog.md).
