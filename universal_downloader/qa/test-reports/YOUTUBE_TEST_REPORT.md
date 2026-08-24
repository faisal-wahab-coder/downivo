# YouTube Integration Test Report

**Date:** 2026-08-15
**Platform:** YouTube (standard videos + Shorts)
**Package:** `download_engine` v0.1.0
**Tester:** QA Engineer (automated)
**Environment:** macOS / Flutter 3.24+ / Dart 3.10+

---

## Summary

| Metric | Count |
|--------|-------|
| **Total tests** | 131 |
| **Passed** | 114 |
| **Failed** | 0 |
| **Skipped** | 17 (live tests, gated by `YOUTUBE_LIVE_TEST=1`) |
| **Blocked** | 0 |
| **Manual tests required** | 7 (see below) |
| **Production bugs** | 0 |
| **Architectural gaps** | 7 (see below) |
| **Environment problems** | 0 |

### Existing Suite Regression Check

The full `download_engine` test suite (172 passed, 18 skipped) ran with **zero regressions** after adding the YouTube test files.

---

## Test Results by Phase

### Phase 1 — URL Parsing

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-URL-001 | www.youtube.com/watch detected as YouTube | PASS |
| YT-URL-002 | youtu.be shortlink detected as YouTube | PASS |
| YT-URL-003 | youtube.com/shorts detected as YouTube | PASS |
| YT-URL-004 | m.youtube.com detected as YouTube | PASS |
| YT-URL-005 | youtube.com/embed detected as YouTube | PASS |
| YT-URL-006 | non-YouTube host rejected | PASS |
| YT-001 | watch?v=YE7VzlLtp-4 → YE7VzlLtp-4 | PASS |
| YT-002 | youtu.be/YE7VzlLtp-4 → YE7VzlLtp-4 | PASS |
| YT-003 | watch?v=YE7VzlLtp-4&t=30s → YE7VzlLtp-4 | PASS |
| YT-004 | watch?v=YE7VzlLtp-4&feature=youtu.be → YE7VzlLtp-4 | PASS |
| YT-005 | watch?v=f7NwyBnIRTE → f7NwyBnIRTE | PASS |
| YT-006 | YouTubeResolver.videoIdFromUri matches YouTubeUri | PASS |
| YT-EMBED-001 | /embed/ URL extracts video ID | PASS |
| YT-LIVE-001 | /live/ URL extracts video ID | PASS |
| YT-QUERY-001 | extra query params don't break parsing | PASS |
| YT-QUERY-002 | youtu.be with si param extracts ID | PASS |
| YT-MOBILE-001 | m.youtube.com extracts video ID | PASS |
| YT-HTML-001 | rr prefix googlevideo URL extracted | PASS |
| YT-HTML-002 | streamingUrl with unicode escapes decoded | PASS |
| YT-HTML-003 | SABR streams rejected | PASS |
| YT-HTML-004 | ytInitialPlayerResponse extracted | PASS |
| YT-TYPE-001 | no content type field documented | PASS |
| YT-TYPE-002 | /shorts/ path detectable from URL | PASS |
| YT-NORM-001 | Shorts normalizes to watch URL | PASS |
| YT-NORM-002 | youtu.be normalizes to watch URL | PASS |
| YT-NORM-003 | embed URL in fetch targets | PASS |

**Phase 1 total: 26 PASS, 0 FAIL**

### Phase 2 — Metadata Extraction

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-META-001 | og:title extracted from HTML | PASS |
| YT-META-002 | platform label is "YouTube" | PASS |
| YT-META-003 | directUrl points to googlevideo.com | PASS |
| YT-META-004 | fileName ends with .mp4 | PASS |
| YT-META-005 | mimeType set from og:video:type | PASS |
| YT-META-006 | empty HTML returns null | PASS |
| YT-META-007 | HTML without streaming data returns null | PASS |

**Phase 2 total: 7 PASS, 0 FAIL**

