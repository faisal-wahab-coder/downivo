# Threads Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

Threads support is **implemented and tested** in the Downivo download engine. Public `threads.net` / `threads.com` / share / embed URLs are classified, normalized, and resolved through `ThreadsResolver` into the **existing Download Engine**. There is no Threads-specific downloader.

Private profiles/posts, login walls, deleted posts, text-only posts, and HLS-only streams are classified and **not** bypassed. Restricted, authentication-required, unavailable, text-only, and HLS-only failures are **not retried**.

**Threads: 138 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 2075 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn, Telegram, and Snapchat tests were included in that suite and did not regress. Dailymotion is not present in this codebase (no adapter, tests, or docs requirement).

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| `threads.net` + `threads.com` | COMPLETE |
| Profile / post / embed / share / `/t/{id}` | COMPLETE |
| Content ID / username | COMPLETE |
| Share / tracking / embed URLs | COMPLETE |
| Image / video when a public CDN URL is exposed | COMPLETE |
| Carousel / multi-media count / order / dedupe | COMPLETE |
| Quote / repost media + original identity | COMPLETE |
| Text-only post | COMPLETE (`NO_DOWNLOADABLE_MEDIA`) |
| Profile / home download | **NOT_REQUIRED** (classified, not downloaded) |
| Download Engine / queue / storage / DB / library | COMPLETE (shared) |
| Pause / resume / retry / cancel / verify | COMPLETE (shared) |
| Restricted / auth-wall content | **RESTRICTED_CONTENT** / **AUTHENTICATION_REQUIRED** |
| Deleted / unavailable post | **CONTENT_UNAVAILABLE** |
| HLS-only video | **PLATFORM_LIMITATION** |

### Production files

| File | Purpose |
|------|---------|
| `threads_resolver.dart` | Public HTML → media; auth/restricted/unavailable/text/HLS errors |
| `social_url_utils.dart` | `ThreadsUri` + `ThreadsContentType` |
| `social_platform.dart` | `threads.net`, `threads.com` |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Threads |
| `content_provider_registry.dart` | No homepage/profile HTML scrape |
| `media_extractor.dart` | Direct Threads CDN only; skip HLS |
| `download_manager.dart` | Threads user errors; no retry for permanent failures |
| `download_engine.dart` | Export resolver |

---

## Test Results

### Threads automated tests (138)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| threads_url_test | 28 | 28 | 0 | 0 |
| threads_resolver_test | 10 | 10 | 0 | 0 |
| threads_profile_test | 5 | 5 | 0 | 0 |
| threads_post_test | 6 | 6 | 0 | 0 |
| threads_image_test | 5 | 5 | 0 | 0 |
| threads_video_test | 5 | 5 | 0 | 0 |
| threads_carousel_test | 5 | 5 | 0 | 0 |
| threads_metadata_test | 7 | 7 | 0 | 0 |
| threads_thumbnail_test | 4 | 4 | 0 | 0 |
| threads_download_test | 10 | 10 | 0 | 0 |
| threads_auth_test | 6 | 6 | 0 | 0 |
| threads_restriction_test | 5 | 5 | 0 | 0 |
| threads_error_test | 16 | 16 | 0 | 0 |
| threads_security_test | 21 | 21 | 0 | 0 |
| threads_performance_test | 5 | 5 | 0 | 0 |
| **Total Threads** | **138** | **138** | **0** | **0** |

### Full regression

| Result | Count |
|--------|------:|
| Passed | 2075 |
| Failed | 0 |
| Skipped | 26 |

Skipped tests are existing live-network / environment-gated cases (`SOCIAL_LIVE_TEST=1`), not Threads failures.

---

## Manual tests

Real public Threads URLs must be copied from Threads. **Do not invent post IDs.**

| ID | Case | Status | Notes |
|----|------|--------|-------|
| TH-001 | `https://www.threads.net/` home | DEFINED | Automated as HOME; no download |
| TH-002 | Public profile | **MANUAL REQUIRED** | Copy a real public profile link |
| TH-003 | Public text post | **MANUAL REQUIRED** | Expect no downloadable media |
| TH-004 | Public image post | **MANUAL REQUIRED** | Download + library |
| TH-005 | Public video post | **MANUAL REQUIRED** | Playback + audio |
| TH-006 | Multi-image post | **MANUAL REQUIRED** | Count / order |
| TH-007 | Multi-media post | **MANUAL REQUIRED** | If a public example exists |
| TH-008 | Share → Copy Link | **MANUAL REQUIRED** | P0 — store exact copied URL |
| TH-009 | Large public video | **MANUAL REQUIRED** | Pause / resume / background |
| TH-010 | Quote post | **MANUAL REQUIRED** | Original identity |
| TH-011 | Repost | **MANUAL REQUIRED** | Original identity |
| TH-012 | Private content | **MANUAL REQUIRED** | Expect RESTRICTED; never bypass |
| TH-013 | Unavailable / deleted | **MANUAL REQUIRED** | Expect CONTENT_UNAVAILABLE |
| TH-014 | `@INVALID/post/INVALID` | DEFINED | Structural POST; resolve → unavailable/invalid |
| TH-015 | `/INVALID` | DEFINED | `INVALID_URL` / NON_CONTENT |
| TH-QA-001–009 | Controlled QA account | **BLOCKED** | No team-owned Threads account in this repo |

Classification for blocked manuals: **ENVIRONMENT PROBLEM** (no live public URL stored in-repo) — not a production bug.

---

## Failures

None in automated suites.

---

## Platform regression

| Platform | Result |
|----------|--------|
| YouTube | PASS (included in 2075) |
| TikTok | PASS |
| Instagram | PASS |
| Facebook | PASS |
| SoundCloud | PASS |
| Reddit | PASS |
| Pinterest | PASS |
| Vimeo | PASS |
| Twitch | PASS |
| LinkedIn | PASS |
| Telegram | PASS |
| Snapchat | PASS |
| Dailymotion | NOT IN CODEBASE |
| Threads | PASS (138) |

Threads did not break URL detection, platform adapters, Download Engine, queue, storage, database, media library, file manager, notifications, background downloads, or error handling.

---

## Completion

A Threads feature is COMPLETE when implementation, unit tests, integration tests, manual test definitions, error/storage/database/library paths, and regression all exist.

| Gate | Status |
|------|--------|
| Implementation exists | YES |
| Unit tests pass | YES (138) |
| Integration tests pass | YES (resolver + registry mocks) |
| Manual test is defined | YES (TH-001–015) |
| Error handling works | YES |
| Storage / DB / library | YES (shared engine) |
| Playback where applicable | Shared player; live playback is manual |
| Regression tests pass | YES (2075 / 0 / 26) |

Live public-URL confirmation (TH-002–013) remains a **manual** step and must use URLs copied from Threads.
