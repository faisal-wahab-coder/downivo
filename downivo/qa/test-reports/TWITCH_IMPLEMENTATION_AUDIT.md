# Twitch Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

Twitch is not named in `docs/`, but the Content Provider Architecture (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) requires every provider to:

- Recognize supported URLs
- Discover downloadable resources where permitted
- Extract metadata (title, filename, MIME, thumbnail, author)
- Provide download instructions to the existing Download Engine
- Handle errors without crashing
- Sanitize filenames and prevent path traversal
- Never bypass authentication, DRM, paywalls, or platform ToS
- Ship unit tests, mock responses, invalid URL tests, and error tests

Video is a first-class storage category. Live-stream recording is **not** required by `docs/12_System_Design/12.11_Download_State_Machine.md` (CREATED → QUEUED → STARTING → DOWNLOADING → VERIFYING → COMPLETED). Home, directory, channel listing, and search URLs are **not** a single downloadable item.

The existing Download Engine already covers queue, pause/resume, retry, cancel, verification, storage, database, media library, file manager, notifications, and background downloads. Twitch must not introduce a platform-specific downloader. HLS/DASH conversion is not required by docs (same policy as Vimeo, Pinterest, SoundCloud).

---

## Feature Audit

| # | Feature | Required? | Before | After | Status |
|---|---------|-----------|--------|-------|--------|
| 1 | Twitch URL detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 2 | Twitch URL parsing | YES | MISSING | IMPLEMENTED (`TwitchUri`) | COMPLETE |
| 3 | Twitch URL normalization | YES | MISSING | IMPLEMENTED | COMPLETE |
| 4 | Twitch platform identification | YES | MISSING | IMPLEMENTED (`SocialPlatform.twitch`) | COMPLETE |
| 5 | Channel detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 6 | Live stream detection | YES | MISSING | IMPLEMENTED (`parseChannelInfo`) | COMPLETE |
| 7 | VOD detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 8 | Clip detection | YES | MISSING | IMPLEMENTED | COMPLETE |
| 9 | Highlight detection | YES | MISSING | IMPLEMENTED (`broadcastType`) | COMPLETE |
| 10 | Video ID extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 11 | Channel ID extraction | YES | MISSING | IMPLEMENTED when GQL provides it | COMPLETE |
| 12 | Streamer/creator extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 13 | Title extraction | YES | MISSING | IMPLEMENTED (not fabricated) | COMPLETE |
| 14 | Description extraction | YES | MISSING | IMPLEMENTED when present | COMPLETE |
| 15 | Category/game extraction | YES | MISSING | IMPLEMENTED when present | COMPLETE |
| 16 | Thumbnail extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 17 | Duration extraction | YES | MISSING | IMPLEMENTED | COMPLETE |
| 18 | Published date | YES | MISSING | IMPLEMENTED when present | COMPLETE |
| 19 | Live status | YES | MISSING | IMPLEMENTED | COMPLETE |
| 20 | Video resolution | YES | MISSING | IMPLEMENTED from clip quality labels | COMPLETE |
| 21 | Available quality detection | YES | MISSING | IMPLEMENTED (clip MP4; HLS labels parsed, not downloaded) | COMPLETE |
| 22 | Audio detection | YES | MISSING | IMPLEMENTED (muxed clip MP4) | COMPLETE |
| 23 | Audio/video stream detection | YES | MISSING | IMPLEMENTED (clip MP4 muxed; HLS skipped) | COMPLETE |
| 24 | HLS handling | YES (no bypass converter) | MISSING | PLATFORM_LIMITATION (skipped as file) | PLATFORM_LIMITATION |
| 25 | VOD handling | YES (metadata); file = HLS | MISSING | Metadata IMPLEMENTED; file PLATFORM_LIMITATION | PLATFORM_LIMITATION |
| 26 | Clip handling | YES | MISSING | IMPLEMENTED (progressive MP4) | COMPLETE |
| 27 | Live-stream handling | Detect YES; record NO | MISSING | Detection IMPLEMENTED; recording NOT_REQUIRED | COMPLETE / NOT_REQUIRED |
| 28 | Download Engine integration | YES | IMPLEMENTED (shared) | IMPLEMENTED | COMPLETE |
| 29 | Download Queue integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 30 | Storage Manager integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 31 | Database integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 32 | Media Library integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 33 | File Manager integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 34 | Notification integration | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 35 | Background download | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 36 | Pause/resume | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 37 | Retry | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 38 | Cancel | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 39 | Duplicate detection | YES | MISSING | IMPLEMENTED (`twitch:clip:{slug}` / `twitch:video:{id}`) | COMPLETE |
| 40 | File naming | YES | MISSING | IMPLEMENTED (sanitize + quality suffix) | COMPLETE |
| 41 | MIME type handling | YES | MISSING | IMPLEMENTED (`video/mp4`) | COMPLETE |
| 42 | Download verification | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 43 | Error handling | YES | PARTIAL | IMPLEMENTED | COMPLETE |
| 44 | Security validation | YES | IMPLEMENTED (generic) | IMPLEMENTED + Twitch cases | COMPLETE |
| 45 | Offline behavior | YES | IMPLEMENTED | IMPLEMENTED | COMPLETE (shared) |
| 46 | Performance | YES | N/A | IMPLEMENTED (URL-only resources) | COMPLETE |
| 47 | Large-file handling | YES | IMPLEMENTED (streaming engine) | IMPLEMENTED | COMPLETE (shared) |