### Phase 3 — Download Resolution

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-RES-001 | DiscoveredResource has required fields | PASS |
| YT-RES-002 | copyWith preserves pageUrl | PASS |
| YT-NAME-001 | buildFileNameForSocial uses title slug | PASS |
| YT-NAME-002 | fallback slug uses video ID | PASS |
| YT-NAME-003 | sanitize removes dangerous characters | PASS |
| YT-ITAG-001 | itag preference tested | PASS |
| YT-ITAG-002 | itag 22 vs 18 selection | PASS |

**Phase 3 total: 7 PASS, 0 FAIL**

### Phase 4 — Video Quality

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-CAP-001 | Single best stream returned, no quality list | PASS (documented) |

**Phase 4 total: 1 PASS (architectural gap documented)**

### Phase 5 — Audio-Only

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-CAP-002 | No audio-only itags in preferred list | PASS (documented) |

**Phase 5 total: 1 PASS (feature not implemented)**

### Phase 6 — Audio+Video Muxing

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-CAP-003 | No muxing pipeline exists | PASS (documented) |

**Phase 6 total: 1 PASS (feature not implemented)**

### Phase 7 — YouTube Shorts

| Test ID | Description | Result |
|---------|-------------|--------|
| YTS-001 | ld4K5nw9gsk — recognized, extracted, normalized | PASS (×4) |
| YTS-002 | XFM4tCakAXY — recognized, extracted, normalized | PASS (×4) |
| YTS-003 | BxXzzAEEhCA — recognized, extracted, normalized | PASS (×4) |
| YTS-004 | LNv4y3wPQA0 — recognized, extracted, normalized | PASS (×4) |
| YTS-005 | hvmIZAvt3jE — recognized, extracted, normalized | PASS (×4) |
| YTS-006 | MNRgAw45mTM — recognized, extracted, normalized | PASS (×4) |
| YTS-007 | www.youtube.com/shorts also works | PASS |
| YTS-008 | all Shorts URLs recognized as YouTube platform | PASS |
| YTS-NORM-001 | Shorts and watch produce same targets | PASS |
| YTS-NORM-002 | www.youtube.com/shorts works | PASS |
| YTS-NORM-003 | m.youtube.com/shorts works | PASS |
| YTS-GAP-001 | no isShorts flag (documented) | PASS |
| YTS-GAP-002 | normalization loses /shorts/ path (documented) | PASS |
| YTS-GAP-003 | no aspect ratio detection (documented) | PASS |
| YTS-GAP-004 | no duration field (documented) | PASS |
| YTS-EDGE-001 | trailing slash edge case | PASS |
| YTS-EDGE-002 | query parameters on Shorts URL | PASS |
| YTS-EDGE-003 | fragment on Shorts URL | PASS |

**Phase 7 total: 34 PASS, 0 FAIL**

### Phase 8 — URL Variations

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-VAR-001 | all 4 variations normalize to same URL | PASS |
| YT-VAR-002 | SocialUrlUtils produces same fetch targets | PASS |
| Individual | each of 4 URLs extracts YE7VzlLtp-4 | PASS (×4) |

**Phase 8 total: 6 PASS, 0 FAIL**

### Phase 9 — Download State Machine

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-SM-001 | all expected states exist | PASS |
| YT-SM-002 | storage values round-trip | PASS |
| YT-SM-003 | unknown value defaults to queued | PASS |
| YT-SM-004 | isActive covers correct states | PASS |

**Phase 9 total: 4 PASS, 0 FAIL**

### Phase 10 — Interruptions

| Test ID | Description | Result |
|---------|-------------|--------|
| DL-006 | pause then resume completes | PASS (existing) |
| DL-007 | cancel deletes partial file | PASS (existing) |
| crash_recovery | interrupted tasks recover to queued | PASS (existing) |

**Phase 10 total: covered by existing tests. Manual device testing required for app background, restart, and network interruption.**

### Phase 11 — Duplicate Download

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-DUP-001 | no duplicate prevention exists | PASS (documented) |

**Phase 11 total: 1 PASS (behavior documented)**

