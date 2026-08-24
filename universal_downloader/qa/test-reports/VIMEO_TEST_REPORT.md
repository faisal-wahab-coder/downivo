# Vimeo Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

Vimeo support is **implemented and tested** in the UniversalDownloader download engine. Before this phase Vimeo was **not a platform**: `SocialPlatform.fromUri` returned null for `vimeo.com`, there was no resolver, and YouTube URL tests used Vimeo as a negative example.

This phase added `SocialPlatform.vimeo`, `VimeoUri` (ID extraction, player/share/unlisted hash, canonical identity), `VimeoResolver` (official player config → progressive MP4), quality listing without fabricated 4K, HTML `playerConfig` fallback, registry wiring, and security/error coverage.

Vimeo uses the **existing Download Engine**. There is no Vimeo-specific downloader.

**Vimeo: 144 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 1340 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, and Pinterest tests were included in that suite and did not regress.

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| Video ID as primary identity | COMPLETE |
| Player URL (`player.vimeo.com/video/{id}`) | COMPLETE — same identity |
| Share / tracking / unlisted `h=` hash | COMPLETE |
| Metadata (title, author, duration, thumbs, dimensions, fps) | COMPLETE |
| Quality listing (actual progressive only) | COMPLETE |
| Default download = highest progressive MP4 | COMPLETE |
| MP4 MIME / extension | COMPLETE |
| Download Engine / queue / storage / DB / library | COMPLETE (shared) |
| Pause / resume / retry / cancel / verify | COMPLETE (shared) |
| Home / profile / channel listing | COMPLETE — correctly non-downloadable |
| HLS-only / DASH-only | **PLATFORM_LIMITATION** |
| Password / private / DRM / On Demand | **PLATFORM_LIMITATION** |

### New / modified production files

| File | Purpose |
|------|---------|
| `vimeo_resolver.dart` | NEW resolver: player config, qualities, restrictions |
| `social_url_utils.dart` | `VimeoUri` + `VimeoContentType` |
| `social_platform.dart` | `vimeo` + `isVimeoHost` |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Vimeo |
| `content_provider_registry.dart` | No homepage HTML scrape |
| `media_extractor.dart` | Direct MP4 only; ignore player embed OG |
| `social_http_headers.dart` | Vimeo origin |
| `download_engine.dart` | Export resolver |
| `youtube_url_test.dart` | Negative host is `example.com` (Vimeo is now valid) |

---

## Test Results

### Vimeo automated tests (144)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| vimeo_url_test | 47 | 47 | 0 | 0 |
| vimeo_resolver_test | 13 | 13 | 0 | 0 |
| vimeo_metadata_test | 10 | 10 | 0 | 0 |
| vimeo_video_test | 6 | 6 | 0 | 0 |
| vimeo_quality_test | 7 | 7 | 0 | 0 |
| vimeo_audio_video_test | 5 | 5 | 0 | 0 |
| vimeo_download_test | 11 | 11 | 0 | 0 |
| vimeo_error_test | 21 | 21 | 0 | 0 |
| vimeo_security_test | 19 | 19 | 0 | 0 |
| vimeo_performance_test | 5 | 5 | 0 | 0 |
| **Total Vimeo** | **144** | **144** | **0** | **0** |

### Full regression

| Platform / area | Status |
|-----------------|--------|
| YouTube | PASS |
| TikTok | PASS |
| Instagram | PASS |
| Facebook | PASS |
| SoundCloud | PASS |
| Reddit | PASS |
| Pinterest | PASS |
| Vimeo | PASS |
| Download Engine / storage / filename / security | PASS |
| **Package total** | **1340 passed, 26 skipped, 0 failed** |

Skipped tests are existing live-network gates (`SOCIAL_LIVE_TEST=1` and similar), not Vimeo failures.

---

## Manual tests required

Do **not** invent Vimeo video IDs. Copy public URLs from Vimeo.

| ID | Case | Status |
|----|------|--------|
| VM-001 | `https://vimeo.com/` → HOME, no download | DEFINED (P0) |
| VM-002 | Public video — Share → Copy link | DEFINED — needs real URL |
| VM-003 | Second public video (different aspect/duration) | DEFINED — needs real URL |
| VM-004 | High-resolution only if actually offered | DEFINED |
| VM-005 | Video with audio — playback + sync | DEFINED |
| VM-006 | Player URL same identity as VM-002 | DEFINED |
| VM-007 | Mobile share URL | DEFINED (P0) |
| VM-008 | Canonical + player + query variants | DEFINED |
| VM-009 | `https://vimeo.com/INVALID` | DEFINED |
| VM-010 | Unavailable/restricted (no bypass) | DEFINED |

Device/background/storage-full checks (Phases 14–18, 21–23) use the shared Download Engine; they remain device-level manual verification.

---

## Failures

None in automated tests.

One production bug was found and **fixed during this phase**:

| Test ID | URL | Expected | Actual (before fix) | Root cause | Component | Severity | Classification | Fix |
|---------|-----|----------|---------------------|------------|-----------|----------|----------------|-----|
| VM-VID-005 | `og:video` = `player.vimeo.com/video/{id}` | Not a downloadable file | MediaExtractor treated embed URL as media | Generic OG fallback after Vimeo-specific extractor | `media_extractor.dart` | Medium | PRODUCTION BUG | Skip OG video/image fallback for Vimeo; only accept direct MP4 |

---

## Platform limitations (not failures)

| Item | Classification | Reason |
|----------------------|--------|
| HLS-only / DASH-only videos | PLATFORM_LIMITATION | No documented converter; same policy as SoundCloud/Pinterest |
| Password-protected | PLATFORM_LIMITATION | Auth bypass prohibited |
| Private videos | PLATFORM_LIMITATION | Privacy controls |
| Unlisted without user-supplied hash | PLATFORM_LIMITATION | Access token required |
| DRM / encrypted | PLATFORM_LIMITATION | DRM bypass prohibited |
| Vimeo On Demand | PLATFORM_LIMITATION | Paywall |
| Profile / channel / showcase bulk | NOT_REQUIRED / EXPECTED BEHAVIOR | Collection, not a media item |
| Quality picker UI | PARTIALLY_SUPPORTED | Resolver lists actual qualities and defaults to best; shared wizard still downloads a single resource (same as YouTube/Facebook) |

---

## Architecture (verified)

```
Vimeo Adapter (VimeoResolver)
  → player.vimeo.com/video/{id}/config
  → Media Resource (progressive MP4)
  → Download Engine
  → Download Queue
  → Storage Manager
  → Database
  → Media Library
```

Canonical identity: `vimeo:video:{id}` for `vimeo.com/{id}`, `player.vimeo.com/video/{id}`, share URLs, and tracking-parameter variants.

---

## How to re-run

```bash
cd universal_downloader/packages/download_engine
flutter test test/vimeo_url_test.dart test/vimeo_resolver_test.dart \
  test/vimeo_metadata_test.dart test/vimeo_video_test.dart \
  test/vimeo_quality_test.dart test/vimeo_audio_video_test.dart \
  test/vimeo_download_test.dart test/vimeo_error_test.dart \
  test/vimeo_security_test.dart test/vimeo_performance_test.dart
flutter test
```
