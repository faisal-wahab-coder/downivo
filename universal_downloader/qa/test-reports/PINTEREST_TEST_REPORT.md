# Pinterest Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

Pinterest support is **implemented and tested** in the UniversalDownloader download engine. Before this phase the platform was declared (`SocialPlatform.pinterest`, `pin.it` host, generic OG video regex) but **had no resolver**, no pin identity, and no image/video/Idea Pin extraction.

This phase added URL classification, slug-independent pin identity, original-quality images (JPG/PNG/WebP/GIF), progressive MP4 video (HLS skipped), Idea Pin `discoverAll`, direct CDN URLs, `pin.it` share handling, metadata, and security/error coverage.

**Pinterest: 158 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 1196 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, SoundCloud, and Reddit tests were included in that suite and did not regress.

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| Image pins (orig quality, correct MIME) | COMPLETE |
| Video pins (best MP4, skip HLS) | COMPLETE |
| Idea Pins / multi-page | COMPLETE |
| Direct pinimg URLs | COMPLETE |
| Share (`pin.it`, `/sent/`) | COMPLETE |
| Board / profile / home | COMPLETE — correctly non-downloadable |
| Metadata / thumbnails | COMPLETE |
| Download Engine / queue / storage / DB / library | COMPLETE (shared architecture) |
| HLS-only video | **PLATFORM_LIMITATION** (documented) |

### New / modified production files

| File | Purpose |
|------|---------|
| `pinterest_resolver.dart` | Full resolver: image, video, idea pin, direct, share |
| `social_url_utils.dart` | `PinterestUri` + `PinterestContentType` |
| `social_platform.dart` | Regional + CDN host detection |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Pinterest |
| `content_provider_registry.dart` | No homepage/board HTML scrape |
| `media_extractor.dart` | Pinterest OG + originals upgrade |
| `download_engine.dart` | Export resolver |

---

## Test Results

### Pinterest tests (158)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| pinterest_url_test | 56 | 56 | 0 | 0 |
| pinterest_resolver_test | 13 | 13 | 0 | 0 |
| pinterest_image_test | 7 | 7 | 0 | 0 |
| pinterest_video_test | 8 | 8 | 0 | 0 |
| pinterest_idea_pin_test | 7 | 7 | 0 | 0 |
| pinterest_multi_media_test | 6 | 6 | 0 | 0 |
| pinterest_metadata_test | 8 | 8 | 0 | 0 |
| pinterest_download_test | 13 | 13 | 0 | 0 |
| pinterest_error_test | 18 | 18 | 0 | 0 |
| pinterest_security_test | 18 | 18 | 0 | 0 |
| pinterest_performance_test | 4 | 4 | 0 | 0 |
| **Total Pinterest** | **158** | **158** | **0** | **0** |

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
| Download Engine / integration / security | PASS |

**Total: 1196 passed, 0 failed, 26 skipped** (skipped = existing env-gated live discovery tests).

---

## Failures

None in automated suites.

---

## Manual tests required

Do **not** invent Pin IDs. Copy links from Pinterest → Pin → Share → Copy link.

| ID | Case | Status |
|----|------|--------|
| PT-001 | Home `https://www.pinterest.com/` | DEFINED — automated equivalent passes |
| PT-002 | Public image Pin (copy from Pinterest) | **MANUAL REQUIRED** — do not invent URLs |
| PT-003 | Second image Pin (different aspect ratio) | **MANUAL REQUIRED** |
| PT-004 | Public video Pin | **MANUAL REQUIRED** |
| PT-005 | Multi-media / Idea Pin | **MANUAL REQUIRED** |
| PT-006 | Mobile share URL (P0) | **MANUAL REQUIRED** — store exact copied URL |
| PT-007 | Public Board URL | DEFINED — automated equivalent passes (no bulk download) |
| PT-008 | Public profile URL | DEFINED — automated equivalent passes (no download) |
| PT-009 | URL variations of the same Pin | DEFINED — automated identity tests pass; live confirm |
| PT-010 | `https://www.pinterest.com/pin/INVALID/` | DEFINED — automated equivalent passes |

Existing repo live fixture (not invented in this phase), env-gated:

- `https://www.pinterest.com/pin/580547278694592554/`

Re-verify that this pin is still public before using it as PT-002.

---

## Platform limitations

| Item | Classification | Notes |
|------|----------------|-------|
| HLS-only video (no MP4 in `video_list`) | PLATFORM_LIMITATION | Empty result. Thumbnail is not downloaded as a substitute. |
| Private / login-walled pins | PLATFORM_LIMITATION | No auth bypass. Empty result + HTTP error mapping. |
| Board bulk crawl | EXPECTED BEHAVIOR | Docs do not require it. BOARD → no download. |
| Profile bulk crawl | EXPECTED BEHAVIOR | PROFILE → no download. |
| HLS separate audio mux | NOT_REQUIRED | Progressive MP4 is muxed; HLS is skipped. |

---

## Security

- Only `http`/`https` accepted
- `javascript:`, `file:`, localhost, private IPs rejected as Pinterest
- Filenames sanitized; path traversal cannot escape storage
- Encoded `..` in pin paths is collapsed by `Uri` (no fake pin ID)
- No cookies/tokens logged by the resolver

---

## Completion

Pinterest required functionality is **COMPLETE** except the documented HLS **PLATFORM_LIMITATION**. Automated Pinterest tests pass. Engine-wide regression passes. Device/manual copy-link tests remain for live Pinterest pages.
