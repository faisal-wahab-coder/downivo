# Current Feature Map

Code wins. Status: `IMPLEMENTED` · `PARTIALLY_IMPLEMENTED` · `NOT_IMPLEMENTED`.

Stack: Flutter / Dart Android app. UI in `app_core`. MD3 `design_system`. Riverpod. GoRouter shell.

---

## 1. URL downloading — IMPLEMENTED

Home `UrlInputField` + `DownloadWizardDialog`. `enqueueUrlFlow` / `ContentProviderRegistry`. Preferred quality/format when `formats.length > 1`.

## 2. Social / platform downloads — IMPLEMENTED

Resolvers under `download_engine/lib/src/content_providers/`. Unified wizard + media sheet. No per-network screens.

| Platform | File |
|----------|------|
| YouTube (+ Shorts) | `youtube_resolver.dart` |
| TikTok | `tiktok_resolver.dart` |
| Instagram | `instagram_graphql_resolver.dart` |
| Facebook | `facebook_resolver.dart` |
| SoundCloud | `soundcloud_resolver.dart` |
| Reddit | `reddit_resolver.dart` |
| Pinterest | `pinterest_resolver.dart` |
| Vimeo | `vimeo_resolver.dart` |
| Twitch | `twitch_resolver.dart` |
| LinkedIn | `linkedin_resolver.dart` |
| Telegram | `telegram_resolver.dart` |
| Snapchat | `snapchat_resolver.dart` |
| Threads | `threads_resolver.dart` |
| WhatsApp | `whatsapp_resolver.dart` |
| X (Twitter) | `twitter_resolver.dart` — **keep** |
| Dailymotion | `dailymotion_resolver.dart` |

`DiscoveredResource`: directUrl, fileName, platform, pageUrl, title, mimeType, thumbnailUrl, requestHeaders, optional author, durationSeconds, width, height, contentLengthBytes, kind, formats.

## 3. Media types — IMPLEMENTED

Mime-driven. Categories: videos, images, audio, documents, archives, apk, qrDownloads, favorites, vault, temp, logs.

## 4. Queue — IMPLEMENTED

Pause, resume, cancel, retry, reorder queued, pause-all, resume-all, tap completed row to open, share, save to gallery (photos/videos). Files delete clears `file_path` and shows **Removed from Files**. Per-tile delete of active tasks: **not** in V1.

`DownloadStatus`: queued, preparing, downloading, paused, completed, failed, cancelled, verifying.

## 5. Background — IMPLEMENTED

`download_background_scope.dart`, `job_manager`, `flutter_foreground_task`, notifications.

## 6. File manager / library — IMPLEMENTED

`/files` is the library. `packages/media_library` backend. Sort `LibrarySort`. Favorites. Import banner. Tap image → `ImageGalleryScreen` (swipe siblings; 3-dot → details). List/grid more-actions stay on the tile.

Actions: Open, Share, Save to Gallery (photos/videos), Favorite, Rename, Move, Delete — all implemented. Multi-select: not in V1.

## 7. Storage dashboard — IMPLEMENTED

Managed bytes from `CategorySummary`. Android volume via StatFs. Hidden on web when no volume stats. Path display-only.

## 8. Browser — IMPLEMENTED

WebView, toolbar, tabs, bookmarks, history, download detection.

## 9. Clipboard — IMPLEMENTED

Settings toggle. Intake sheet. History screen. Copy “Download detected”.

## 10. Share / import — IMPLEMENTED

`receive_sharing_intent`. Import files + download URLs. No standalone Import route. No export UI.

## 11. QR — IMPLEMENTED

`QrScannerScreen` + `mobile_scanner`. Not in `AppRoutes`.

## 12. Search — IMPLEMENTED

`AppSearchScreen` + `udm_search`. Recent queries in prefs. Not a tab.

## 13. History — IMPLEMENTED

`/downloads/history`. Clear all. No per-item delete.

## 14. Notifications — PARTIALLY

Engine + onboarding permission. No Settings toggle. No notification center.

## 15. Settings — IMPLEMENTED

Keys only: `themeMode`, `clipboardMonitoringEnabled`, `storageRootPath`, `preferredQuality`, `preferredFormat`. Do not invent privacy/security groups.

## 16. Onboarding — IMPLEMENTED

5 steps. Permissions: notifications, camera, clipboard (`AppPermission`).

## 17. Viewer — IMPLEMENTED

`UniversalViewerScreen` for local video/audio; `ImageGalleryScreen` for photos; else system open.

## Not implemented (do not add)

Collections, Activity Center, Notification Center, Smart Scanner beyond QR, desktop rail as product shell, Media Library tab, Search tab.
