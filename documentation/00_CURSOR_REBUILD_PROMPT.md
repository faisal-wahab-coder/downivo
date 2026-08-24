# Cursor Rebuild Prompt — Universal Downloader (exact copy)

Copy everything below the line into a new Cursor chat (or AGENTS.md) when recreating this product from scratch.

---

You are rebuilding **Universal Downloader**, a production Flutter download manager. Your job is to recreate an **exact functional and architectural copy** of the as-built V1 app (`1.0.0+2`), not the original React Native specification.

## Absolute constraints

- Stack: **Flutter >= 3.24**, **Dart ^3.10**, **Material Design 3**.
- State: **flutter_riverpod ^2.6.1**. Navigation: **go_router ^16.2** with `StatefulShellRoute.indexedStack`.
- HTTP: **dio ^5.9**. Database: **sqflite ^2.4.2** (schemaVersion **4**). Settings: **shared_preferences**.
- Monorepo: Melos. Root folder name: `universal_downloader/`.
- V1 platforms: **Android 10+ (API 29)** primary; also ship **Flutter Web** (`apps/web`) sharing `app_core`.
- Language: **Dart only** (no TypeScript, no React Native, no Zustand, no Redux).
- Production-ready code. No placeholder architecture. No demo screens in the live router.
- Follow Clean Architecture: Presentation → Application → Domain → Data. UI must not touch SQLite or the filesystem directly.
- Keep changes modular. Match existing package boundaries.

## Do not implement (V1 replica)

These exist only as empty folders or old docs. **Skip them:**

- Collections UI (`packages/collections`)
- Activity Center (`packages/activity`)
- Notification Center screen
- Dedicated Media Library tab (Files **is** the library)
- Search as a bottom tab (search is a pushed screen)
- Drift/Hive (use sqflite + SharedPreferences)
- Cloud sync, AI organization, OCR search, encryption vault UI
- Desktop/tablet NavigationRail as the shipping shell (mobile is bottom `NavigationBar` only)
- Export UI, editable storage-root picker, per-tile delete of active downloads, Settings notification toggle

## Do implement (complete V1)

Milestones M1–M9, all complete in the original:

1. App shell, MD3 theme, 5-tab nav, 5-step onboarding, sqflite, storage folders, permissions, settings.
2. Download engine: URL wizard, max 3 concurrent, pause/resume Range, cancel/retry, pause-all/resume-all, progress (speed/ETA), foreground service + notifications, crash recovery, network auto-pause.
3. Media library / Files tab: search, category filters, favorites, sort, open/share/save to gallery/rename/move/delete.
4. In-app WebView browser: tabs, history, bookmarks, download detection → queue.
5. File manager: breadcrumbs, recursive scan, file detail, import detection.
6. Content intake: URL analyzer, clipboard monitor, share target, QR scanner.
7. Performance: TTL/LRU caches, 250ms progress throttle, SQLite indexes, virtualized lists, startup metrics.
8. Download history + `clearHistory()` (DB only, keep files), a11y semantics, QA checklist.
9. Version `1.0.0+2`, Android release (R8), signing template, CHANGELOG, GitHub Actions.

## Repository structure (required)

```
universal_downloader/
  apps/mobile/          # name: universal_downloader, version 1.0.0+2
  apps/web/             # name: universal_downloader_web
  packages/
    app_core/           # bootstrap, providers, ALL live screens
    browser/
    content_intake/
    database/
    design_system/
    download_engine/    # includes 16 social resolvers
    job_manager/
    media_library/
    navigation/         # MainShell, OnboardingFlow, AppRoutes used from shared_types
    notifications/
    performance/
    permissions/
    search/             # pub name: udm_search
    shared_types/
    shared_utils/
    storage/
    universal_viewer/
  melos.yaml            # only list implemented packages
  scripts/ci.sh
  README.md, RELEASE.md, CHANGELOG.md, QA_CHECKLIST.md
```

`apps/mobile/lib/main.dart` must only bootstrap: `FlutterForegroundTask.initCommunicationPort()`, `bootstrap()`, `UncontrolledProviderScope` + `WithForegroundTask` + `UniversalDownloaderApp`.

Live UI lives in `packages/app_core`. Placeholder widgets in `navigation/lib/src/screens/tab_screens.dart` must **not** be wired into the router.

## Navigation (exact)

Routes in `shared_types` `AppRoutes`:

| Path | Screen |
|------|--------|
| `/onboarding` | `OnboardingFlow` (not in shell) |
| `/home` | `HomeScreen` shell index 0 |
| `/downloads` | `DownloadsScreen` shell index 1 |
| `/downloads/history` | `DownloadHistoryScreen` nested |
| `/browser` | `BrowserScreen` shell index 2 |
| `/files` | `FilesScreen` shell index 3 |
| `/settings` | `SettingsScreen` shell index 4 |
| `/permissions` | constant only — **no GoRoute** |

Pushed via `Navigator` (not GoRouter): QR scanner, clipboard history, file detail, search, in-app viewer.

Dialogs/sheets: download wizard, media selection, format picker, intake actions, file actions/filters/import, browser tabs/history/bookmarks/page-downloads.

Onboarding first launch: `SharedPreferences` key `onboarding_complete`.

## Database (exact)

sqflite `schemaVersion = 4`.

`downloads`: id, url, domain, file_name, file_path, file_size, mime_type, status, priority, progress, created_at, started_at, completed_at, updated_at, thumbnail_url, platform, title.

`app_metadata`: key, value, updated_at.

Indexes: status, created_at DESC, updated_at DESC, file_path.

Migrations: v2 indexes created/updated; v3 file_path index; v4 add thumbnail_url, platform, title.

Statuses: QUEUED, PREPARING, DOWNLOADING, PAUSED, COMPLETED, FAILED, CANCELLED, VERIFYING.

Priorities: LOW, NORMAL, HIGH, URGENT.

`clearHistory()` deletes completed/failed/cancelled **rows only**, never files.

## Storage folders (exact)

Root download directory with categories: Videos, Images, Audio, Documents, Archives, APK, QR Downloads, Favorites, Vault, Temp, Logs.

## Download engine (exact)

- `DownloadManager`: maxConcurrent=3, maxRetries=3, Dio connectTimeout 30s, receiveTimeout 30m.
- Progress UI throttled 250ms (`ThrottleGate`).
- HTTP Range resume. Filename from Content-Disposition / URL.
- `ContentProviderRegistry` + platform resolvers. Generic HTTP URLs also enqueue.
- Multi-resource URLs → `MediaSelectionSheet`. If `formats.length > 1`, apply Settings preferred quality/format and/or `FormatPickerSheet`.
- Platforms (keep Twitter/X even if not in old marketing lists): YouTube (incl. Shorts), TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn, Telegram, Snapchat, Threads, WhatsApp, X/Twitter, Dailymotion.

## Android (exact)

Permissions: INTERNET, POST_NOTIFICATIONS, CAMERA, FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, WAKE_LOCK.

Share intent-filters: SEND text/plain, SEND */*, SEND_MULTIPLE */*.

`launchMode=singleTask`. ForegroundService `dataSync` from `flutter_foreground_task`.

Package `receive_sharing_intent: 1.8.1`, `mobile_scanner`, `webview_flutter`, `flutter_local_notifications`, `permission_handler`, `connectivity_plus`, `open_filex`, `share_plus`, `video_player`.

## Theme (exact)

Light-first. Light seed `#1B6EF3` (electricBlue). Dark seed `#2F9EAE` (signalCyan). Tokens in `UdmColors`. 8-point spacing (`UdmSpacing`). Card radius 12, sheet 16.

Widget tests depend on copy: **“Welcome to Universal Downloader”**, **“Get started”**, **“Download detected”**, history semantics `{fileName}, {status}`.

## Settings model (exact — do not invent keys)

`themeMode`, `clipboardMonitoringEnabled`, `storageRootPath` (display-only), `preferredQuality`, `preferredFormat`. Appearance system/light/dark. Performance panel. Clear caches. About v1.0.0. Link to download history.

## Implementation order

Follow `documentation/30_Rebuild_Checklist.md` M1→M9. After each milestone, `flutter analyze` and package tests must pass.

Read `documentation/` in this order: this prompt → 07 Engineering Standards → 26 Package Catalog → 27 Source Map → 11.2 Project Structure → 15 Download Engine → 08 Design System → 09 Navigation → 10 UX specs for the screens you are building.

## Quality bar

- Feature-based packages, barrel exports.
- Tests for engine, database, enqueue persistence, history clear keeps files.
- Accessibility: semantic headers on `UdmScaffold`.
- No business logic in `design_system`.
- Web: stub IO (sqflite_common_ffi_web, file store web, share intake stub, QR stub).
