# Downivo

Flutter monorepo for Downivo (Android + Web). Contributor onboarding for the public project lives in the repository root [README.md](../README.md).

## Structure

```
downivo/
├── apps/
│   ├── mobile/          # Flutter Android application
│   └── web/             # Flutter Web application
└── packages/
    ├── app_core/        # Bootstrap, DI, app configuration
    ├── design_system/   # Material Design 3 theme & components
    ├── download_engine/ # Queue, workers, pause/resume
    ├── job_manager/     # Foreground service & connectivity
    ├── notifications/   # Download progress notifications
    ├── navigation/      # go_router routes & shell
    └── shared_types/    # Shared enums & types
```

## Requirements

- Flutter 3.x / Dart 3.x
- Android SDK (API 29+)

## Getting started

```bash
cd downivo/apps/mobile
flutter pub get
flutter run
```

Web:

```bash
cd downivo/apps/web
flutter pub get
flutter run -d chrome
```

Validate the monorepo: `bash scripts/ci.sh` from `downivo/`.

## Documentation

Product and architecture specs live in [`../documentation/`](../documentation/README.md). Open-source contributor guides: [`../docs/`](../docs/README.md).

Release engineering: [`RELEASE.md`](RELEASE.md) · [`CHANGELOG.md`](CHANGELOG.md) · [`QA_CHECKLIST.md`](QA_CHECKLIST.md)

## Milestones

**M1 — Foundation (complete)**

- App shell + MD3 theme + 5-tab navigation
- Multi-step onboarding (5 screens)
- SQLite database v1 (`downloads`, `app_metadata`)
- Storage folder initialization
- Permission service (notifications, camera)
- Settings (theme, clipboard toggle, download folder path)

**M2 — Download Engine (complete)**

- [x] URL validation and download wizard
- [x] Queue management (max 3 concurrent, reorder, priority)
- [x] Pause / resume with HTTP Range support
- [x] Cancel, retry, pause-all / resume-all
- [x] Progress UI (speed, ETA, remaining size)
- [x] Background foreground service + notifications
- [x] Notification actions (pause / cancel)
- [x] Crash recovery and integrity verification
- [x] Network loss auto-pause / reconnect resume
- [x] Home tab active + recent downloads summary

**M3 — Storage Management (complete)**

- [x] Media library scans managed category folders
- [x] Files tab: search, category filters, favorites, sort
- [x] Open, share, rename, move, delete file actions
- [x] Home tab managed storage summary
- [x] Favorites persisted locally

**M4 — Browser Integration (complete)**

- [x] `browser` package: tabs, history, bookmarks, URL utils, download detector
- [x] WebView browser with address bar, back/forward/refresh, home
- [x] Multi-tab session, history and bookmarks sheets
- [x] Direct URL + on-page link download detection
- [x] Download wizard integration → download engine queue

**M5 — File Manager (complete)**

- [x] Folder browser with breadcrumb navigation (root → category → subfolders)
- [x] Recursive library scan + global search with size/date filters
- [x] File detail screen with metadata and image previews
- [x] Import detection for newly added files (FR-035)
- [x] Move unsorted imports into category folders

**M6 — Advanced Features (complete)**

- [x] `content_intake` package — URL analyzer, clipboard, share, QR resolver
- [x] Foreground clipboard monitoring with download prompts (settings toggle)
- [x] Clipboard history screen
- [x] Android share target — receive URLs, text, and files
- [x] QR scanner with camera — download / browser / import actions

**M7 — Optimization (complete)**

- [x] `performance` package — TTL cache, LRU cache, throttling, metrics
- [x] Library scan cache (30s TTL) with folder counts from cache
- [x] Throttled download progress UI updates (250ms)
- [x] SQLite v2 indexes on `created_at` / `updated_at`
- [x] Virtualized file lists + collapsible completed/failed downloads
- [x] Lifecycle-aware clipboard polling; downsized image thumbnails
- [x] Parallel startup init + performance panel in Settings

**M8 — Release Candidate (complete)**

- [x] Download history screen (FR-049) with clear history without deleting files (FR-050)
- [x] `clearHistory()` pipeline — database → repository → download manager
- [x] Integration tests — enqueue persistence, history clear keeps files
- [x] Widget/integration tests for download history and bootstrap enqueue
- [x] Accessibility — semantic headers and screen labels on `UdmScaffold`
- [x] Manual QA checklist (`QA_CHECKLIST.md`)
- [x] Version `1.0.0-rc.1`

**M9 — Production Release (complete)**

- [x] Version `1.0.0+2` (semver production)
- [x] Android release build — R8 minify, shrink resources, ProGuard rules
- [x] Signing template (`key.properties.example`) + [`RELEASE.md`](RELEASE.md)
- [x] [`CHANGELOG.md`](CHANGELOG.md) for 1.0.0
- [x] GitHub Actions — CI (analyze, test, AAB on main) + release workflow on tags
- [x] Production QA checklist updated

**1.1.0 — Gallery & social (complete)**

- [x] Version `1.1.0+3`
- [x] Save to Gallery + in-app image gallery
- [x] Social/media URL resolvers (YouTube, TikTok, Instagram, and others)
- [x] [`CHANGELOG.md`](CHANGELOG.md) for 1.1.0

**1.2.0 — What's new (complete)**

- [x] Version `1.2.0+4`
- [x] What's new dialog after updates (also Settings → About)
- [x] [`CHANGELOG.md`](CHANGELOG.md) for 1.2.0
