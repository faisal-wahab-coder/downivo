# Pinterest Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

Pinterest is not named in `docs/`, but it is a declared `SocialPlatform` and the Content Provider Architecture (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) requires every provider to:

- Recognize supported URLs
- Discover downloadable resources where permitted
- Extract metadata (title, filename, MIME, thumbnail, author)
- Provide download instructions to the existing Download Engine
- Handle errors without crashing
- Sanitize filenames and prevent path traversal
- Never bypass authentication, DRM, paywalls, or platform ToS
- Ship unit tests, mock responses, invalid URL tests, and error tests

Images and videos are first-class storage categories. Playlist-style bulk download (`supportsPlaylists` in 11.5 §12) is optional. Board and profile URLs are collections, not a single media item — they are **not** bulk-downloaded.

---

## Feature Audit

| # | Feature | Required? | Before | After | Status |
|---|---------|-----------|--------|-------|--------|
| 1 | Pinterest URL detection | YES | PARTIAL (pinterest.com / pin.it only) | IMPLEMENTED (regional TLDs + pinimg CDN) | COMPLETE |
| 2 | Pinterest URL parsing | YES | MISSING | IMPLEMENTED (`PinterestUri`) | COMPLETE |
| 3 | URL normalization | YES | MISSING | IMPLEMENTED | COMPLETE |
| 4 | Platform identification | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 5 | Pin detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 6 | Image Pin detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 7 | Video Pin detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 8 | Multiple-image detection | YES | MISSING | IMPLEMENTED (Idea Pin pages) | COMPLETE |
| 9 | Idea Pin detection | YES | MISSING | IMPLEMENTED (`story_pin_data`) | COMPLETE |
| 10 | Board detection | YES (reject download) | MISSING | IMPLEMENTED | COMPLETE |
| 11 | Direct media URL detection | YES | MISSING | IMPLEMENTED (`i.pinimg.com`, `v1.pinimg.com`) | COMPLETE |
| 12 | Share / `pin.it` handling | YES | PARTIAL (host only) | IMPLEMENTED (redirect + og:url) | COMPLETE |
| 13 | Pin ID extraction | YES | MISSING | IMPLEMENTED (slug ignored) | COMPLETE |
| 14 | Board ID extraction | YES (slug from URL) | MISSING | IMPLEMENTED (user + board slug) | COMPLETE |
| 15 | Author/profile extraction | YES | MISSING | IMPLEMENTED (`PinterestPinInfo`) | COMPLETE |
| 16 | Metadata extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 17 | Image extraction | YES | PARTIAL (generic OG fallback only) | IMPLEMENTED (`images.orig`) | COMPLETE |
| 18 | Video extraction | YES | PARTIAL (og:video / mp4 regex) | IMPLEMENTED (best MP4) | COMPLETE |
| 19 | Thumbnail extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 20 | Original / high-res extraction | YES | MISSING | IMPLEMENTED (`orig` + `/originals/` upgrade) | COMPLETE |
| 21 | Download Engine integration | YES | IMPLEMENTED (shared) | IMPLEMENTED | COMPLETE |
| 22 | Download Queue integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 23 | Storage Manager integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 24 | Database integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 25 | Media Library integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 26 | File Manager integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 27 | Notification integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 28 | Background download | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 29 | Pause/resume | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 30 | Retry | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 31 | Cancel | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 32 | Duplicate detection | YES | MISSING (no pin identity) | IMPLEMENTED (`pinterest:pin:{id}`) | COMPLETE |
| 33 | File naming | YES | PARTIAL (generic) | IMPLEMENTED | COMPLETE |
| 34 | MIME type handling | YES | PARTIAL | IMPLEMENTED (JPG/PNG/WebP/GIF/MP4) | COMPLETE |
| 35 | Download verification | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 36 | Error handling | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 37 | Security validation | YES | IMPLEMENTED (generic) | IMPLEMENTED + Pinterest cases | COMPLETE |
| 38 | Offline behavior | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 39 | Performance | YES | N/A | IMPLEMENTED (URL-only resources) | COMPLETE |
| 40 | Multi-media state management | YES | MISSING | IMPLEMENTED (`discoverAll` + per-item tasks) | COMPLETE |

---

## Production Code Changes

### NEW `pinterest_resolver.dart`

- `PinterestResolver.discover` / `discoverAll`
- Parse `__PWS_DATA__` / `__PWS_INITIAL_PROPS__` / JSON-LD / OpenGraph
- Prefer `images.orig`; upgrade sized pinimg paths to `/originals/`
- Prefer highest progressive MP4; skip HLS (`.m3u8`)
- Idea Pins: `story_pin_data.pages` in order, mixed image/video MIME
- Direct CDN URLs, `pin.it` redirect, pidgets + oEmbed fallbacks
- `PinterestPinInfo` metadata mapping
- HLS-only / `is_video` without MP4 → empty (not a thumbnail download)

### `social_url_utils.dart` / `social_platform.dart`

- `PinterestUri` + `PinterestContentType`
- Hosts: `pinterest.com`, regional TLDs, `pin.it`, `pinimg.com`
- Normalize: strip tracking, drop slug, canonical `www.pinterest.com/pin/{id}/`
- `contentIdentity` for duplicate detection

### Wiring

- `PlatformSocialResolver` discover + discoverAll
- `ContentProviderRegistry` does **not** scrape home/board/profile HTML
- Export from `download_engine.dart`
- `MediaExtractor` Pinterest OG video + originals upgrade on fallback

---

## Platform Limitations

| Feature | Classification | Reason |
|---------|----------------|--------|
| Private / secret / login-walled pins | PLATFORM_LIMITATION | Auth bypass prohibited |
| HLS-only video (no progressive MP4) | PLATFORM_LIMITATION | Not a single downloadable file; no HLS converter required by docs |
| Board bulk download | NOT_REQUIRED | Board is a collection; empty result |
| Profile bulk download | NOT_REQUIRED | Profile is not a media item |
| Author persisted on DownloadTask | NOT_REQUIRED | Existing `DiscoveredResource` / `DownloadTask` have no author column |
| Separate video+audio mux | NOT_REQUIRED | Pinterest progressive MP4 is muxed; HLS (with separate audio) is skipped |

---

## Relevant Source Files

| File | Role |
|------|------|
| `pinterest_resolver.dart` | Resolver (NEW) |
| `social_url_utils.dart` | `PinterestUri` (MODIFIED) |
| `social_platform.dart` | Host detection (MODIFIED) |
| `platform_social_resolver.dart` | Registry wiring (MODIFIED) |
| `content_provider_registry.dart` | Non-downloadable skip (MODIFIED) |
| `media_extractor.dart` | OG fallback + originals upgrade (MODIFIED) |
| `download_engine.dart` | Export (MODIFIED) |
| `download_manager.dart` | Shared lifecycle |
| `filename_resolver.dart` | MIME → extension |

---

*Audit complete after implementation. See PINTEREST_TEST_REPORT.md for results.*
