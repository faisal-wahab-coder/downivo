# Product Architecture (as-built)

---

# 1. Shape

```
┌─────────────────────────────────────────────┐
│ apps/mobile  ·  apps/web                    │
│  thin main() + platform plugins             │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│ packages/app_core                           │
│  bootstrap · providers · GoRouter · screens │
└───────┬─────────────┬─────────────┬─────────┘
        │             │             │
   download_engine  media_library  browser
   content_intake   job_manager    navigation
   database         storage        design_system
   permissions      notifications  performance
   search           universal_viewer
   shared_types     shared_utils
```

---

# 2. Runtime composition

1. `bootstrap()` creates `AppInitializer`, `StoragePaths`, `SharedPreferences`, `DownloadManager`, `GoRouter`.
2. `ProviderContainer` overrides: prefs, initializer, storage path, download manager, router.
3. `UniversalDownloaderApp` watches theme + router.
4. Feature widgets read Riverpod providers (`downloadListProvider`, `libraryBrowseProvider`, `settingsProvider`, …).
5. `DownloadManager.tasksStream` is the live queue bus (no separate event-bus package).

---

# 3. Data plane

- **Metadata:** sqflite `downloads` + `app_metadata`.
- **Bytes:** filesystem via `FileStore` under `StoragePaths` category folders (IO) or web memory/file store.
- **Prefs:** onboarding flag, theme, clipboard toggle, storage path string, preferred quality/format, recent searches.

---

# 4. Intake plane

`content_intake` analyzes URLs, clipboard history, share payloads, QR text. UI in `app_core` (`intake_prompt_sheet`, `IntakeActionHandler`). Actions: download, open browser, import files, show text.

---

# 5. Work plane

`DownloadManager` validates, resolves (social registry or direct URL), queues, runs ≤3 Dio downloads, writes files, updates DB. `job_manager` binds that work to a foreground service + connectivity. `notifications` mirrors progress.

---

# 6. Library plane

`media_library` scans storage folders, favorites store, search helpers. `app_core` Files UI. `universal_viewer` plays local AV.

---

# 7. Platform isolation

Conditional imports:

- `sqflite_init_io.dart` / `_web.dart` / `_stub.dart`
- `share_intake_io.dart` / `_stub.dart`
- `qr_navigation_io.dart` / `_stub.dart`
- `file_store_factory_io.dart` / `_web.dart`
- `storage_info_load_io.dart` / `_web.dart`

Do not put `dart:io` in shared UI files without a stub.
