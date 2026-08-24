# LinkedIn Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

LinkedIn support is **implemented and tested** in the UniversalDownloader download engine. Before this phase LinkedIn was only a host label: `SocialPlatform.fromUri` matched `linkedin.com`, there was no `LinkedInUri`, no dedicated resolver, and generic Open Graph could treat a player page (`og:video` `text/html`) as a file.

This phase added `lnkd.in` / `licdn.com` detection, `LinkedInUri` (post / profile / company / article / embed / short / direct media), `LinkedInResolver` (public HTML → progressive MP4, DMS images, PDF when exposed), canonical activity identity, registry wiring, and security/error coverage.

LinkedIn uses the **existing Download Engine**. There is no LinkedIn-specific downloader.

**LinkedIn: 136 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 1617 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, and Twitch tests were included in that suite and did not regress.

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| Post / video / image / document / article / profile / company classification | COMPLETE |
| Activity / ugcPost / share ID (slug ignored) | COMPLETE |
| Share / `lnkd.in` / mobile / tracking URLs | COMPLETE |
| Image extraction (highest exposed DMS, skip logos) | COMPLETE |
| Multi-image count / order / dedupe | COMPLETE |
| Video progressive MP4 + actual qualities | COMPLETE |
| HLS-only video file download | **PLATFORM_LIMITATION** |
| Document PDF when exposed | COMPLETE |
| Article / profile / company download | **NOT_REQUIRED** (classified, not downloaded) |
| Download Engine / queue / storage / DB / library | COMPLETE (shared) |
| Pause / resume / retry / cancel / verify | COMPLETE (shared) |
| Restricted / auth-wall content | **PLATFORM_LIMITATION** |

### New / modified production files

| File | Purpose |
|------|---------|
| `linkedin_resolver.dart` | NEW resolver: HTML/JSON-LD/OG, MP4, images, PDF |
| `social_url_utils.dart` | `LinkedInUri` + `LinkedInContentType` |
| `social_platform.dart` | `lnkd.in` + `licdn.com` hosts |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → LinkedIn |
| `content_provider_registry.dart` | No homepage/profile/article HTML scrape |
| `media_extractor.dart` | Direct licdn only; ignore player OG |
| `download_manager.dart` | LinkedIn-specific user errors |
| `download_engine.dart` | Export resolver |

---

## Test Results

### LinkedIn automated tests (136)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| linkedin_url_test | 37 | 37 | 0 | 0 |
| linkedin_resolver_test | 13 | 13 | 0 | 0 |
| linkedin_post_test | 5 | 5 | 0 | 0 |
| linkedin_image_test | 5 | 5 | 0 | 0 |
| linkedin_video_test | 6 | 6 | 0 | 0 |
| linkedin_multi_media_test | 6 | 6 | 0 | 0 |
| linkedin_document_test | 3 | 3 | 0 | 0 |
| linkedin_metadata_test | 7 | 7 | 0 | 0 |
| linkedin_download_test | 10 | 10 | 0 | 0 |
| linkedin_error_test | 20 | 20 | 0 | 0 |
| linkedin_security_test | 19 | 19 | 0 | 0 |
| linkedin_performance_test | 5 | 5 | 0 | 0 |
| **Total LinkedIn** | **136** | **136** | **0** | **0** |

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
| LinkedIn | PASS (new) |
| Download engine / storage / security / filename | PASS |

**1617 passed, 0 failed, 26 skipped** (`flutter test` in `packages/download_engine`).

Skipped tests are pre-existing (not LinkedIn). None were skipped to hide failures.

---

## Manual tests required

Do **not** invent LinkedIn post IDs. Copy from the LinkedIn app/site at test time.

| ID | Intent | Status |
|----|--------|--------|
| LI-001 | Home — platform LINKEDIN, content HOME, no download | DEFINED (device) |
| LI-002 | Public post — detect POST, author, text, thumbnail | DEFINED (device) |
| LI-003 | Public image post — image, MIME, download, library | DEFINED (device) |
| LI-004 | Public video post — MP4 if exposed; else PLATFORM_LIMITATION | DEFINED (device) |
| LI-005 | Multi-image post — count, order, download | DEFINED (device) |
| LI-006 | Document/carousel — PDF/pages if exposed | DEFINED (device) |
| LI-007 | Article — ARTICLE, not a media download | DEFINED (device) |
| LI-008 | Profile — PROFILE, no auto-download | DEFINED (device) |
| LI-009 | Company — COMPANY, no auto-download | DEFINED (device) |
| LI-010 | Mobile share URL (P0) | DEFINED (device) |
| LI-011 | Canonical vs share vs query → same identity | DEFINED (device) |
| LI-012 | Unavailable/deleted post — clear error | DEFINED (device) |
| LI-013 | Restricted / auth-required — RESTRICTED, no bypass | DEFINED (device) |

Store exact copied URLs next to the ID when executing:

```
LI-002
<REAL LINKEDIN POST URL>
```

Automated fixtures cover the same logic without live network.

---

## Failures

None in automated suites.

---

## Classifications

| Item | Classification | Notes |
|------|----------------|-------|
| Public image / multi-image download | COMPLETE | Highest exposed DMS image |
| Public video progressive MP4 | COMPLETE | Best height actually listed |
| HLS-only video file | PLATFORM_LIMITATION | No converter in this engine |
| Document PDF | COMPLETE when URL is public | Empty if LinkedIn does not expose it |
| Article / profile / company file download | EXPECTED BEHAVIOR | Classified, not downloaded |
| Login wall / private post | PLATFORM_LIMITATION | Auth bypass prohibited |
| Deleted / unavailable post | EXPECTED BEHAVIOR | Empty result + user error |
| javascript: / file: / localhost | EXPECTED BEHAVIOR | Rejected by UrlValidator / host check |

---

## Completion rule

| Criterion | Image/PDF | Video MP4 | HLS-only video |
|-----------|-----------|-----------|----------------|
| Implementation exists | YES | YES | Detection only |
| Unit tests pass | YES | YES | YES |
| Integration tests pass | YES | YES | YES (empty discover) |
| Manual test defined | YES | YES | YES |
| Error handling | YES | YES | YES |
| Storage / DB / library / playback | YES (shared engine) | YES (shared engine) | N/A (no file) |
| Regression | YES | YES | YES |

Public image, multi-image, document-PDF, and progressive-MP4 workflows are **COMPLETE**. HLS-only video files, login-walled posts, and article/profile/company bulk download are documented limitations or non-requirements, not silent gaps.

---

*Do not bypass authentication, privacy controls, DRM, or platform security.*
