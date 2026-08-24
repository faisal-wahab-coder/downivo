# Snapchat Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

Snapchat support is **implemented and tested** in the UniversalDownloader download engine. Public `snapchat.com` / `t.snapchat.com` / `story.snapchat.com` / `snapchat://` / CDN URLs are classified, normalized, and resolved through `SnapchatResolver` into the **existing Download Engine**. There is no Snapchat-specific downloader.

Private chat/Memories, friends-only HTML, login walls, expired Snaps, and HLS-only streams are classified and **not** bypassed. Restricted, authentication-required, expired, and HLS-only failures are **not retried**.

**Snapchat: 157 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 1937 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn, and Telegram tests were included in that suite and did not regress. Dailymotion is not present in this codebase (no adapter, tests, or docs requirement).

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| Profile / Spotlight / Story / Saved Story / Snap / share / embed / `snapchat://` | COMPLETE |
| Content ID / username / share code | COMPLETE |
| Share / tracking / embed URLs | COMPLETE |
| Photo / video when a public CDN URL is exposed | COMPLETE |
| Multi-snap Story count / order / dedupe | COMPLETE |
| Profile / home / feed download | **NOT_REQUIRED** (classified, not downloaded) |
| Download Engine / queue / storage / DB / library | COMPLETE (shared) |
| Pause / resume / retry / cancel / verify | COMPLETE (shared) |
| Restricted / auth-wall content | **RESTRICTED_CONTENT** / **AUTHENTICATION_REQUIRED** |
| Expired / disappeared Snap | **CONTENT_EXPIRED** |
| HLS-only Spotlight / Story | **PLATFORM_LIMITATION** |

### Production files

| File | Purpose |
|------|---------|
| `snapchat_resolver.dart` | Public HTML → media; auth/restricted/expired/HLS errors |
| `social_url_utils.dart` | `SnapchatUri` + `SnapchatContentType` |
| `social_platform.dart` | `snapchat.com`, `t.snapchat.com`, `sc-cdn.net`, `snapchat://` |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Snapchat |
| `content_provider_registry.dart` | No homepage/profile HTML scrape |
| `media_extractor.dart` | Direct Snapchat CDN only; skip HLS |
| `download_manager.dart` | Snapchat user errors; no retry for permanent failures |
| `download_repository.dart` | Public `snapchat://` → `https://www.snapchat.com` |
| `download_engine.dart` | Export resolver |

---

## Test Results

### Snapchat automated tests (157)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| snapchat_url_test | 40 | 40 | 0 | 0 |
| snapchat_resolver_test | 10 | 10 | 0 | 0 |
| snapchat_profile_test | 5 | 5 | 0 | 0 |
| snapchat_spotlight_test | 6 | 6 | 0 | 0 |
| snapchat_story_test | 6 | 6 | 0 | 0 |
| snapchat_photo_test | 5 | 5 | 0 | 0 |
| snapchat_video_test | 6 | 6 | 0 | 0 |
| snapchat_metadata_test | 5 | 5 | 0 | 0 |
| snapchat_download_test | 10 | 10 | 0 | 0 |
| snapchat_auth_test | 7 | 7 | 0 | 0 |
| snapchat_restriction_test | 6 | 6 | 0 | 0 |
| snapchat_expiration_test | 4 | 4 | 0 | 0 |
| snapchat_error_test | 21 | 21 | 0 | 0 |
| snapchat_security_test | 21 | 21 | 0 | 0 |
| snapchat_performance_test | 5 | 5 | 0 | 0 |
| **Total Snapchat** | **157** | **157** | **0** | **0** |

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
| Twitch | PASS (no regression) |
| LinkedIn | PASS (no regression) |
| Telegram | PASS (no regression) |
| Snapchat | PASS |
| Dailymotion | N/A (not in this repository) |
| Download engine / storage / security / filename | PASS |

**1937 passed, 0 failed, 26 skipped** (`flutter test` in `packages/download_engine`).

Skipped tests are pre-existing (not Snapchat). None were skipped to hide failures.

---

## Manual tests required

Do **not** invent Snapchat content IDs. Copy public URLs from Snapchat at test time.

