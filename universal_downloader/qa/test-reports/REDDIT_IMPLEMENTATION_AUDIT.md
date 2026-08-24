# Reddit Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md` defines a generic Content Provider framework. Reddit is declared in `SocialPlatform` and already had a video-only JSON resolver. The architecture requires:

- Providers can download **images** and **videos**
- `canHandle`, `validate`, `discoverResources`, `extractMetadata`, `buildDownloadPlan`
- Graceful errors, filename sanitization, path-traversal prevention
- No bypass of authentication, DRM, or platform access controls
- Unit tests, mock responses, invalid URL tests, error-handling tests

Reddit-specific product docs do not exist by name. Required behavior follows the shared provider contract plus the existing Reddit resolver surface.

---

## Feature Audit

| # | Feature | Required? | Before | After | Status |
|---|---------|-----------|--------|-------|--------|
| 1 | Reddit URL detection | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 2 | Reddit URL parsing | YES | PARTIAL (`jsonEndpoint` only) | IMPLEMENTED | COMPLETE |
| 3 | Reddit URL normalization | YES | MISSING | IMPLEMENTED | COMPLETE |
| 4 | Reddit platform identification | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 5 | Post detection | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 6 | Subreddit detection | YES (reject bulk) | MISSING | IMPLEMENTED | COMPLETE — not a download |
| 7 | Video detection | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 8 | Image detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 9 | GIF detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 10 | Gallery detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 11 | Multiple-media detection | YES | MISSING (`discoverAll` unwired) | IMPLEMENTED | COMPLETE |
| 12 | Audio detection | YES (identify) | MISSING | IMPLEMENTED | COMPLETE — stream identified |
| 13 | Direct media URL detection | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 14 | Short/share URL handling | YES | BROKEN (`redd.it` JSON null) | IMPLEMENTED | COMPLETE |
| 15 | Post ID extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 16 | Subreddit extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 17 | Author extraction | YES (metadata) | MISSING | IMPLEMENTED | COMPLETE (`RedditPostInfo`) |
| 18 | Metadata extraction | YES | PARTIAL (title only) | IMPLEMENTED | COMPLETE |
| 19 | Thumbnail extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 20 | Media URL extraction | YES | PARTIAL (video only) | IMPLEMENTED | COMPLETE |
| 21 | Download Engine integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
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
| 32 | Duplicate detection | YES | PARTIAL | IMPLEMENTED | COMPLETE (`reddit:post:<id>`) |
| 33 | File naming | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 34 | MIME type handling | YES | BROKEN (always `video/mp4`) | IMPLEMENTED | COMPLETE |
| 35 | Download verification | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 36 | Error handling | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 37 | Security validation | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE |
| 38 | Offline behavior | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 39 | Performance | YES | N/A | IMPLEMENTED | COMPLETE (gallery parse, no full-res preload) |
| 40 | Multi-media state management | YES | MISSING | IMPLEMENTED | COMPLETE (independent items) |

---

## Production Code Changes

| File | Change |
|------|--------|
| `social_url_utils.dart` | Full `RedditUri`: classify, post ID, subreddit, normalize, jsonEndpoint, contentIdentity, `RedditContentType` |
| `reddit_resolver.dart` | Images, GIFs, galleries, mixed MIME, direct media, share redirects, metadata, audio-stream identification |
| `platform_social_resolver.dart` | Wired `discoverAll` to `RedditResolver` |
| `content_provider_registry.dart` | Skip HTML scrape for non-downloadable Reddit pages (home/subreddit/user) |
| `media_extractor.dart` | Reddit HTML fallback for images + DASH MP4; ignore HLS/DASH playlists |
| `filename_resolver.dart` | Map `image/jpg` → `.jpg` |

---

## Documented Limitations

| Feature | Classification | Reason |
|---------|----------------|--------|
| Muxed video+audio file | **PLATFORM_LIMITATION** | Reddit hosts DASH video and audio separately. No ffmpeg/muxer exists (same as YouTube). Audio URL is identified via `audioStreamUrlFromVideo`. GIF-like `is_gif` videos correctly have no audio. |
| HLS/DASH playlist download | **NOT_REQUIRED** | Playlists are not playable files. Resolver uses `fallback_url` MP4 only. |
| Subreddit bulk download | **NOT_REQUIRED** | Docs do not require crawling `/r/<sub>/`. Classified as SUBREDDIT; no download created. |
| Home / search / profile | **EXPECTED BEHAVIOR** | Not media. No download. |
| Private / quarantined / login-walled posts | **PLATFORM_LIMITATION** | Must not bypass authentication or access controls. Returns empty + user-facing HTTP error. |
| Comment text download | **NOT_REQUIRED** | Comment URLs resolve parent post media only. |
| Live Reddit posts in unit tests | **EXPECTED BEHAVIOR** | Unit tests use fixtures. Live URLs are env-gated (`SOCIAL_LIVE_TEST=1`) and manual. |

---

## Relevant Source Files

| File | Role |
|------|------|
| `reddit_resolver.dart` | Resolver (MODIFIED) |
| `social_url_utils.dart` | `RedditUri` (MODIFIED) |
| `platform_social_resolver.dart` | Platform router (MODIFIED) |
| `content_provider_registry.dart` | Registry (MODIFIED) |
| `media_extractor.dart` | HTML fallback (MODIFIED) |
| `social_platform.dart` | Host detection |
| `download_manager.dart` | Shared download lifecycle |

---

*Audit complete. Implementation and tests follow.*
