# Changelog

All notable changes to this project will be documented here.

The product changelog with historical releases also lives in [`downivo/CHANGELOG.md`](downivo/CHANGELOG.md). Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## Unreleased

### Added

- MIT license, contributing guide, code of conduct, and security policy
- GitHub issue and pull request templates
- Contributor documentation under `docs/`
- `.env.example` for optional analytics and local tooling variables

### Changed

- `.gitignore` now excludes live `google-services.json` and additional secret patterns
- CI validates `analytics`, `search`, and `universal_viewer` in addition to existing packages
- Removed private Bitbucket compare URLs from the product changelog

### Fixed

### Performance

### Security

- Stopped tracking `downivo/apps/mobile/android/app/google-services.json` (Firebase Android config). The file remains gitignored for local development. **Rotate the Firebase Android API key before the first public push** — see [docs/GIT_HISTORY_SECURITY.md](docs/GIT_HISTORY_SECURITY.md).

## 1.2.0 - 2026-08-25

### Added

- What's new dialog after an app update, also available from Settings → About

## 1.1.0 - 2026-08-25

Sideload / internal release (Android arm64). Gallery, in-app photo viewer, and social URL resolvers.

### Added

- Save to Gallery for photos and videos
- In-app image gallery
- Social and media URL resolvers: YouTube, TikTok, Instagram, Facebook, Twitter/X, Reddit, Vimeo, Dailymotion, Twitch, Pinterest, LinkedIn, Snapchat, SoundCloud, Telegram, WhatsApp, and Threads

## 1.0.0 - 2026-08-15

First production release (Android, V1 scope).

### Added

- Five-tab app shell with Material Design 3 theme and onboarding
- Download engine: queue, pause/resume, cancel, retry, HTTP Range, background service
- Managed storage with category folders and media library
- In-app browser with tabs, bookmarks, history, and link detection
- File manager, content intake (clipboard, share, QR)
- Download history with clear-history (preserves files on disk)

### Security

- Release builds use R8 minification and resource shrinking
- Production signing via local `key.properties` (not committed)

## 1.0.0-rc.1 - 2026-08-15

Release candidate — feature complete, QA checklist provided.