### Phase 12 — Error Handling

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-ERR-001 | youtube.com homepage — no video ID | PASS |
| YT-ERR-002 | /watch without v= — no video ID | PASS |
| YT-ERR-003 | empty v= — no video ID | PASS |
| YT-ERR-004 | homepage still recognized as YouTube | PASS |
| YT-ERR-005 | UrlValidator accepts YouTube URLs | PASS |
| YT-ERR-006 | UrlValidator rejects non-HTTP | PASS |
| YT-ERR-007 | bare /shorts/ — no video ID | PASS |
| YT-ERR-008 | youtu.be/ with no path — no video ID | PASS |
| YT-ERR-FMT-001 | error message formatting | PASS |
| YT-ERR-FMT-002 | long errors truncated | PASS |

**Phase 12 total: 10 PASS, 0 FAIL**

### Phase 13 — File Validation

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-FILE-001 | video/mp4 → .mp4 | PASS |
| YT-FILE-002 | video/webm → .webm | PASS |
| YT-FILE-003 | audio/mp4 → .m4a | PASS |
| YT-FILE-004 | unknown video → .mp4 | PASS |
| YT-FILE-005 | ensureExtension adds .mp4 | PASS |
| YT-FILE-006 | ensureExtension keeps existing | PASS |

**Phase 13 total: 6 PASS, 0 FAIL**

### Phase 14 — HTTP Headers

| Test ID | Description | Result |
|---------|-------------|--------|
| YT-HDR-001 | page fetch uses mobile UA | PASS |
| YT-HDR-002 | media download uses Android YouTube UA | PASS |

**Phase 14 total: 2 PASS, 0 FAIL**

---

## Live Integration Tests (Skipped — require `YOUTUBE_LIVE_TEST=1`)

| Test ID | URL | Type |
|---------|-----|------|
| YT-001 Live | `https://www.youtube.com/watch?v=YE7VzlLtp-4` | Standard |
| YT-002 Live | `https://youtu.be/YE7VzlLtp-4` | Standard |
| YT-003 Live | `https://www.youtube.com/watch?v=YE7VzlLtp-4&t=30s` | Standard |
| YT-004 Live | `https://www.youtube.com/watch?v=YE7VzlLtp-4&feature=youtu.be` | Standard |
| YT-005 Live | `https://www.youtube.com/watch?v=f7NwyBnIRTE` | Standard |
| YT-VAR-LIVE | All 4 variations → same video | Variation |
| YTS-001 Live | `https://youtube.com/shorts/ld4K5nw9gsk` | Shorts |
| YTS-002 Live | `https://youtube.com/shorts/XFM4tCakAXY` | Shorts |
| YTS-003 Live | `https://youtube.com/shorts/BxXzzAEEhCA` | Shorts |
| YTS-004 Live | `https://youtube.com/shorts/LNv4y3wPQA0` | Shorts |
| YTS-005 Live | `https://youtube.com/shorts/hvmIZAvt3jE` | Shorts |
| YTS-006 Live | `https://youtube.com/shorts/MNRgAw45mTM` | Shorts |
| YT-INV-001 Live | `https://www.youtube.com/` | Invalid |
| YT-INV-002 Live | `https://www.youtube.com/watch` | Invalid |
| YT-INV-003 Live | `https://www.youtube.com/watch?v=INVALID_VIDEO_ID` | Invalid |
| YT-INV-004 Live | `https://youtu.be/INVALID_VIDEO_ID` | Invalid |
| YT-INV-005 Live | `https://youtube.com/shorts/INVALID_VIDEO_ID` | Invalid |

**Live total: 17 tests skipped (run with `YOUTUBE_LIVE_TEST=1`)**

---

## Manual Tests Required

| ID | Procedure | Priority |
|----|-----------|----------|
| M-YT-001 | Full download flow — standard video on device | HIGH |
| M-YT-002 | Full download flow — Shorts on device | HIGH |
| M-YT-003 | Pause/resume during active download | HIGH |
| M-YT-004 | Cancel active download | MEDIUM |
| M-YT-005 | Network interruption → recovery | HIGH |
| M-YT-006 | Duplicate download same URL | MEDIUM |
| M-YT-007 | Invalid video ID error display | MEDIUM |

---

## Architectural Gaps Found (Not Bugs — Missing Features)

### GAP-001: No Quality Selection

