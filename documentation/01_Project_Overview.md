# Universal Downloader — Project Overview

Version: 1.0.0 (as-built)  
Document type: Project Overview  
Status: Approved for rebuild  
Last updated: August 2026

---

# 1. Introduction

Universal Downloader is a modern **Android** (and Flutter Web) application for downloading, organizing, previewing, and managing files from supported and authorized sources.

Unlike a classic download manager that only fetches bytes, this product is a complete download experience: queue management, background transfers, intelligent source resolution, file organization, an in-app browser, clipboard/share/QR intake, and a Material Design 3 interface.

**V1 is complete** (milestones M1–M9). Future versions may grow toward a Media Hub; those features are out of scope for a V1 replica.

---

# 2. Vision

Create the most modern, user-friendly downloader while respecting platform policies, user privacy, and intellectual property rights.

The app should feel as polished as first-party Google or Microsoft software.

---

# 3. Mission

Provide a beautiful, intelligent, reliable downloader that simplifies downloads, organization, and management while remaining lightweight, secure, and performant.

---

# 4. Product goals

**Primary**

- Fast downloads
- Beautiful MD3 UI
- Easy to use (≤ 3 taps to start a download)
- Smart URL / social-source detection
- Automatic file organization
- Background downloading
- Resume interrupted downloads
- Powerful file management
- Premium UX

**Secondary (not in V1 replica)**

- Cloud sync, desktop companion, AI organization, OCR search, smart recommendations

---

# 5. Target user

Android users who download videos, audio, documents, and other files from the open web and supported public social/media URLs, and who want one place to queue, pause, resume, and organize those files.

---

# 6. Platforms (as-built)

| Platform | Status |
|----------|--------|
| Android 10+ (API 29) | Shipping product |
| Flutter Web | Shipping runner (`apps/web`), reduced native features |
| iOS / desktop / wear | Not V1 |

Application version: **`1.2.0+4`**.

---

# 7. Technology stack (as-built)

| Layer | Choice |
|-------|--------|
| UI framework | Flutter 3.24+ |
| Language | Dart 3.10 |
| State | Riverpod 2.6 |
| Navigation | go_router 16 |
| HTTP | Dio 5.9 |
| Database | sqflite 2.4, schema v4 |
| Settings | shared_preferences |
| Background | flutter_foreground_task 9 |
| Notifications | flutter_local_notifications 19 |
| Browser | webview_flutter 4 |
| QR | mobile_scanner 7 |
| Share | receive_sharing_intent 1.8.1 |
| Theme | Material Design 3 |
| Workspace | Melos 8 |

---

# 8. Architecture summary

Feature-based Melos monorepo:

- `apps/mobile` and `apps/web` are thin runners.
- `packages/app_core` owns bootstrap, Riverpod graph, GoRouter, and all live screens.
- Domain packages: `download_engine`, `media_library`, `browser`, `content_intake`, `storage`, `database`, `job_manager`, etc.
- `design_system` is UI-only (no business logic).

Clean Architecture layers: Presentation (`app_core` features) → application services (managers/providers) → domain types (`shared_types`) → data (`database`, `storage`, Dio).

---

# 9. Core capabilities (shipped)

1. Direct HTTP(S) downloads
2. Sixteen social/media resolvers (YouTube, TikTok, Instagram, Facebook, X, Reddit, Pinterest, LinkedIn, Threads, SoundCloud, Vimeo, Twitch, Telegram, Snapchat, WhatsApp, Dailymotion)
3. Queue with 3 concurrent workers, reorder, priorities
4. Pause / resume (HTTP Range), cancel, retry, pause-all / resume-all
5. Foreground service + progress notifications
6. Crash recovery / queue restore
7. File manager with categories, search, favorites, import
8. In-app browser with download detection
9. Clipboard monitor, share target, QR scanner
10. Light / dark / system theme
11. Download history with clear-without-delete-files

---

# 10. Success metrics (original product bar)

- Startup < 2 seconds (measured via `performance` package)
- Download success rate > 99%
- Crash-free sessions > 99.5%
- App size < 60 MB
- Battery-aware background work via a single dataSync foreground service

---

# 11. Legal / policy

Download only from sources the user is authorized to access. Do not circumvent DRM, private authenticated CDNs (e.g. WhatsApp `mmg.whatsapp.net`), or paywalls. Resolvers that hit auth walls must fail clearly, not scrape private content.

---

# 12. Folder categories on disk

Videos, Images, Audio, Documents, Archives, APK, QR Downloads, Favorites, Vault, Temp, Logs.
