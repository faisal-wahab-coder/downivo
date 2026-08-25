# Product Requirements Document (PRD)

Project: Downivo  
Version: 1.0.0 as-built  
Status: Approved for rebuild

---

# 1. Purpose

This PRD defines the **shipped V1** product. Recreate this scope. Do not expand into Media Hub / cloud / AI.

Downivo is a professional Android download manager that downloads, organizes, previews, and manages files from supported and authorized sources.

---

# 2. Business objectives

| ID | Objective |
|----|-----------|
| BO-001 | Most user-friendly Android downloader |
| BO-002 | Start a download in at most 3 taps (Home paste → Download) |
| BO-003 | Premium UX without sacrificing performance |
| BO-004 | Architecture that *could* grow into a Media Hub later (packages), without shipping those features |
| BO-005 | Enterprise-grade file organization (category folders) |
| BO-006 | Reliable long-running / background downloads |

---

# 3. Product objectives

The application shall:

- Download files from HTTP(S) and supported public social/media URLs
- Organize files into category folders automatically
- Search downloads and files quickly
- Manage a concurrent queue (max 3)
- Minimize interaction via clipboard, share, QR, browser detection
- Remain usable with large libraries (virtualized lists, scan cache)

---

# 4. In scope (V1)

- Onboarding (5 steps) + permissions
- Home dashboard with URL hero
- Downloads queue + history
- File manager (library)
- In-app browser
- Clipboard monitoring (settings toggle)
- Android share target
- QR scanner
- Settings (theme, quality/format prefs, clipboard, storage path display, performance, caches)
- Background foreground service + notifications
- Light / dark / system theme
- Flutter Web runner with stubs for camera/share/foreground

---

# 5. Out of scope (V1 replica)

- iOS, desktop, tablet adaptive shell as the shipping UX
- Cloud backup/sync
- User accounts
- Collections, Activity Center, Notification Center screens
- Encrypted vault product, OCR, AI tagging
- Per-item history delete, export, storage-root folder picker
- Settings notification toggle (permission is onboarding-only)
- Crashlytics / PostHog / product analytics (V1 has none; see [31](31_Observability_Analytics.md) when that milestone starts)

---

# 6. Personas

**Power downloader** — queues many files, needs pause/resume, reorder, history.

**Casual user** — pastes a link on Home, taps Download, finds the file under Files.

**Browser user** — discovers a file while browsing in-app, confirms download.

---

# 7. Primary user journeys

1. Cold start → onboarding → Home.
2. Paste URL on Home → resolve preview → Download → appears in queue.
3. Multi-item page → select media sheet → enqueue N items.
4. Pause / leave app → foreground service continues → resume UI on return.
5. Files tab → browse category → open / share / save to gallery / rename / favorite / delete.
6. Share URL from another app → intake sheet → download or open in browser.
7. Copy link with clipboard monitor on → “Download detected” sheet.
8. Scan QR → URL → same intake/download path.
9. Downloads → history → clear history (files remain on disk).

---

# 8. Acceptance bar for a replica

A copy is acceptable when:

- All five shell tabs work
- Onboarding gates first launch
- HTTP and at least the 16 platform resolvers exist with the same class names/files
- Queue semantics match (3 concurrent, Range resume, statuses listed in shared_types)
- Files, browser, clipboard, share, QR, history, settings match the screen map
- `schemaVersion` is 4 with the columns and indexes documented in 22_Database
- Tests cover enqueue persistence and history-clear-keeps-files
- Android share intents and foreground service are declared

---

# 9. Non-goals for the replica Cursor

Do not “improve” information architecture. Do not add tabs. Do not replace sqflite with Drift. Do not add a Search tab. Match the as-built product.