| ID | Intent | Status |
|----|--------|--------|
| SC-001 | Home `https://www.snapchat.com/` — SNAPCHAT / HOME, no download | DEFINED (device) |
| SC-002 | Public profile — PUBLIC_PROFILE, metadata, no auto-download | DEFINED (device) |
| SC-003 | Public Spotlight video — detect, metadata, download, playback | DEFINED (device) |
| SC-004 | Public photo — detect, download, library | DEFINED (device); mark MANUAL TEST BLOCKED if no stable public photo URL exists |
| SC-005 | Public Story — detect, snap count, download | DEFINED (device) |
| SC-006 | Multi-snap Story — count, order, individual items | DEFINED (device) |
| SC-007 | Mobile share Copy Link (P0) | DEFINED (device) |
| SC-008 | Spotlight playback — play / pause / seek / audio sync | DEFINED (device) |
| SC-009 | Large public video — pause / resume / background | DEFINED (device) |
| SC-010 | Expired content — CONTENT_EXPIRED | DEFINED (device) |
| SC-011 | Private content — RESTRICTED_CONTENT | DEFINED (device) |
| SC-012 | Authentication required — AUTHENTICATION_REQUIRED | DEFINED (device) |
| SC-013 | `https://www.snapchat.com/p/INVALID` — invalid profile, no download | DEFINED (device) |
| SC-014 | Invalid Spotlight — CONTENT_UNAVAILABLE | DEFINED (device) |
| SC-015 | `https://www.snapchat.com/INVALID` — INVALID_URL | DEFINED (device) |

Store exact copied URLs next to the ID when executing:

```
SC-003
<REAL SNAPCHAT PUBLIC SPOTLIGHT URL>
```

Automated fixtures cover the same logic without live network.

### Controlled QA content (optional)

If you control a public Snapchat profile, label posts SC-QA-001…008 (photo, short video, long video, Story, multi-snap Story, Spotlight, Unicode caption, long caption) for repeatable device regression.

---

## Failures

None in automated suites.

---

## Classifications

| Item | Classification | Notes |
|------|----------------|-------|
| Public Spotlight MP4 | COMPLETE | Highest exposed public CDN URL |
| Public photo Snap | COMPLETE | JPEG/PNG/WebP when exposed |
| Public Story / Saved Story | COMPLETE | Order preserved, URL-only |
| Share / embed / tracking URLs | COMPLETE | Same canonical identity |
| Profile / home / feed file download | EXPECTED BEHAVIOR | Classified, not downloaded |
| Chat / Memories / friends-only | RESTRICTED_CONTENT | No fetch, no bypass, no retry |
| Login wall / `/login` | AUTHENTICATION_REQUIRED | No official Snapchat login |
| Expired Snap | CONTENT_EXPIRED | Permanent error, no retry |
| HLS-only video | PLATFORM_LIMITATION | Not remuxed into a file |
| Public `snapchat://spotlight` / `add` | COMPLETE | Normalized to HTTPS |
| `snapchat://chat` / `memories` | EXPECTED BEHAVIOR | Rejected with a clear message |
| javascript: / file: / localhost | EXPECTED BEHAVIOR | Rejected by UrlValidator / host check |

---

## Completion rule

| Criterion | Photo/Video Spotlight | Story | Restricted / Auth / Expired |
|-----------|----------------------|-------|-----------------------------|
| Implementation exists | YES | YES | Detection only |
| Unit tests pass | YES | YES | YES |
| Integration tests pass | YES | YES | YES |
| Manual test defined | YES | YES | YES |
| Error handling | YES | YES | YES |
| Storage / DB / library / playback | YES (shared engine) | YES (shared engine) | N/A (no file) |
| Regression | YES | YES | YES |

Public Spotlight, photo, Story, share, and embed workflows are **COMPLETE** when Snapchat exposes a progressive media file. Private content, login walls, expired Snaps, profile bulk download, and HLS-only streams are documented limitations or non-requirements, not silent gaps.

---

*Do not bypass authentication, privacy controls, private Stories, friends-only content, DRM, or platform security. Do not use stolen sessions, cookies, or unauthorized credentials. Do not attempt to recover expired or private content through unauthorized methods.*
