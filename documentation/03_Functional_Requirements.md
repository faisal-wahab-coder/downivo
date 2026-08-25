# Functional Requirements

Project: Downivo  
Version: 1.0.0 as-built  
Status: Approved for rebuild

Each FR lists **priority** and **as-built status**. Recreate every `IMPLEMENTED` item. Skip `NOT_IN_V1`.

---

# MODULE 1 — Application lifecycle

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-061 | Launch: init widgets, prefs, storage paths, DB, download manager; show onboarding or Home | Critical | IMPLEMENTED (`bootstrap.dart`) |
| FR-062 | Restore unfinished downloads after restart | Critical | IMPLEMENTED (`createDownloadManager` restoreTasks) |
| FR-063 | Initialize clipboard, queue, notifications, DB, storage scanner on startup (after onboarding) | Critical | IMPLEMENTED (`AppInitializer`, intake/background scopes) |
| FR-064 | Recover after unexpected termination | Critical | IMPLEMENTED (persist tasks; restore; Range resume) |

No dedicated splash screen widget — Flutter launch theme is the splash (`LaunchTheme`).

---

# MODULE 2 — Download entry points

| ID | Requirement | Status |
|----|-------------|--------|
| FR paste URL | Home `UrlInputField` + Downloads wizard | IMPLEMENTED |
| FR browser | Detect links in WebView → sheet → enqueue | IMPLEMENTED |
| FR clipboard | Monitor when settings toggle on; prompt “Download detected” | IMPLEMENTED |
| FR share | Android SEND / SEND_MULTIPLE → intake sheet | IMPLEMENTED |
| FR QR | Home → camera scan → URL → intake | IMPLEMENTED |
| FR wizard | URL, optional name, priority Low/Normal/High/Urgent | IMPLEMENTED (`DownloadWizardDialog`) |

---

# MODULE 3 — Download engine

| ID | Requirement | Status |
|----|-------------|--------|
| FR queue | Max 3 concurrent | IMPLEMENTED |
| FR reorder | Drag queued items | IMPLEMENTED |
| FR priority | LOW/NORMAL/HIGH/URGENT persisted | IMPLEMENTED |
| FR pause/resume | HTTP Range | IMPLEMENTED |
| FR cancel | Active/paused | IMPLEMENTED |
| FR retry | Failed, maxRetries=3 | IMPLEMENTED |
| FR pause-all / resume-all | Downloads app bar | IMPLEMENTED |
| FR progress | Progress, bytes, speed, ETA; UI throttle 250ms | IMPLEMENTED |
| FR social | 16 platform resolvers via `ContentProviderRegistry` | IMPLEMENTED |
| FR generic HTTP | Any valid http(s) URL | IMPLEMENTED |
| FR multi-resource | `discoverAllResources` → media selection sheet | IMPLEMENTED |
| FR formats | Picker / preferred quality when `formats.length > 1` | IMPLEMENTED |
| FR filename | Content-Disposition / URL / user override | IMPLEMENTED |
| FR crash | Persist `DownloadRecord`; restore | IMPLEMENTED |

Statuses: queued, preparing, downloading, paused, completed, failed, cancelled, verifying.

---

# MODULE 4 — Background

| ID | Requirement | Status |
|----|-------------|--------|
| FR FG service | `flutter_foreground_task` dataSync | IMPLEMENTED |
| FR notifications | Progress + pause/cancel actions | IMPLEMENTED |
| FR connectivity | Auto-pause on loss, resume on reconnect | IMPLEMENTED (`connectivity_plus` + job_manager) |

---

# MODULE 5 — Storage and files

| ID | Requirement | Status |
|----|-------------|--------|
| FR folders | Category folders under storage root | IMPLEMENTED |
| FR scan | Library scan with 30s TTL cache | IMPLEMENTED |
| FR browse | Breadcrumb folder browser | IMPLEMENTED |
| FR search | In-Files query + global `AppSearchScreen` | IMPLEMENTED |
| FR sort | newest/oldest/nameAsc/nameDesc/largest/smallest | IMPLEMENTED |
| FR filters | Size + modified date | IMPLEMENTED |
| FR favorites | Star + Favorites folder | IMPLEMENTED |
| FR actions | Open, share, save to gallery (photos/videos), rename, move, delete | IMPLEMENTED |
| FR import | Detect unsorted files; move to category | IMPLEMENTED |
| FR storage UI | Home/Settings `StorageDashboard` | IMPLEMENTED |
| FR path picker | User-editable download root | NOT_IN_V1 (path is display-only) |
| FR-049 | Download history screen | IMPLEMENTED `/downloads/history` |
| FR-050 | Clear history without deleting files | IMPLEMENTED `clearHistory()` |

---

# MODULE 6 — Browser

| ID | Requirement | Status |
|----|-------------|--------|
| Tabs, history, bookmarks | IMPLEMENTED |
| Address bar, back/forward/refresh/home | IMPLEMENTED |
| Start page (Google / GitHub / Archive.org + search) | IMPLEMENTED |
| On-page download detection | IMPLEMENTED |

---

# MODULE 7 — Settings and onboarding

| ID | Requirement | Status |
|----|-------------|--------|
| 5-step onboarding | IMPLEMENTED |
| Permissions: notifications, camera, clipboard | IMPLEMENTED |
| Theme system/light/dark | IMPLEMENTED (default light if unset) |
| Clipboard monitoring toggle | IMPLEMENTED |
| Preferred quality/format | IMPLEMENTED |
| Performance panel | IMPLEMENTED |
| Clear caches | IMPLEMENTED |
| About current version; What's new after update | IMPLEMENTED |
| Notification settings toggle | NOT_IN_V1 |

---

# MODULE 8 — Viewer

| ID | Requirement | Status |
|----|-------------|--------|
| In-app video/audio | IMPLEMENTED `UniversalViewerScreen` |
| In-app images | IMPLEMENTED `ImageGalleryScreen` (swipe siblings) |
| Other types | System open via `open_filex` | IMPLEMENTED |

---

# MODULE 9 — Explicitly not in V1

Collections, Activity Center, Notification Center, Smart Scanner (beyond QR), dedicated Storage Center screen, cloud, AI, encryption product, export UI.
