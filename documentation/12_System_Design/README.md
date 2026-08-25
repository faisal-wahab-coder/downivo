# 12. System Design (as-built)

Original `/docs/12_System_Design` described a larger platform. This folder records **what to implement** vs **what to skip**.

| File | V1 replica |
|------|------------|
| 12.1 Overview | Follow 11.1 |
| 12.2 Design principles | Follow 07 |
| 12.3 Package specifications | Follow 26 |
| 12.4 DI | Riverpod overrides in bootstrap — **no GetIt required** |
| 12.5 Event bus | **Do not add.** Use `tasksStream` |
| 12.6 Repository | `DownloadRepository` only for downloads |
| 12.7 Navigation | Follow 09 |
| 12.8 Feature modules | `app_core/features/*` |
| 12.9 UI components | design_system + feature widgets |
| 12.10 Queue algorithm | max 3, priority, `_queueOrder` |
| 12.11 State machine | `DownloadStatus` enum |
| 12.12 Storage manager | `storage` package |
| 12.13 Browser engine | `browser` + WebView |
| 12.14 Media library | `media_library` |
| 12.15 Search | `udm_search` |
| 12.16 Thumbnail generator | **No package.** Inline downsized thumbs |
| 12.17 Metadata extractor | **No package.** Resolvers fill DiscoveredResource |
| 12.18 Notification engine | `notifications` package |
| 12.19 Activity timeline | **DO NOT BUILD** |
| 12.20 Background scheduler | Foreground task only |
| 12.21 Permission manager | `permissions` |
| 12.22 Settings manager | `settingsProvider` + prefs |
| 12.23 Analytics | **Implemented** — [31](../31_Observability_Analytics.md); no-op without keys |
| 12.24 Logging | `AppLogger` in analytics package |
| 12.25 Errors | formatter + snackbars |
| 12.26 File import | intake + Files import sheet |
| 12.27 File export | **DO NOT BUILD UI** (Share + Save to Gallery on the file) |
| 12.28 Theme engine | `AppTheme` |
| 12.29 Animation | Material defaults only |
| 12.30 Accessibility | UdmScaffold semantics |
| 12.31 Performance | `performance` package |
| 12.32 Memory | LRU/TTL caches, downsized images |
| 12.33 Offline | Queue persists; downloads need network |
| 12.34 Sync | **DO NOT BUILD** |
| 12.35 AI | **DO NOT BUILD** |