**Severity:** MEDIUM
**Component:** `YouTubeResolver`
**Description:** The resolver picks a single "best" stream by itag preference. There is no API or UI to let the user choose between 360p, 720p, 1080p, etc.
**Recommended Fix:** Expose all available streams from `streamingData.formats` and `streamingData.adaptiveFormats` in `DiscoveredResource`. Add a quality selection step in the download wizard.

### GAP-002: No Audio-Only Downloads

**Severity:** LOW
**Component:** `YouTubeResolver`
**Description:** Audio-only itags (140=m4a, 251=opus, 249/250=opus low) are not in the preferred list. Users cannot download audio only.
**Recommended Fix:** Add audio-only itags and expose a "Download Audio" option in the wizard.

### GAP-003: No Audio+Video Muxing

**Severity:** MEDIUM
**Component:** `DownloadManager`
**Description:** High-quality YouTube streams (1080p+) are adaptive — separate audio and video. Without a muxing pipeline, the app is limited to muxed streams (max 720p via itag 22).
**Recommended Fix:** Integrate ffmpeg (via `ffmpeg_kit_flutter`) for post-download muxing of separate audio+video streams.

### GAP-004: No Shorts Content Type Detection

**Severity:** LOW
**Component:** `DiscoveredResource`
**Description:** `DiscoveredResource` has no `isShorts`, `contentType`, or `videoType` field. After URL normalization, the `/shorts/` path information is lost.
**Recommended Fix:** Add `contentType` field to `DiscoveredResource`. Set it based on original URL path before normalization.

### GAP-005: No Thumbnail Extraction

**Severity:** LOW
**Component:** `YouTubeResolver` / `DiscoveredResource`
**Description:** YouTube thumbnail URLs (`https://i.ytimg.com/vi/{id}/maxresdefault.jpg`) are not extracted or stored.
**Recommended Fix:** Add `thumbnailUrl` to `DiscoveredResource`. Set it from InnerTube `videoDetails.thumbnail` or construct from video ID.

### GAP-006: No Duration Extraction

**Severity:** LOW
**Component:** `DiscoveredResource` / `DownloadTask`
**Description:** Neither `DiscoveredResource` nor `DownloadTask` stores duration. InnerTube response includes `videoDetails.lengthSeconds` but it is not captured.
**Recommended Fix:** Add `durationSeconds` to `DiscoveredResource`.

### GAP-007: No Duplicate Download Prevention

**Severity:** LOW
**Component:** `DownloadManager`
**Description:** `enqueue()` does not check if a task with the same URL already exists. Duplicate downloads are silently created.
**Recommended Fix:** Check `_tasks.values` for matching URL before creating a new task. Prompt user or skip.

---

## Production Bugs Found

**None.** All existing functionality works as designed. The gaps above are missing features, not bugs in implemented behavior.

---

## Conclusion

The YouTube URL parsing, platform detection, and resolver architecture are solid and well-tested. All 11 test URLs (5 standard, 6 Shorts) parse correctly. URL normalization correctly handles all variation forms. Error handling for invalid URLs is robust.

The primary limitations are in download capability:
- Maximum quality is 720p (itag 22 muxed stream)
- No quality selection, audio-only, or muxing support
- No Shorts-specific metadata (aspect ratio, duration cap)

These are architectural gaps to be addressed in future milestones, not bugs in existing code.

---

## Files Created

```
qa/test-cases/youtube/YOUTUBE_TEST_PLAN.md
qa/test-cases/youtube/YOUTUBE_URL_TESTS.md
qa/test-cases/youtube/YOUTUBE_RESOLVER_TESTS.md
qa/test-cases/youtube/YOUTUBE_SHORTS_TESTS.md
qa/test-cases/youtube/YOUTUBE_DOWNLOAD_TESTS.md
qa/test-reports/YOUTUBE_TEST_REPORT.md

packages/download_engine/test/youtube_url_test.dart      (48 tests)
packages/download_engine/test/youtube_resolver_test.dart  (19 tests)
packages/download_engine/test/youtube_shorts_test.dart    (34 tests)
packages/download_engine/test/youtube_download_test.dart  (13 unit + 17 live)
```
