# Changelog

All notable changes to Downivo are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Open-source GitHub preparation (license, contributing guides, issue/PR templates).

## [1.2.0] - 2026-08-25

### Added

- What's new dialog after an app update, also available from Settings → About.

## [1.1.0] - 2026-08-25

Sideload / internal release (Android arm64). Gallery, in-app photo viewer, and social URL resolvers.

### Added

- Save to Gallery for photos and videos (Files actions, file details, completed downloads). Copies into the system gallery album `Downivo`; originals stay in the app library.
- In-app image gallery: tap a photo in Files to view it full-screen, swipe to other images in the folder, and open details from the viewer 3-dot. More actions for the current photo sits on the image. List/grid More actions stay on the tile. File details is metadata only.
- Social and media URL resolvers: YouTube, TikTok, Instagram, Facebook, Twitter/X, Reddit, Vimeo, Dailymotion, Twitch, Pinterest, LinkedIn, Snapchat, SoundCloud, Telegram, WhatsApp, and Threads.

## [1.0.0] - 2026-08-15

First production release (Android, V1 scope).

### Added

- Five-tab app shell with Material Design 3 theme and onboarding
- Download engine: queue, pause/resume, cancel, retry, HTTP Range, background service
- Managed storage with category folders and media library
- In-app browser with tabs, bookmarks, history, and link detection
- File manager: browse, search, filters, favorites, import detection, file actions
- Content intake: clipboard monitoring, share target, QR scanner, clipboard history
- Performance optimizations: scan cache, throttled UI, SQLite indexes, virtual lists
- Download history with clear-history (preserves files on disk)
- Settings: theme, clipboard toggle, storage path, performance metrics

### Security

- Release builds use R8 minification and resource shrinking
- Production signing via local `key.properties` (not committed)

## [1.0.0-rc.1] - 2026-08-15

Release candidate — feature complete, QA checklist provided.
