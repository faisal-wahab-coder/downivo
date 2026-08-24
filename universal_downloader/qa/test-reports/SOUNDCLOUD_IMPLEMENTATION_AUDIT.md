# SoundCloud Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

SoundCloud is not named in `docs/`, but it is a declared `SocialPlatform` and the Content Provider Architecture (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) requires every provider to:

- Recognize supported URLs
- Discover downloadable resources where permitted
- Extract metadata (title, filename, MIME, thumbnail, author)
- Provide download instructions to the existing Download Engine
- Handle errors without crashing
- Sanitize filenames and prevent path traversal
- Never bypass authentication, DRM, paywalls, or platform ToS
- Ship unit tests, mock responses, invalid URL tests, and error tests

Audio is a first-class storage category (`docs/14_Storage_Management.md`, `docs/13.4_Local_Storage_Schema.md`). Playlist-style multi-resource discovery is an optional provider capability (`supportsPlaylists` in 11.5 §12) and is implemented for public SoundCloud sets.

---

## Feature Audit

| # | Feature | Required? | Before | After | Status |
|---|---------|-----------|--------|-------|--------|
| 1 | SoundCloud URL detection | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 2 | SoundCloud URL parsing | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 3 | URL normalization | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 4 | Track detection | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 5 | Playlist/set detection | YES | PARTIAL (`/sets` without slug) | IMPLEMENTED | COMPLETE |
| 6 | Album/set detection | YES | PARTIAL (same `/sets/` path) | IMPLEMENTED | COMPLETE |
| 7 | Artist/profile detection | YES (reject download) | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 8 | Track ID / slug extraction | YES | IMPLEMENTED (slug) | IMPLEMENTED | COMPLETE |
| 9 | Playlist ID / slug extraction | YES | IMPLEMENTED (slug) | IMPLEMENTED | COMPLETE |
| 10 | Username extraction | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 11 | Metadata extraction | YES | PARTIAL (title only) | IMPLEMENTED | COMPLETE |
| 12 | Artwork extraction | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 13 | Duration extraction | OPTIONAL | MISSING | NOT stored on `DiscoveredResource` | NOT_REQUIRED (existing model) |
| 14 | Audio URL resolution | YES | **BROKEN** (API JSON URL) | **IMPLEMENTED** | COMPLETE |
| 15 | Audio format detection | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 16 | Bitrate detection | OPTIONAL | MISSING | NOT_REQUIRED | SoundCloud progressive often omits bitrate |
| 17 | Download Engine integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 18 | Download Queue integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 19 | Storage integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (audio category) |
| 20 | Database integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 21 | Media Library integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 22 | File Manager integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 23 | Notification integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 24 | Background download | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 25 | Pause/resume | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 26 | Retry | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 27 | Cancel | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 28 | Duplicate detection | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (canonical identity) |
| 29 | File naming | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 30 | MIME type handling | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 31 | Metadata embedding (ID3) | NO | N/A | N/A | NOT_REQUIRED (no existing embedder) |
| 32 | Error handling | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 33 | Security validation | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 34 | Offline handling | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 35 | Performance | YES | PARTIAL | IMPLEMENTED | COMPLETE (URL-only resources) |

---

## Production Code Changes

### `soundcloud_resolver.dart`

- Resolve progressive transcoding API URLs to CDN audio files (`{ "url": "https://cf-media.sndcdn.com/....mp3" }`).
- Prefer artist-enabled `download_url` when `downloadable == true`.
- Reject HLS-only / SNIP / BLOCK / private tracks (no DRM or preview bypass).
- Hydrate playlist stub tracks via the public `api-v2` tracks endpoint used by the website.
- Skip unavailable playlist items so one failure does not fail the set.
- Attach SoundCloud download headers; upgrade artwork to `t500x500` with avatar fallback.

### `social_url_utils.dart` / `social_platform.dart`

- Classify `/artist/sets` (no slug) and `/sets/...` as non-content.
- Detect `on.soundcloud.com` short links; do not rewrite them (redirect required).
- Preserve `secret_token`; strip `fbclid` / `gclid` / `igshid`.
- Canonical content identity for tracks, playlists, profiles, and short codes.

---

## Platform Limitations

| Feature | Classification | Reason |
|---------|----------------|--------|
| Private / secret tracks without a user-supplied token | PLATFORM_LIMITATION | Auth bypass prohibited |
| Go+ SNIP / preview-only | PLATFORM_LIMITATION | DRM / paid preview; not the full track |
| HLS-only streams | PLATFORM_LIMITATION | Not a single downloadable file; no converter required by docs |
| Profile / likes / followers bulk download | NOT_REQUIRED | Profile is not a media item; rejected with empty result |
| ID3/artwork embedding into the file | NOT_REQUIRED | Application has no existing embedder |
| Play counts / likes | NOT_REQUIRED | Unstable; not in the metadata model |

---

## Relevant Source Files

| File | Role |
|------|------|
| `soundcloud_resolver.dart` | Resolver (MODIFIED) |
| `social_url_utils.dart` | `SoundCloudUri` (MODIFIED) |
| `social_platform.dart` | Host detection (MODIFIED) |
| `platform_social_resolver.dart` | Registry wiring |
| `media_extractor.dart` | Filename + og:audio fallback |
| `download_manager.dart` | Shared lifecycle / audio storage category |
| `filename_resolver.dart` | MIME → extension |

---

*Audit complete after implementation. See SOUNDCLOUD_TEST_REPORT.md for results.*