---

## Production Code Changes

### NEW `twitch_resolver.dart`

- `TwitchResolver.discover` / `discoverAll`
- Public GQL (`gql.twitch.tv`) using the website Client-ID (not a user secret)
- Clip `videoQualities` → progressive MP4; highest height by default
- Playback token appended as `sig` / `token` query params
- Reject forbidden tokens, missing clips, HLS-only clip lists
- `parseVideoInfo` / `parseChannelInfo` / `parseHlsMaster` for metadata and quality labels
- Live channels are classified; recording is not started

### `social_url_utils.dart` / `social_platform.dart`

- `SocialPlatform.twitch` for `twitch.tv`, `clips.twitch.tv`, `player.twitch.tv`, mobile hosts
- `TwitchUri` classification, ID extraction, canonical identity
- Fetch targets include normalized clip/VOD/channel URLs

### Wiring

- `PlatformSocialResolver`, `ContentProviderRegistry` (no home/directory HTML scrape)
- `SocialHttpHeaders` origin
- `MediaExtractor` accepts clip CDN MP4 only; ignores HLS and `twitch.tv` page URLs
- `DownloadManager` user-facing errors for home / channel / VOD / clip

---

## Platform Limitations

| Feature | Classification | Reason |
|---------|----------------|--------|
| VOD file download | PLATFORM_LIMITATION | Twitch VODs are HLS-only; no documented converter (same as Vimeo/SoundCloud/Pinterest) |
| Highlight file download | PLATFORM_LIMITATION | Same HLS delivery as VOD |
| Live-stream recording | NOT_REQUIRED | Docs do not require RECORDING states or live capture |
| Subscriber-only / forbidden token | PLATFORM_LIMITATION | Auth / entitlement bypass prohibited |
| Deleted / unavailable Clip or VOD | EXPECTED BEHAVIOR | Clear empty result / user error |
| Offline channel download | NOT_REQUIRED | Channel is not a media file |
| Fabricated 4K when source is 1080p | NOT_REQUIRED | Must not upscale or invent quality |
| DRM / encrypted streams | PLATFORM_LIMITATION | DRM bypass prohibited |

---

## Relevant Source Files

| File | Role |
|------|------|
| `twitch_resolver.dart` | Resolver (NEW) |
| `social_url_utils.dart` | `TwitchUri` (MODIFIED) |
| `social_platform.dart` | Host detection (MODIFIED) |
| `platform_social_resolver.dart` | Registry wiring |
| `content_provider_registry.dart` | Skip non-downloadable pages |
| `media_extractor.dart` | Direct MP4 fallback only |
| `download_manager.dart` | Twitch error messages |
| `filename_resolver.dart` | Sanitize + MIME → extension |

---

*Audit complete after implementation. See TWITCH_TEST_REPORT.md for results.*
