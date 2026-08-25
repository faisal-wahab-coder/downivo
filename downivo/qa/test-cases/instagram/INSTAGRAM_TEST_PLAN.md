# Instagram Integration Test Plan

**Platform:** Instagram (Reels, Posts, IGTV, Carousels, Stories, Profiles)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

This test plan covers all Instagram-related functionality in Downivo:

1. URL detection and platform recognition
2. Shortcode (Post ID / Reel ID) extraction from URLs
3. Content type classification (Reel, Post, IGTV, Story, Profile)
4. URL normalization and deduplication
5. Embed URL generation
6. Metadata extraction via GraphQL resolver
7. HTML fallback extraction (og:video, cdninstagram.com, fbcdn.net)
8. Video download (Reels, video posts, IGTV)
9. Download state machine transitions
10. Interruption handling (pause/resume/cancel)
11. Duplicate download behavior
12. Error handling for invalid/private/deleted content
13. File naming and validation
14. Security (malformed URLs, injection, unsafe protocols)
15. Regression test automation

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
PlatformSocialResolver.discover(pageUrl, SocialPlatform.instagram)
  ↓
InstagramGraphqlResolver.discover(pageUrl)
  ├── shortcodeFromUri(pageUrl)             # /reel/, /p/, /tv/ → shortcode
  ├── canonicalPageUrl(pageUrl, shortcode)   # normalize to canonical form
  ├── _loadSession(canonical)               # fetch page → extract CSRF/LSD/cookies
  ├── _queryGraphql(...)                    # POST to /graphql/query/
  └── _parsePayload(...)                    # video_versions → best quality URL
  ↓ (if null)
SocialUrlUtils.fetchTargets()               # embed URL fallback
  ↓
