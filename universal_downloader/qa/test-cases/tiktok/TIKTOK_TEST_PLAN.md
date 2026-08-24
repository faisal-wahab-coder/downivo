# TikTok Integration Test Plan

**Platform:** TikTok (videos, short URLs, player/embed, photo posts)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

This test plan covers all TikTok-related functionality in UniversalDownloader:

1. URL detection, parsing, and video ID extraction
2. Username extraction from standard URLs
3. Short URL recognition (vm.tiktok.com, vt.tiktok.com, t.tiktok.com)
4. Player/embed URL classification
5. URL normalization and deduplication
6. Short URL redirect resolution
7. Metadata extraction from resolved resources
8. Download resolution through ContentProviderRegistry → TikTokResolver
9. HTML extraction strategies (downloadAddr, playAddr, playApi, SIGI_STATE, __UNIVERSAL_DATA_FOR_REHYDRATION__)
10. Video quality handling
11. Audio handling
12. Photo/carousel post handling
13. Download state machine transitions
14. Interruption handling (pause/resume/cancel)
15. Duplicate download behavior
16. Error handling for invalid URLs
17. Private/restricted content handling
18. File validation post-download
19. Security (malformed URLs, injection)
20. Regression test automation

---

## Implementation Summary

### Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover(pageUrl)
  ↓
PlatformSocialResolver.discover(pageUrl, SocialPlatform.tiktok)
  ↓
TikTokResolver.discover(pageUrl)
  ├── SocialUrlResolver.resolveRedirects()   # short link resolution
  ├── TikTokUri.videoIdFromUri()             # video ID extraction
  ├── Fetch HTML from up to 3 target URLs
  ├── _extractVideoUrl(html)                 # JSON fields + regex
  ├── _metaTitle(html)                       # og:title
  └── MediaExtractor.buildFileNameForSocial()
  ↓ (if null)
SocialUrlUtils.fetchTargets() + MediaExtractor.extract()   # generic fallback
```

### Key Components

| Component | File | Function |
|-----------|------|----------|
| Platform detection | `social_platform.dart` | `SocialPlatform.fromUri()` — matches `tiktok.com` or `*.tiktok.com` |
| Video ID extraction | `social_url_utils.dart` | `TikTokUri.videoIdFromUri()` — regex `/video/(\d+)` and `/v/(\d+)` |
| Short URL resolution | `social_url_resolver.dart` | `SocialUrlResolver.resolveRedirects()` — follows HTTP 3xx |
| TikTok resolver | `tiktok_resolver.dart` | `TikTokResolver.discover()` — fetches page HTML, extracts CDN URL |
| Fetch targets | `social_url_utils.dart` | `SocialUrlUtils._tiktokTargets()` — original + mobile + generic |
| HTTP headers | `social_http_headers.dart` | TikTok Origin/Referer for page fetch and CDN download |
| HTML extraction | `tiktok_resolver.dart` | `_extractVideoUrl()` — downloadAddr, playAddr, playApi, SIGI_STATE, regex |
| URL validation | `tiktok_resolver.dart` | `_isVideoPlaybackUrl()` — rejects static assets, accepts CDN video |
| Generic fallback | `media_extractor.dart` | `_extractTikTokVideo()` — same script IDs + CDN regex |
| File naming | `media_extractor.dart` | `buildFileNameForSocial()` — CDN basename, og:title slug, or video ID |
| CDN detection | `download_detector.dart` | `isSocialCdnUrl()` — recognizes `tiktokcdn.com`, `tiktokv.com` |

### What Is NOT Implemented

| Feature | Status |
|---------|--------|
| Photo/carousel posts | NOT SUPPORTED — resolver extracts video only |
| Quality selection | NOT SUPPORTED — single best stream returned |
| Audio-only download | NOT SUPPORTED — no audio extraction |
| Audio+Video muxing | NOT SUPPORTED — no ffmpeg integration |
| Thumbnail extraction | NOT SUPPORTED — not in DiscoveredResource |
| Duration extraction | NOT SUPPORTED — not in DiscoveredResource |
| vt.tiktok.com handling | PARTIAL — host detected, redirect resolution untested |
| t.tiktok.com handling | PARTIAL — host detected, redirect resolution untested |
| Player/embed URL content | NOT SUPPORTED — no video ID in `/player/v1/` path |
| Duplicate prevention | NOT SUPPORTED — duplicates are allowed |

---

## Test Data

### Standard TikTok Videos

| ID | URL | Expected Video ID | Expected Username |
|----|-----|-------------------|-------------------|
| TT-001 | `https://www.tiktok.com/@scout2015/video/6718335390845095173` | `6718335390845095173` | `scout2015` |
| TT-003 | `https://www.tiktok.com/@scout2015/video/6718335390845095173?_r=1&_t=8ZqWxYvBmN3` | `6718335390845095173` | `scout2015` |

