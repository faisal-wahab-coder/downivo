# YouTube Integration Test Plan

**Platform:** YouTube (standard videos + Shorts)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

This test plan covers all YouTube-related functionality in UniversalDownloader:

1. URL detection, parsing, and video ID extraction
2. Metadata extraction from resolved resources
3. Download resolution through ContentProviderRegistry → YouTubeResolver
4. Video quality selection
5. Audio-only downloads
6. Audio+Video muxing
7. YouTube Shorts handling
8. URL variation normalization
9. Download state machine transitions
10. Interruption handling (pause/resume/cancel)
11. Duplicate download behavior
12. Error handling for invalid URLs
13. File validation post-download
14. Regression test automation

---

## Test Data

### Standard YouTube Videos

| ID | URL | Expected Video ID |
|----|-----|-------------------|
| YT-001 | `https://www.youtube.com/watch?v=YE7VzlLtp-4` | `YE7VzlLtp-4` |
| YT-002 | `https://youtu.be/YE7VzlLtp-4` | `YE7VzlLtp-4` |
| YT-003 | `https://www.youtube.com/watch?v=YE7VzlLtp-4&t=30s` | `YE7VzlLtp-4` |
| YT-004 | `https://www.youtube.com/watch?v=YE7VzlLtp-4&feature=youtu.be` | `YE7VzlLtp-4` |
| YT-005 | `https://www.youtube.com/watch?v=f7NwyBnIRTE` | `f7NwyBnIRTE` |

### YouTube Shorts

| ID | URL | Expected Video ID |
|----|-----|-------------------|
| YTS-001 | `https://youtube.com/shorts/ld4K5nw9gsk` | `ld4K5nw9gsk` |
| YTS-002 | `https://youtube.com/shorts/XFM4tCakAXY` | `XFM4tCakAXY` |
| YTS-003 | `https://youtube.com/shorts/BxXzzAEEhCA` | `BxXzzAEEhCA` |
| YTS-004 | `https://youtube.com/shorts/LNv4y3wPQA0` | `LNv4y3wPQA0` |
| YTS-005 | `https://youtube.com/shorts/hvmIZAvt3jE` | `hvmIZAvt3jE` |
| YTS-006 | `https://youtube.com/shorts/MNRgAw45mTM` | `MNRgAw45mTM` |

---

## Test Files

| File | Location | Type | Gate |
|------|----------|------|------|
| `youtube_url_test.dart` | `packages/download_engine/test/` | Unit | Always |
| `youtube_resolver_test.dart` | `packages/download_engine/test/` | Unit | Always |
| `youtube_shorts_test.dart` | `packages/download_engine/test/` | Unit | Always |
| `youtube_download_test.dart` | `packages/download_engine/test/` | Unit + Live | `YOUTUBE_LIVE_TEST=1` |

### Running Tests

```bash
# Unit tests only (no network)
cd packages/download_engine
flutter test test/youtube_url_test.dart test/youtube_resolver_test.dart test/youtube_shorts_test.dart test/youtube_download_test.dart

# Live integration tests (requires network + real YouTube)
YOUTUBE_LIVE_TEST=1 flutter test test/youtube_download_test.dart
```

---

## Phase Details

### Phase 1 — URL Parsing (Automated)

Verifies:
- `SocialPlatform.fromUri()` recognizes all YouTube hosts
- `ContentProviderRegistry.canHandle()` returns true
- `YouTubeUri.videoIdFromUri()` extracts correct IDs
- Query parameters do not break parsing
- youtu.be, /watch, /shorts/, /embed/, /live/ patterns all work

### Phase 2 — Metadata Extraction (Partially Automated)

Unit tests verify:
- `MediaExtractor` extracts `og:title` from synthetic HTML
- `DiscoveredResource` has `platform = "YouTube"`
- `directUrl` points to `googlevideo.com`
- `fileName` ends with `.mp4`
- `mimeType` is set when available
- Empty/missing HTML returns null

**Gaps identified:**
- No thumbnail URL extraction (not in DiscoveredResource)
- No duration extraction (not in DiscoveredResource or DownloadTask)
- No channel/creator extraction
- No Shorts-vs-standard content type field

### Phase 3 — Download Resolution (Live Only)

