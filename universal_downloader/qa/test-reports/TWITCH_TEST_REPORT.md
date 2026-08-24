# Twitch Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

Twitch support is **implemented and tested** in the UniversalDownloader download engine. Before this phase Twitch was **not a platform**: `SocialPlatform.fromUri` returned null for `twitch.tv`, there was no resolver, and no Clip/VOD/channel classification.

This phase added `SocialPlatform.twitch`, `TwitchUri` (channel / VOD / clip / highlight classification, canonical identity), `TwitchResolver` (public GQL → progressive Clip MP4), live/offline metadata, VOD/Highlight metadata, HLS quality-label parsing without downloading playlists, registry wiring, and security/error coverage.

Twitch uses the **existing Download Engine**. There is no Twitch-specific downloader.

**Twitch: 141 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 1481 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, and Vimeo tests were included in that suite and did not regress.

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| Channel / VOD / Clip / Highlight classification | COMPLETE |
| Clip slug / VOD id / channel login | COMPLETE |
| Share / tracking / mobile / player URLs | COMPLETE |
| Clip metadata (title, creator, channel, category, duration, thumb) | COMPLETE |
| Clip quality listing (actual progressive MP4 only) | COMPLETE |
| Default download = highest clip MP4 | COMPLETE |
| MP4 MIME / extension | COMPLETE |
| Live / offline detection | COMPLETE |
| Live recording | **NOT_REQUIRED** (docs do not require it) |
| VOD / Highlight metadata | COMPLETE |
| VOD / Highlight file download | **PLATFORM_LIMITATION** (HLS-only) |
| Download Engine / queue / storage / DB / library | COMPLETE (shared) |
| Pause / resume / retry / cancel / verify | COMPLETE (shared) |
| Home / directory / channel listing | COMPLETE — correctly non-downloadable |
| Subscriber-only / forbidden token | **PLATFORM_LIMITATION** |

### New / modified production files

| File | Purpose |
|------|---------|
| `twitch_resolver.dart` | NEW resolver: GQL, clip MP4, VOD/live metadata, restrictions |
| `social_url_utils.dart` | `TwitchUri` + `TwitchContentType` |
| `social_platform.dart` | `twitch` + `isTwitchHost` |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Twitch |
| `content_provider_registry.dart` | No homepage HTML scrape |
| `media_extractor.dart` | Direct MP4 only; ignore HLS and twitch.tv pages |
| `social_http_headers.dart` | Twitch origin |
| `download_manager.dart` | Twitch-specific user errors |
| `download_engine.dart` | Export resolver |

---

## Test Results

### Twitch automated tests (141)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| twitch_url_test | 35 | 35 | 0 | 0 |
| twitch_resolver_test | 12 | 12 | 0 | 0 |
| twitch_metadata_test | 10 | 10 | 0 | 0 |
| twitch_vod_test | 6 | 6 | 0 | 0 |
| twitch_clip_test | 6 | 6 | 0 | 0 |
| twitch_live_test | 5 | 5 | 0 | 0 |
| twitch_quality_test | 7 | 7 | 0 | 0 |
| twitch_audio_video_test | 5 | 5 | 0 | 0 |
| twitch_download_test | 11 | 11 | 0 | 0 |
| twitch_error_test | 19 | 19 | 0 | 0 |
| twitch_security_test | 19 | 19 | 0 | 0 |
| twitch_performance_test | 6 | 6 | 0 | 0 |
| **Total Twitch** | **141** | **141** | **0** | **0** |

### Full regression

| Platform / area | Status |
|-----------------|--------|
| YouTube | PASS (no regression) |
| TikTok | PASS (no regression) |
| Instagram | PASS (no regression) |
| Facebook | PASS (no regression) |
| SoundCloud | PASS (no regression) |
| Reddit | PASS (no regression) |
| Pinterest | PASS (no regression) |
| Vimeo | PASS (no regression) |
| Twitch | PASS (new) |
| Download engine / storage / security / filename | PASS |

**1481 passed, 0 failed, 26 skipped** (`flutter test` in `packages/download_engine`).

Skipped tests are pre-existing (not Twitch). None were skipped to hide failures.

---

## Manual tests required

Do **not** invent Twitch URLs. Copy from the Twitch app/site at test time.

| ID | Intent | Status |
|----|--------|--------|
| TW-001 | Home — platform TWITCH, content HOME, no download | DEFINED (device) |
| TW-002 | Public channel — live/offline, no channel download | DEFINED (device) |
| TW-003 | Live channel — metadata; no auto-record | DEFINED (device) |
| TW-004 | Public VOD — detect + metadata; HLS file limitation | DEFINED (device) |
| TW-005 | Public Clip — download, verify, playback, library | DEFINED (device) |
| TW-006 | Long VOD — HLS limitation; clip pause/resume via engine | DEFINED (device) |
| TW-007 | Mobile share Clip URL (P0) | DEFINED (device) |
| TW-008 | Canonical vs share vs query → same identity | DEFINED (device) |
| TW-009 | Offline channel — no download | DEFINED (device) |
| TW-010 | `/videos/INVALID` — clean error | DEFINED (device) |

Store exact copied URLs next to the ID when executing. Automated fixtures cover the same logic without live network.

---

## Failures

None in automated suites.

---

## Classifications

| Item | Classification | Notes |
|------|----------------|-------|
| Public Clip MP4 download | COMPLETE | GQL `videoQualities` + signed URL |
| VOD / Highlight file download | PLATFORM_LIMITATION | HLS-only; no converter in this engine |
| Live recording | NOT_REQUIRED | Docs do not define RECORDING states |
| Subscriber-only / forbidden token | PLATFORM_LIMITATION | Entitlement bypass prohibited |
| Deleted Clip / VOD | EXPECTED BEHAVIOR | Empty result + user error |
| Offline / live channel page | EXPECTED BEHAVIOR | Not a media file |
| javascript: / file: / localhost | EXPECTED BEHAVIOR | Rejected by UrlValidator / host check |

---

## Completion rule

| Criterion | Clip | VOD file | Live record |
|-----------|------|----------|-------------|
| Implementation exists | YES | Metadata only | Detection only |
| Unit tests pass | YES | YES | YES |
| Integration tests pass | YES | YES (empty discover) | YES (empty discover) |
| Manual test defined | YES | YES | YES |
| Error handling | YES | YES | YES |
| Storage / DB / library / playback | YES (shared engine, Clip MP4) | N/A (no file) | N/A (no file) |
| Regression | YES | YES | YES |

Clip download workflow is **COMPLETE**. VOD/Highlight **files** and live **recording** are documented limitations, not silent gaps.

---

*Do not bypass authentication, privacy controls, DRM, or platform security.*
