# 26. Package Catalog

Melos workspace members only. `publish_to: none` on all. SDK `^3.10.0`. Flutter packages `flutter: ">=3.24.0"` where they import Flutter.

Path dependencies listed as `(path)`.

---

## apps/mobile — `universal_downloader` `1.1.0+3`

**Dart:** `lib/main.dart` + tests  
**Deps:** flutter_riverpod ^2.6.1, app_core (path), flutter_foreground_task ^9.1.0, shared_preferences ^2.5.3, path_provider_platform_interface ^2.1.2, plugin_platform_interface ^2.1.8, cupertino_icons ^1.0.8  
**Dev:** flutter_lints ^6.0.0, sqflite_common_ffi ^2.3.6

## apps/web — `universal_downloader_web` `1.1.0+3`

**Deps:** flutter_riverpod, app_core (path), sqflite_common_ffi_web ^1.0.4, cupertino_icons

---

## app_core (~54 Dart)

Bootstrap, providers, AppRouter, all live screens.

**Deps:** flutter_riverpod, go_router ^16.2.0, shared_preferences, database, design_system, navigation, download_engine, media_library, browser, performance, content_intake, job_manager, shared_utils, permissions, storage, udm_search, universal_viewer, shared_types, webview_flutter ^4.13.0, webview_flutter_web ^0.2.3+4, receive_sharing_intent 1.8.1, mobile_scanner ^7.0.1

### Feature files (must exist)

```
lib/app_core.dart
lib/src/app/universal_downloader_app.dart
lib/src/bootstrap/bootstrap.dart
lib/src/bootstrap/app_initializer.dart
lib/src/bootstrap/intake_scope.dart
lib/src/bootstrap/download_background_scope.dart
lib/src/bootstrap/share_intake.dart
lib/src/bootstrap/share_intake_io.dart
lib/src/bootstrap/share_intake_stub.dart
lib/src/bootstrap/share_intake_factory.dart
lib/src/navigation/app_router.dart
lib/src/providers/app_providers.dart
lib/src/providers/download_providers.dart
lib/src/providers/library_providers.dart
lib/src/providers/settings_provider.dart
lib/src/providers/browser_providers.dart
lib/src/providers/intake_providers.dart
lib/src/providers/performance_providers.dart
lib/src/features/home/home_screen.dart
lib/src/features/home/storage_dashboard.dart
lib/src/features/downloads/downloads_screen.dart
lib/src/features/downloads/download_history_screen.dart
lib/src/features/downloads/download_wizard_dialog.dart
lib/src/features/downloads/download_enqueue.dart
lib/src/features/downloads/download_task_widgets.dart
lib/src/features/downloads/media_preview_card.dart
lib/src/features/downloads/media_selection_sheet.dart
lib/src/features/downloads/format_picker_sheet.dart
lib/src/features/downloads/apply_preferred_format.dart
lib/src/features/files/files_screen.dart
lib/src/features/files/image_gallery_screen.dart
lib/src/features/files/file_detail_screen.dart
lib/src/features/files/file_actions_sheet.dart
lib/src/features/files/file_filter_sheet.dart
lib/src/features/files/file_thumbnail.dart
lib/src/features/files/open_managed_media.dart
lib/src/features/files/library_source_index.dart
lib/src/features/files/file_image_io.dart
lib/src/features/files/file_image_stub.dart
lib/src/features/browser/browser_screen.dart
lib/src/features/browser/browser_home.dart
lib/src/features/browser/browser_sheets.dart
lib/src/features/settings/settings_screen.dart
lib/src/features/intake/qr_scanner_screen.dart
lib/src/features/intake/qr_navigation.dart
lib/src/features/intake/qr_navigation_io.dart
lib/src/features/intake/qr_navigation_stub.dart
lib/src/features/intake/clipboard_history_screen.dart
lib/src/features/intake/intake_prompt_sheet.dart
lib/src/features/intake/intake_action_handler.dart
lib/src/features/search/app_search_screen.dart
```

## browser (~11 Dart)

**Deps:** shared_preferences, uuid ^4.5.1, download_engine

## content_intake (~14 Dart)

**Deps:** shared_preferences, uuid, download_engine, browser

## database (~9 Dart)

**Deps:** sqflite ^2.4.2, sqflite_common_ffi_web ^1.0.4, path_provider ^2.1.5, path ^1.9.1, shared_types

## design_system (~8 Dart)

**Deps:** shared_types  
Files: `design_system.dart`, `spacing.dart`, `udm_colors.dart`, `app_theme.dart`, `udm_scaffold.dart`, `empty_state.dart`, `onboarding_widgets.dart`, `udm_components.dart`

## download_engine (~208 Dart incl. tests)

**Deps:** dio ^5.9.0, uuid, path, database, storage, shared_types, performance

## job_manager (~7 Dart)

**Deps:** flutter_foreground_task ^9.1.0, connectivity_plus ^6.1.4, download_engine, notifications, shared_types

## media_library (~22 Dart)

**Deps:** path, mime ^2.0.0, open_filex ^4.7.0, share_plus ^10.1.4, gal ^2.3.3, shared_preferences, storage, shared_utils, performance

## navigation (~5 Dart)

**Deps:** go_router, design_system, permissions, shared_types  
Owns: MainShell, OnboardingFlow, tab placeholder file (unused)

## notifications (~4 Dart)

**Deps:** flutter_local_notifications ^19.0.0

## performance (~6 Dart)

No extra deps. TTL, LRU, ThrottleGate, metrics.

## permissions (~4 Dart)

**Deps:** permission_handler ^12.0.1, shared_types

## search (`udm_search`, ~5 Dart)

**Deps:** shared_preferences, download_engine, media_library, shared_types, storage

## shared_types (~4 Dart)

`app_routes.dart`, `download_status.dart`, `theme_mode_preference.dart`, barrel

## shared_utils (~3 Dart)

transfer format helpers

## storage (~23 Dart)

**Deps:** path, path_provider, web ^1.1.1

## universal_viewer (~6 Dart)

**Deps:** video_player ^2.10.0, design_system