### Player/Embed URL

| ID | URL | Classification |
|----|-----|---------------|
| TT-002 | `https://www.tiktok.com/player/v1/6718335390845095173` | TikTok platform detected, but no `/video/` path — video ID extraction returns null |

### Short URLs (Manual Testing Only)

| ID | Domain | Notes |
|----|--------|-------|
| TT-004 | `vm.tiktok.com` | Real URL from Share → Copy link |
| TT-005 | `vt.tiktok.com` | Real URL if available |
| TT-006 | `t.tiktok.com` | Real URL if available |

---

## Test Files

| File | Location | Type | Gate |
|------|----------|------|------|
| `tiktok_url_test.dart` | `packages/download_engine/test/` | Unit | Always |
| `tiktok_resolver_test.dart` | `packages/download_engine/test/` | Unit | Always |
| `tiktok_download_test.dart` | `packages/download_engine/test/` | Unit + Live | `TIKTOK_LIVE_TEST=1` |
| `tiktok_photo_test.dart` | `packages/download_engine/test/` | Unit | Always |
| `tiktok_error_test.dart` | `packages/download_engine/test/` | Unit | Always |

### Running Tests

```bash
# Unit tests only (no network)
cd packages/download_engine
flutter test test/tiktok_url_test.dart test/tiktok_resolver_test.dart test/tiktok_download_test.dart test/tiktok_photo_test.dart test/tiktok_error_test.dart

# Live integration tests (requires network + real TikTok)
TIKTOK_LIVE_TEST=1 flutter test test/tiktok_download_test.dart
```

---

## Phase Details

### Phase 1 — URL Parsing (Automated)

Verifies:
- `SocialPlatform.fromUri()` recognizes all TikTok hosts (www, m, vm, vt, t)
- `ContentProviderRegistry.canHandle()` returns true for TikTok URLs
- `TikTokUri.videoIdFromUri()` extracts correct numeric IDs from `/video/{id}` and `/v/{id}` paths
- Query parameters do not break parsing
- Username extraction from `/@{username}/video/` path
- Non-TikTok URLs are not misidentified

### Phase 2 — URL Normalization (Automated)

Verifies:
- URL with and without query params extract the same video ID
- `SocialUrlUtils.fetchTargets()` produces consistent targets
- Deduplication across URL variations

### Phase 3 — Short URL Resolution (Live + Manual)

Verifies:
- `vm.tiktok.com` URLs detected as TikTok platform
- `vt.tiktok.com` URLs detected as TikTok platform
- `t.tiktok.com` URLs detected as TikTok platform
- `SocialUrlResolver.resolveRedirects()` follows 3xx to final URL
- Video ID extractable from resolved URL
- Failed redirects do not crash — return original URL

### Phase 4 — Metadata Extraction (Automated)

Verifies:
- `TikTokResolver.extractFromHtmlForTest()` extracts from downloadAddr, playAddr, playApi
- og:title extraction from page HTML
- Platform label is "TikTok"
- fileName ends with `.mp4`
- mimeType is `video/mp4`
- Static/webarch CDN assets are rejected

**Gaps documented:**
- No thumbnail URL extraction
- No duration extraction
- No width/height extraction
- No description extraction
- No available formats list

### Phase 5 — Download Resolution (Live Only)

Gated by `TIKTOK_LIVE_TEST=1`. Verifies each URL resolves to a non-null `DiscoveredResource` with non-empty `directUrl`, `fileName`, and `platform`.

### Phase 6 — Video Quality (Not Supported)

**Finding:** `TikTokResolver` selects a single stream from downloadAddr/playAddr/playApi. There is no quality selection UI or API. The user cannot choose between qualities.

### Phase 7 — Audio (Not Supported)

**Finding:** No audio extraction or audio-only download capability. TikTok videos include audio in the MP4 stream.

### Phase 8 — Audio+Video Muxing (Not Applicable)

**Finding:** TikTok typically serves muxed MP4 streams. No separate stream muxing is needed or implemented.

