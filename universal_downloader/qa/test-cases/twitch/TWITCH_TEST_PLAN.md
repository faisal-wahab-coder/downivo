# Twitch Integration Test Plan

**Platform:** Twitch (Channels, Live detection, VODs, Highlights, Clips)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition
2. Channel / VOD / Clip / Highlight classification
3. ID extraction (numeric VOD id; clip slug; channel login)
4. URL normalization and duplicate identity
5. Public GQL resolution for Clips (`gql.twitch.tv`)
6. Progressive MP4 quality listing (no fabricated 4K)
7. HLS skipped as a downloadable file
8. Live vs offline detection without auto-recording
9. Download state machine (shared engine)
10. Error handling and security
11. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → TwitchResolver
  ├── TwitchUri.classifyUrl()
  ├── TwitchUri.normalize() / videoIdFromUri() / clipIdFromUri()
  ├── POST gql.twitch.tv (public web Client-ID)
  ├── parseClipQualities() → best progressive MP4
  └── parseVideoInfo / parseChannelInfo (metadata only)
  ↓
DiscoveredResource → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, directory, channel, VOD HLS) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://www.twitch.tv/` | No |
| Channel | `https://www.twitch.tv/{login}` | No (live detect only) |
| VOD | `https://www.twitch.tv/videos/{id}` | Metadata yes; file no (HLS) |
| Highlight | same VOD URL, `broadcastType=HIGHLIGHT` | Metadata yes; file no (HLS) |
| Clip | `https://clips.twitch.tv/{slug}` | Yes, if public MP4 |
| Channel clip | `/{login}/clip/{slug}` | Yes (same identity) |
| Player | `player.twitch.tv/?clip=` / `?video=` / `?channel=` | Clip yes; others no |
| Directory / search | `/directory`, `/search` | No |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `twitch_url_test.dart` | 35 | Detection, classification, IDs, normalize, identity |
| `twitch_resolver_test.dart` | 12 | GQL discovery, registry, naming |
| `twitch_metadata_test.dart` | 10 | Title, creator, duration, thumbs, MIME |
| `twitch_vod_test.dart` | 6 | VOD id, HLS-only, quality labels |
| `twitch_clip_test.dart` | 6 | Best MP4, skip HLS, embed, restricted |
| `twitch_live_test.dart` | 5 | Live/offline, no recording |
| `twitch_quality_test.dart` | 7 | Actual qualities only; no 4K invent |
| `twitch_audio_video_test.dart` | 5 | Muxed MP4, no silent HLS substitute |
| `twitch_download_test.dart` | 11 | State machine, filename, identity |
| `twitch_error_test.dart` | 19 | HTTP 403–503, deleted/restricted |
| `twitch_security_test.dart` | 19 | Schemes, private IPs, filenames |
| `twitch_performance_test.dart` | 6 | Many qualities, identity loop |
| **Total Twitch** | **141** | |

---

## Manual tests (do not invent URLs)

Copy links directly from Twitch at test time. Store the exact URL next to the ID.

| ID | Intent |
|----|--------|
| TW-001 | Home `https://www.twitch.tv/` — no download |
| TW-002 | Public channel — live/offline, no channel download |
| TW-003 | Live channel — metadata only; no auto-record |
| TW-004 | Public VOD — detect + metadata; HLS file is limitation |
| TW-005 | Public Clip — download + playback |
| TW-006 | Long VOD — same HLS limitation; clip pause/resume uses engine |
| TW-007 | Mobile share Clip URL (P0) |
| TW-008 | Canonical vs share vs query params → same identity |
| TW-009 | Offline channel — no download |
| TW-010 | `https://www.twitch.tv/videos/INVALID` — clean error |

---

## Controlled fixtures (automated)

| ID | Fixture |
|----|---------|
| TW-QA-001 | Short clip MP4 (`twitchClipPayload`) |
| TW-QA-002 | VOD metadata (`twitchVideoPayload`) |
| TW-QA-003 | Muxed clip with audio |
| TW-QA-004 | Clip slug `AwkwardHelplessSalamanderSwiftRage` |
| TW-QA-005 | Live user payload |
| TW-QA-006 | Arabic title filename |
| TW-QA-007 | 400-char title truncated |