MediaExtractor.extract()                    # og:video, cdninstagram.com regex
```

### Key Components

| Component | File | Function |
|-----------|------|----------|
| Platform detection | `social_platform.dart` | `SocialPlatform.fromUri()` — matches `instagram.com` or `*.instagram.com` |
| Shortcode extraction | `instagram_graphql_resolver.dart` | `shortcodeFromUri()` — regex `/(reel\|p\|tv)/([^/?#]+)` |
| Canonical URL | `instagram_graphql_resolver.dart` | `canonicalPageUrl()` — strips query params, normalizes path |
| GraphQL resolver | `instagram_graphql_resolver.dart` | `discover()` — session + GraphQL → video URL |
| Payload parsing | `instagram_graphql_resolver.dart` | `_parsePayload()` — video_versions best width |
| Embed targets | `social_url_utils.dart` | `_instagramTargets()` / `_instagramEmbedUri()` |
| HTML extraction | `media_extractor.dart` | `_extractInstagramVideo()` — video_url, contentUrl, CDN regex |
| HTTP headers | `social_http_headers.dart` | Instagram Origin/Referer for page fetch and CDN download |
| CDN detection | `download_detector.dart` | `isSocialCdnUrl()` — recognizes `cdninstagram.com` |
| File naming | `media_extractor.dart` | `buildFileNameForSocial()` — CDN basename or caption slug |

### What Is NOT Implemented

| Feature | Status |
|---------|--------|
| Stories (`/stories/`) | NOT SUPPORTED — shortcodeFromUri only matches `/reel/`, `/p/`, `/tv/` |
| Carousels (multi-item posts) | NOT SUPPORTED — only `items.first` used, video only |
| Image-only posts | NOT SUPPORTED — requires `video_url`/`video_versions`, no image fallback |
| Profile page downloads | NOT SUPPORTED — no shortcode extractable from `/<username>/` |
| Content type enum | NOT AVAILABLE — `DiscoveredResource` has no content type field |
| Audio-only download | NOT SUPPORTED — only full video download |
| Quality selection | NOT SUPPORTED — always selects highest width from video_versions |
| Carousel individual item selection | NOT SUPPORTED |

---

## Test Data

### Deterministic Fixtures (Unit Tests)

| ID | URL Pattern | Expected Shortcode | Content Kind |
|----|-------------|-------------------|--------------|
| IG-FIX-001 | `/reel/ABC123/` | `ABC123` | reel |
| IG-FIX-002 | `/p/XYZ789/` | `XYZ789` | p (post) |
| IG-FIX-003 | `/tv/DEF456/` | `DEF456` | tv (IGTV) |
| IG-FIX-004 | `/reel/ABC123/?utm_source=ig_web_copy_link` | `ABC123` | reel |
| IG-FIX-005 | `/reel/ABC123/?igsh=someParam` | `ABC123` | reel |
| IG-FIX-006 | `/stories/username/12345/` | null | story (unsupported) |
| IG-FIX-007 | `/instagram/` (profile) | null | profile (unsupported) |

### Live Integration (Env-Gated)

Live tests require `INSTAGRAM_LIVE_TEST=1` environment variable.

---

## Test Files

| File | Coverage |
|------|----------|
| `instagram_url_test.dart` | URL parsing, platform detection, shortcode extraction, normalization, embed targets, invalid URLs |
| `instagram_resolver_test.dart` | GraphQL payload parsing, session extraction, video_versions selection, filename generation |
| `instagram_reel_test.dart` | Reel-specific URL patterns, embed generation, canonical URL |
| `instagram_post_test.dart` | Post URL patterns, video/image distinction, IGTV paths |
| `instagram_carousel_test.dart` | Multi-item post handling (current limitation documentation) |
| `instagram_story_test.dart` | Story URL detection (current limitation documentation) |
| `instagram_error_test.dart` | Invalid URLs, security, private content, deleted content |

---

## Run Commands

```bash
# All Instagram tests
flutter test packages/download_engine/test/instagram_url_test.dart \
  packages/download_engine/test/instagram_resolver_test.dart \
  packages/download_engine/test/instagram_reel_test.dart \
  packages/download_engine/test/instagram_post_test.dart \
  packages/download_engine/test/instagram_carousel_test.dart \
  packages/download_engine/test/instagram_story_test.dart \
  packages/download_engine/test/instagram_error_test.dart

# URL parsing only
flutter test packages/download_engine/test/instagram_url_test.dart

# Resolver/payload only
flutter test packages/download_engine/test/instagram_resolver_test.dart

# Error/security only
flutter test packages/download_engine/test/instagram_error_test.dart

# Live integration (requires network + env var)
INSTAGRAM_LIVE_TEST=1 flutter test packages/download_engine/test/instagram_url_test.dart
```

---

## Manual Test Procedures

### M-IG-001 — Public Reel Download

1. Copy link from a public Instagram Reel (Share → Copy link)
2. Paste URL into Downivo
3. Verify Instagram platform detected
4. Verify Reel content type recognized
5. Verify metadata extracted (thumbnail, duration if shown)
6. Start download
7. Verify download completes
8. Verify file plays correctly
9. Verify database record created
10. Verify file appears in Media Library

### M-IG-002 — Public Video Post Download

1. Copy link from a public Instagram video post
2. Paste URL into Downivo
3. Verify Instagram platform detected
4. Verify video detected (not treated as image)
5. Start download
6. Verify file is video (.mp4)
7. Verify playback with audio

### M-IG-003 — Profile URL Rejection

1. Copy a profile URL (`https://www.instagram.com/instagram/`)
2. Paste into Downivo
3. Verify no download starts
4. Verify meaningful error/feedback
5. Verify no crash

### M-IG-004 — Private Content Handling

1. Obtain URL to a private Instagram post
2. Paste into Downivo
3. Verify graceful failure
4. Verify no crash, no infinite retry
5. Verify correct error messaging

### M-IG-005 — Deleted/Unavailable Content

1. Use URL with invalid/deleted shortcode
2. Paste into Downivo
3. Verify meaningful error
4. Verify download state finalized correctly

### M-IG-006 — Mobile Copy-Link Test

1. On mobile device: Instagram → Reel → Share → Copy link
2. Paste exact copied URL into Downivo
3. Verify URL processed correctly (including igsh params)
4. Verify download works end-to-end

### M-IG-007 — Pause/Resume During Download

1. Start Reel download
2. Pause download mid-progress
3. Resume download
4. Verify completion
5. Verify file integrity

### M-IG-008 — Duplicate Download

1. Download a Reel
2. Attempt same download again
3. Verify application's duplicate behavior
4. Verify no corruption of first download

### M-IG-009 — Story URL (Unsupported)

1. Obtain a Story URL (`/stories/<username>/<id>/`)
2. Paste into Downivo
3. Verify graceful failure (stories not supported)
4. Verify no crash

### M-IG-010 — Carousel Post (Unsupported)

1. Obtain a carousel post URL
2. Paste into Downivo
3. Verify behavior: if first item is video, may download; if all images, should fail gracefully
4. Verify no crash

---

## Per-URL Manual Checklist

For every real Instagram URL tested:

1. Paste URL
2. Detect Instagram platform
3. Detect content type (reel/post/tv)
4. Resolve shortcode
5. Display metadata (if available)
6. Display thumbnail (if available)
7. Display duration (if available)
8. Display available formats (if available)
9. Select download
10. Start download
11. Observe progress
12. Pause
13. Resume
14. Complete
15. Open resulting file
16. Verify media plays
17. Verify audio present
18. Verify resolution reasonable
19. Verify file size reasonable
20. Check Downloads database
21. Check Media Library
22. Check notification
23. Repeat download → verify duplicate behavior
24. Verify no orphan temp files on failure