### Phase 9 — Photo Posts (Not Supported)

**Finding:** The resolver only extracts video URLs. TikTok photo/carousel posts have no dedicated handling. The resolver would return null for photo-only posts.

### Phase 10 — Download State Machine (Existing Tests)

States verified by existing `DL-*` tests: queued, preparing, downloading, paused, completed, failed, cancelled, verifying. TikTok downloads follow the same state machine as all other downloads.

### Phase 11 — Interruptions (Manual Only)

Covered by existing infrastructure. Manual device testing required for pause/resume, app background, network interruption.

### Phase 12 — Duplicate Download (Documented)

**Finding:** `DownloadManager.enqueue()` does not check for existing tasks. Duplicates are allowed — each call creates a separate task.

### Phase 13 — Invalid URLs (Automated)

Verifies graceful handling of: homepage, profile-only, empty video ID, non-numeric video ID, invalid short URLs, non-TikTok URLs.

### Phase 14 — Private/Restricted Content (Manual)

Private, deleted, age-restricted, or region-restricted content should fail gracefully. The resolver returns null, which the download manager treats as a discovery failure.

### Phase 15 — File Validation (Automated + Manual)

MIME-to-extension mapping tested. Sanitize tested. Full file validation (size, playability, corruption) requires manual testing on device.

### Phase 16 — Security (Automated)

Tests malformed URLs, unexpected protocols (javascript:, file:, ftp:), localhost, private IPs, excessively long URLs. The URL validator and `SocialPlatform.fromUri()` protect against these.

### Phase 17 — Player/Embed URL (Automated)

Verifies that `/player/v1/{id}` URLs are correctly detected as TikTok platform but do not extract a video ID from the `/video/` path pattern — they use a different path structure.

---

## Manual Test Procedures

### M-TT-001 Full Download Flow (Standard Video)

1. Launch app on Android device
2. Navigate to Downloads tab
3. Add URL: `https://www.tiktok.com/@scout2015/video/6718335390845095173`
4. Verify wizard appears with TikTok detected
5. Confirm download
6. Observe progress bar
7. Verify file appears in Videos category
8. Open file — verify playback with audio

### M-TT-002 Short URL Download

1. Copy a real `vm.tiktok.com` share URL from TikTok app
2. Add URL in app
3. Verify TikTok platform detected
4. Verify redirect resolution completes
5. Verify metadata displayed
6. Confirm and complete download

### M-TT-003 Pause/Resume

1. Start download of TikTok video
2. Pause at ~30%
3. Verify progress freezes
4. Resume
5. Verify download completes

### M-TT-004 Cancel

1. Start download
2. Cancel
3. Verify partial file deleted
4. Verify task removed from active list

### M-TT-005 Network Interruption

1. Start download
2. Toggle airplane mode
3. Verify failure/retry behavior
4. Restore connectivity
5. Retry — verify completion

### M-TT-006 Duplicate Download

1. Download `https://www.tiktok.com/@scout2015/video/6718335390845095173`
2. Download same URL again
3. Verify both complete as separate tasks

### M-TT-007 Invalid URL

1. Add `https://www.tiktok.com/@scout2015/video/INVALID`
2. Verify meaningful error
3. Verify no stuck task

### M-TT-008 Photo Post

1. Find a real TikTok photo post URL
2. Add URL in app
3. Verify behavior — expected: no media found, graceful failure

### M-TT-009 Private Content

1. Find a private TikTok video URL
2. Add URL in app
3. Verify clear error — no crash, no infinite retry

### M-TT-010 Player URL

1. Add `https://www.tiktok.com/player/v1/6718335390845095173`
2. Observe behavior
3. Document whether it resolves or returns error

---

## Checklist (Per Real TikTok URL)

1. Paste URL
2. Detect platform → TikTok
3. Resolve URL (follow redirects if short URL)
4. Display metadata (title if available)
5. Display thumbnail (NOT IMPLEMENTED)
6. Display duration (NOT IMPLEMENTED)
7. Display available quality (NOT IMPLEMENTED — single stream)
8. Select quality (N/A)
9. Start download
10. Observe progress
11. Pause
12. Resume
13. Complete
14. Open downloaded file
15. Verify video playback
16. Verify audio in video
17. Check file size > 0
18. Check Downloads database record
19. Check Media Library entry
20. Check notification
21. Repeat download (duplicate test)
22. Verify duplicate behavior (separate tasks created)
