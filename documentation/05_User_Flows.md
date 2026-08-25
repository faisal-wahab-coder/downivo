# User Flows (as-built)

---

## Flow A — First launch

1. Process starts → Android `LaunchTheme`.
2. `main()` → `FlutterForegroundTask.initCommunicationPort()` → `bootstrap()`.
3. If `onboarding_complete` is not true → `/onboarding` (5 steps: welcome, storage init, notifications, camera, clipboard/finish).
4. Complete → set pref → `context.go(/home)`.

Copy that tests depend on: “Welcome to Downivo”, “Get started”.

---

## Flow B — Paste URL on Home (happy path)

1. User focuses Home URL field (paste supported).
2. App validates URL; if social host, `ContentProviderRegistry.canHandle` / resolve.
3. States: empty → typing → invalid → resolving → resolved preview (`MediaPreviewCard`) or unsupported helper.
4. User taps Download.
5. If multiple resources → `MediaSelectionSheet`. If multiple formats → preferred format from settings and/or `FormatPickerSheet`.
6. `enqueueUrlFlow` → `DownloadManager` → task in queue (max 3 active).
7. Home shows active + recent completed (max 5). User can open Downloads tab.

---

## Flow C — Downloads wizard

1. FAB or empty CTA on `/downloads`.
2. `DownloadWizardDialog`: URL, optional filename, priority.
3. Invalid URL → snackbar. Valid → enqueue or media sheet.

---

## Flow D — Queue operations

- Pause / resume / cancel on tile.
- Retry on failed.
- Reorder queued via drag handle.
- Pause all / resume all in app bar.
- Tap a completed tile to open (video/audio → in-app viewer). Share / Save to Gallery stay as trailing actions. Photos and videos also offer Save to Gallery.
- If the file was deleted in Files, the row stays with a **Removed from Files** chip.

---

## Flow E — Background

1. With active tasks, `job_manager` keeps a dataSync foreground service.
2. Notifications show progress; actions pause/cancel.
3. Connectivity loss pauses; reconnect resumes.
4. Process death: records remain; restore on next `DownloadManager` create.

---

## Flow F — Files

1. `/files` root = category folders.
2. Open folder → files. Breadcrumbs back to root.
3. Search overrides browse. Filter sheet: size + date. Sort menu.
4. Tap an image → `ImageGalleryScreen` (full-screen, swipe siblings in the folder or search results). Viewer 3-dot → `FileDetailScreen`. Bottom More actions → `FileActionsSheet`. Tap video/audio → in-app player. Other types → `FileDetailScreen` (Name, Category, Size, Modified, Type, Location).
5. Long-press / more on the list or grid tile → Open, Share, Save to Gallery (photos/videos), Favorite, Rename, Move, Delete. Tile more-actions stay on the row.
6. Unsorted imports → banner → `_ImportSheet` → move to category.

---

## Flow G — Browser

1. `/browser` start page or WebView.
2. Toolbar: back, forward, close, refresh, home, address, tabs, bookmarks, history, page downloads, bookmark toggle.
3. Detected downloadable links → sheet → queue.

---

## Flow H — Clipboard

1. Settings `clipboardMonitoringEnabled` true.
2. Foreground polling (lifecycle-aware).
3. New URL → modal `showIntakeActionSheet` copy **Download detected**.
4. Actions: Download, Open in browser, Dismiss. History via Home → `ClipboardHistoryScreen`.

---

## Flow I — Share

1. External app SEND text or files.
2. `receive_sharing_intent` → intake: download URL, import files, or show text.
3. Imported files appear as pending on Files.

---

## Flow J — QR

1. Home → Scan QR → `QrScannerScreen` (`mobile_scanner`).
2. URL detected → same intake/download pipeline.

---

## Flow K — History

1. From Downloads app bar, Home “View all”, or Settings.
2. `/downloads/history` lists completed/failed/cancelled.
3. Clear → confirm dialog → `clearHistory()` deletes rows, **files stay**.

---

## Flow L — Search

1. Search icon on Home or Downloads.
2. `AppSearchScreen` queries files + download history (`udm_search`).
3. Recent queries in SharedPreferences. Not a shell tab.