Gated by `YOUTUBE_LIVE_TEST=1`. Verifies each URL resolves to a non-null `DiscoveredResource` with non-empty `directUrl`, `fileName`, and `platform`.

### Phase 4 — Video Quality (Not Supported)

**Finding:** YouTubeResolver selects a single "best" stream using itag preference `[22, 18, 37, 136, 135, 134, 399, 401, 313]`. There is no quality selection UI or API. The user cannot choose between 360p, 720p, etc.

### Phase 5 — Audio-Only (Not Supported)

**Finding:** No audio-only itags (140, 251, 249, 250) in the preferred list. Audio-only download is not implemented.

### Phase 6 — Audio+Video Muxing (Not Supported)

**Finding:** No ffmpeg or muxer integration exists. The app downloads a single muxed stream (itag 22 = 720p+audio or itag 18 = 360p+audio).

### Phase 7 — Shorts (Automated)

All six Shorts URLs verified for:
- Platform detection (YouTube)
- Video ID extraction
- Normalization to canonical `/watch?v=ID`
- Original `/shorts/` path detection

**Gaps identified:**
- No `isShorts` flag in DiscoveredResource
- Normalization loses `/shorts/` path
- No vertical aspect ratio detection
- No duration field for ≤60s Shorts verification

### Phase 8 — URL Variations (Automated)

All four URL forms for `YE7VzlLtp-4` verified to:
- Extract the same video ID
- Normalize to the same canonical URL
- Produce identical fetch targets

### Phase 9 — Download State Machine (Automated + Existing)

States verified: queued, preparing, downloading, paused, completed, failed, cancelled, verifying.
Round-trip storage values verified. `isActive` covers correct states.
Existing DL-001 through DL-013 tests cover full lifecycle.

### Phase 10 — Interruptions (Existing Tests)

Covered by `DL-006` (pause/resume), `DL-007` (cancel), crash recovery test.
Application background/restart and network interruption require manual testing on device.

### Phase 11 — Duplicate Download (Documented)

**Finding:** `DownloadManager.enqueue()` does not check for existing tasks with the same URL. Duplicates are allowed — each call creates a separate task.

### Phase 12 — Error Handling (Automated + Live)

Unit tests verify invalid URL forms return null video IDs. Live tests verify no crashes for invalid video IDs. DownloadErrorFormatter tested for message formatting.

### Phase 13 — File Validation (Automated)

MIME-to-extension mapping tested. `ensureExtension` tested. Sanitize tested. Full file validation (size, playability) requires manual testing on device.

### Phase 14 — Regression Tests (This Document)

All tests organized in `packages/download_engine/test/youtube_*.dart`. Run as part of the standard `flutter test` suite. Live tests gated behind environment variable.

---

## Manual Test Procedures

### M-YT-001 Full Download Flow (Standard Video)

1. Launch app on Android device
2. Navigate to Downloads tab
3. Add URL: `https://www.youtube.com/watch?v=YE7VzlLtp-4`
4. Verify wizard appears with YouTube detected
5. Confirm download
6. Observe progress bar
7. Verify file appears in Videos category
8. Open file — verify playback

### M-YT-002 Full Download Flow (Shorts)

1. Add URL: `https://youtube.com/shorts/ld4K5nw9gsk`
2. Verify YouTube platform detected
3. Confirm download
4. Verify download completes
5. Open file — verify vertical video playback

### M-YT-003 Pause/Resume

1. Start download of `https://www.youtube.com/watch?v=YE7VzlLtp-4`
2. Pause at ~30%
3. Verify progress freezes
4. Resume
5. Verify download completes

### M-YT-004 Cancel

1. Start download
2. Cancel
3. Verify partial file is deleted
4. Verify task removed from active list

### M-YT-005 Network Interruption

1. Start download
2. Toggle airplane mode
3. Verify failure/retry behavior
4. Restore connectivity
5. Retry — verify completion

### M-YT-006 Duplicate Download

1. Download `https://www.youtube.com/watch?v=YE7VzlLtp-4`
2. Download same URL again
3. Verify both complete as separate tasks

### M-YT-007 Invalid URL

1. Add `https://www.youtube.com/watch?v=INVALID_VIDEO_ID`
2. Verify meaningful error
3. Verify no stuck task
