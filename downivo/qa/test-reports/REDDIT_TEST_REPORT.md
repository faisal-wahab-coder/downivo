# Reddit Test Report

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Engineer:** QA / Implementation Engineer

---

## Executive Summary

Reddit support is **implemented and tested** in the Downivo download engine. The previous resolver only extracted hosted video MP4 from post JSON. This phase added URL classification, slug-independent post identity, images (JPG/PNG/WebP), GIF-accurate MIME, galleries/`discoverAll`, direct CDN URLs, short/share URL handling, metadata, and security/error coverage.

**Reddit: 162 passed, 0 failed, 0 skipped.**

**Full download_engine regression: 957 passed, 0 failed, 26 skipped.**

YouTube, TikTok, Instagram, Facebook, and SoundCloud tests were included in that suite and did not regress.

---

## Implementation Status

| Area | Status |
|------|--------|
| URL detection / parse / normalize | COMPLETE |
| Video posts | COMPLETE |
| Image posts | COMPLETE |
| GIF / GIF-like | COMPLETE (actual MIME preserved) |
| Galleries / mixed media | COMPLETE |
| Direct media URLs | COMPLETE |
| Short (`redd.it`) / share URLs | COMPLETE |
| Subreddit / home | COMPLETE — correctly non-downloadable |
| Metadata / thumbnails | COMPLETE |
| Download Engine / queue / storage / DB / library | COMPLETE (shared architecture) |
| Video+audio mux to one file | **PLATFORM_LIMITATION** (documented) |

### New / modified production files

| File | Purpose |
|------|---------|
| `reddit_resolver.dart` | Full resolver: video, image, GIF, gallery, direct, share |
| `social_url_utils.dart` | `RedditUri` + `RedditContentType` |
| `platform_social_resolver.dart` | `discoverAll` → Reddit |
| `content_provider_registry.dart` | No homepage HTML scrape for Reddit |
| `media_extractor.dart` | Reddit image + DASH MP4 HTML fallback |
| `filename_resolver.dart` | `image/jpg` → `.jpg` |

---

## Test Results

### Reddit tests (162)

| Suite | Total | Passed | Failed | Skipped |
|-------|------:|-------:|-------:|--------:|
| reddit_url_test | 54 | 54 | 0 | 0 |
| reddit_resolver_test | 21 | 21 | 0 | 0 |
| reddit_video_test | 8 | 8 | 0 | 0 |
| reddit_image_test | 7 | 7 | 0 | 0 |
| reddit_gif_test | 5 | 5 | 0 | 0 |
| reddit_gallery_test | 9 | 9 | 0 | 0 |
| reddit_metadata_test | 9 | 9 | 0 | 0 |
| reddit_download_test | 12 | 12 | 0 | 0 |
| reddit_error_test | 17 | 17 | 0 | 0 |
| reddit_security_test | 17 | 17 | 0 | 0 |
| reddit_performance_test | 3 | 3 | 0 | 0 |
| **Total Reddit** | **162** | **162** | **0** | **0** |

### Full regression

| Platform / area | Status |
|-----------------|--------|
| YouTube | PASS |
| TikTok | PASS |
| Instagram | PASS |
| Facebook | PASS |
| SoundCloud | PASS |
| Reddit | PASS |
| Download Engine / integration / security | PASS |

**Total: 957 passed, 0 failed, 26 skipped** (skipped = existing env-gated live discovery tests).

---

## Failures

None in automated suites.

---

## Manual tests required

| ID | Case | Status |
|----|------|--------|
| RD-001 | Home `https://www.reddit.com/` | DEFINED — automated equivalent passes |
| RD-002 | Public image (copy from Reddit) | **MANUAL REQUIRED** — do not invent URLs |
| RD-003 | Public video | **MANUAL REQUIRED** |
| RD-004 | GIF / GIF-like | **MANUAL REQUIRED** |
| RD-005 | Gallery (P0) | **MANUAL REQUIRED** |
| RD-006 | Mixed media if available | **MANUAL REQUIRED** |
| RD-007 | Mobile share URL (P0) | **MANUAL REQUIRED** |
| RD-008 | Direct `i.redd.it` / `v.redd.it` | **MANUAL REQUIRED** |
| RD-009 | Invalid post | DEFINED — automated equivalent passes |
| RD-010 | Removed/unavailable | DEFINED — fixture `removed_by_category` passes; live optional |

Existing repo live fixtures (not invented here), env-gated:

- `https://www.reddit.com/r/videos/comments/6rrwyj/that_small_heart_attack/`
- `https://www.reddit.com/r/funny/comments/d8qo81/baby_crocodiles_sound_like_theyre_shooting_laser/`

---

## Platform limitations

| Item | Classification | Notes |
|------|----------------|-------|
| Silent DASH video when `has_audio=true` | PLATFORM_LIMITATION | Reddit splits video/audio. Engine has no muxer (same as YouTube). Audio URL is identified as `https://v.redd.it/<id>/DASH_audio.mp4`. |
| Private / login-walled / quarantined | PLATFORM_LIMITATION | No auth bypass. Empty result + HTTP error mapping. |
| Subreddit bulk crawl | EXPECTED BEHAVIOR | Docs do not require it. SUBREDDIT → no download. |
| HLS `.m3u8` as a file | EXPECTED BEHAVIOR | Not a media file; ignored in favor of `fallback_url`. |

---

## Security

- Only `http`/`https` accepted
- `javascript:`, `file:`, localhost, private IPs rejected as Reddit
- Filenames sanitized; path traversal cannot escape storage
- No cookies/tokens logged by the resolver

---

## Completion

Reddit required functionality is **COMPLETE** except the documented muxing **PLATFORM_LIMITATION**. Automated Reddit tests pass. Engine-wide regression passes. Device/manual copy-link tests remain for live Reddit pages.
