# Instagram Test Report

**Platform:** Instagram
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Runner:** Flutter Test (flutter_test SDK)

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tests** | 168 |
| **Passed** | 168 |
| **Failed** | 0 |
| **Skipped** | 0 |
| **Blocked** | 0 |
| **Manual Tests Required** | 10 |

---

## Implementation Changes

This test cycle included both **implementation** and **testing**:

| Change | Type | Impact |
|--------|------|--------|
| Added `_bestImageUrl()` method | NEW FEATURE | Instagram photo posts now downloadable |
| Added `_parseCarouselFirstMedia()` method | NEW FEATURE | Carousel posts return first media item |
| Updated `_parsePayload()` to fall through to images | ENHANCEMENT | Video → Image fallback chain |
| Updated `_parseLegacyShortcodeMedia()` for images | ENHANCEMENT | Legacy API image support |
| Added `instagram_photo_test.dart` | NEW TESTS | 12 photo-specific tests |
| Updated carousel/post tests for new behavior | TEST UPDATE | Tests reflect correct implementation |

---

## Test Files

| File | Tests | Status |
|------|-------|--------|
| `instagram_url_test.dart` | 52 | ALL PASS |
| `instagram_resolver_test.dart` | 27 | ALL PASS |
| `instagram_reel_test.dart` | 18 | ALL PASS |
| `instagram_post_test.dart` | 15 | ALL PASS |
| `instagram_photo_test.dart` | 12 | ALL PASS |
| `instagram_carousel_test.dart` | 5 | ALL PASS |
| `instagram_story_test.dart` | 9 | ALL PASS |
| `instagram_error_test.dart` | 30 | ALL PASS |

---

## Phase Results

| Phase | Description | Result |
|-------|-------------|--------|
| 1 | Platform detection | PASS |
| 2 | URL normalization & embed targets | PASS |
| 3 | GraphQL payload parsing (video + image) | PASS |
| 4 | Photo post extraction | PASS |
| 5 | Video quality selection | PASS |
| 6 | Carousel handling | PASS |
| 7 | Reel-specific tests | PASS |
| 8 | HTML fallback extraction | PASS |
| 9 | Post-specific tests | PASS |
| 10 | Story handling (graceful limitation) | PASS |
| 11 | Legacy format support | PASS |
| 12 | Caption extraction | PASS |
| 13 | Filename generation | PASS |
| 14 | Private content handling | PASS |
| 15 | Deleted/unavailable content | PASS |
| 16 | Invalid URLs | PASS |
| 17 | Security (unsafe protocols) | PASS |
| 18 | URL validation | PASS |

---

## Full Regression Results

| Suite | Tests | Result |
|-------|-------|--------|
| download_engine (all tests) | 486 pass, 26 skipped | ALL PASS |
| YouTube URL tests | 108 pass | ALL PASS |
| TikTok URL tests | 108 pass | ALL PASS |
| Instagram tests | 168 pass | ALL PASS |
| Integration/lifecycle tests | 14 pass | ALL PASS |
| Security tests | pass | ALL PASS |

---

## Features Verified Working

| Feature | Content Types | Evidence |
|---------|--------------|----------|
| URL detection | Reels, Posts, IGTV, Stories, Profiles | IG-URL-001 to IG-URL-010 |
| Shortcode extraction | /reel/, /p/, /tv/ | IG-SC-001 to IG-SC-012 |
| Query param stripping | utm_source, igsh, etc. | IG-NORM-001 to IG-NORM-008 |
| Video download | Reels, video posts, IGTV | IG-GQL-001, IG-QUAL-001 to 003 |
| **Photo download** | Image posts, legacy format | IG-PHOTO-001 to IG-PHOTO-007 |
| **Carousel download** | First item (video or image) | IG-CAR-ITEMS-001 to 003 |
| Embed URL fallback | All /reel/, /p/, /tv/ | IG-EMBED-001 to IG-EMBED-005 |
| HTML fallback | video_url, og:video, CDN regex | IG-HTML-001 to IG-HTML-005 |
| Security | javascript:, file:, data:, localhost | IG-SEC-001 to IG-SEC-008 |
| Error handling | Invalid, deleted, private, restricted | IG-DEL, IG-PRIV, IG-INV, IG-ERR |

---

## Known Limitations

| Limitation | Classification | Reason |
|------------|----------------|--------|
| Stories not downloadable | PLATFORM LIMITATION | Requires authentication (docs §23 forbids bypass) |
| Profile not downloadable | EXPECTED BEHAVIOR | Not a media URL |
| Carousel downloads first item only | DESIGN DECISION | `supportsMultipleResources` is optional per docs |
| Audio-only not supported | NOT REQUIRED | Documentation does not require it |
| Quality selection not exposed | NOT REQUIRED | Always selects best quality |

---

## Manual Tests Required

| ID | Description | Status |
|----|-------------|--------|
| M-IG-001 | Public Reel download end-to-end | PENDING |
| M-IG-002 | Public video post download | PENDING |
| M-IG-003 | Public photo post download | PENDING |
| M-IG-004 | Profile URL rejection (no crash) | PENDING |
| M-IG-005 | Private content graceful failure | PENDING |
| M-IG-006 | Mobile copy-link (igsh param) end-to-end | PENDING |
| M-IG-007 | Pause/resume during download | PENDING |
| M-IG-008 | Duplicate download behavior | PENDING |
| M-IG-009 | Story URL graceful failure | PENDING |
| M-IG-010 | Carousel post (first item download) | PENDING |

---

## Run Commands

```bash
# All Instagram tests
cd downivo/packages/download_engine && \
flutter test \
  test/instagram_url_test.dart \
  test/instagram_resolver_test.dart \
  test/instagram_reel_test.dart \
  test/instagram_post_test.dart \
  test/instagram_photo_test.dart \
  test/instagram_carousel_test.dart \
  test/instagram_story_test.dart \
  test/instagram_error_test.dart

# Full download_engine regression
flutter test

# Cross-platform regression (YouTube + TikTok + Instagram)
flutter test test/youtube_url_test.dart test/tiktok_url_test.dart \
  test/instagram_url_test.dart test/instagram_photo_test.dart
```

---

## Conclusion

The Instagram integration is **COMPLETE** for all documented requirements:

1. **Photo posts** — NEW: now fully supported (was missing)
2. **Video posts** — working (reels, IGTV, feed videos)
3. **Carousel posts** — NEW: downloads first media item (video preferred, then image)
4. **URL normalization** — working (deduplication via canonical URL)
5. **Security** — verified (all unsafe protocols rejected)
6. **Error handling** — verified (graceful failures, no crashes)
7. **Stories** — documented platform limitation (requires auth, ToS constraint)

No production bugs found. No test failures. Full regression passes across all platforms.
