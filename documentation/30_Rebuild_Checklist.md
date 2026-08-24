# 30. Rebuild Checklist

Work **in this order**. Do not skip to social resolvers before the queue works with a generic HTTP file.

## Environment

- [ ] Flutter 3.24+ / Dart 3.10
- [ ] Android SDK API 29+
- [ ] Create `universal_downloader/` Melos workspace

## M1 Foundation

- [ ] `shared_types` (routes, status, priority, theme enum)
- [ ] `design_system` (UdmColors, AppTheme, spacing, UdmScaffold, EmptyState, onboarding widgets)
- [ ] `navigation` (MainShell 5 tabs, OnboardingFlow)
- [ ] `database` schema v4 (can start v4 directly)
- [ ] `storage` categories + FileStore + initializer
- [ ] `permissions`
- [ ] `app_core` bootstrap + settings + router
- [ ] `apps/mobile` main()
- [ ] Onboarding 5 steps; first-run flag
- [ ] Settings theme + clipboard toggle + path display

## M2 Engine

- [ ] `DownloadManager` generic HTTP, persist, restore
- [ ] Max 3, pause/resume Range, cancel, retry, reorder, pause-all
- [ ] Downloads + Home queue UI + wizard dialog
- [ ] `job_manager` + notifications + manifest service
- [ ] Network auto-pause

## M3–M5 Files

- [ ] `media_library` scan
- [ ] Files tab browse/search/sort/filter/favorites/actions
- [ ] File detail + import banner
- [ ] StorageDashboard

## M4 Browser

- [ ] `browser` package
- [ ] WebView screen + detector → enqueue

## M6 Intake

- [ ] `content_intake`
- [ ] Clipboard monitor + “Download detected”
- [ ] Share target
- [ ] QR scanner

## M2+ Social

- [ ] `ContentProviderRegistry` + all 16 resolvers
- [ ] MediaSelectionSheet + format picker
- [ ] Host matching on `SocialPlatform`

## M7 Performance

- [ ] `performance` TTL/LRU/throttle
- [ ] Scan cache 30s, indexes, virtualized lists

## M8–M9 Release

- [ ] History + clearHistory keeps files
- [ ] `universal_viewer`
- [ ] `udm_search` + AppSearchScreen
- [ ] Semantics
- [ ] `apps/web` stubs
- [ ] `scripts/ci.sh` green
- [ ] Version 1.0.0+2, RELEASE/CHANGELOG/QA_CHECKLIST

## Acceptance

- [ ] Five tabs match IA
- [ ] Paste URL on Home downloads
- [ ] Background notification while downloading
- [ ] Files show completed file
- [ ] Share URL into app works on device
- [ ] Clear history does not delete the file on disk
