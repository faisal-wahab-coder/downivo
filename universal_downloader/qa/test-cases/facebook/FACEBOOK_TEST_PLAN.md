# Facebook Integration Test Plan

**Platform:** Facebook (Videos, Reels, Photos, Multi-Photo Posts, Pages, Share URLs)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

This test plan covers all Facebook-related functionality in UniversalDownloader:

1. URL detection and platform recognition
2. Content ID extraction (video ID, reel ID, photo ID, post ID)
3. Content type classification (Video, Reel, Photo, Page, Home)
4. URL normalization (tracking param stripping, canonical host)
5. Fetch targets (desktop, mobile, mbasic variants)
6. Facebook resolver (structured JSON + OpenGraph fallback)
7. Video extraction (playable_url, browser_native, CDN patterns)
8. Reel extraction (same flow as video, /reel/ URL detection)
9. Photo extraction (og:image, structured data)
10. Multi-photo post support (discoverAll)
11. Download state machine (queued → completed lifecycle)
12. File naming and validation
13. Thumbnail extraction
14. Error handling (HTTP errors, missing content, malformed HTML)
15. Security (unsafe schemes, private IPs, filename sanitization)
16. Duplicate detection via URL normalization
17. Regression against YouTube, TikTok, Instagram

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
PlatformSocialResolver.discover(pageUrl, SocialPlatform.facebook)
  ↓
FacebookResolver.discover(pageUrl)
  ├── classifyUrl(pageUrl)                    # Video, Reel, Photo, Page, Home
  ├── _resolveUrl(pageUrl)                    # fb.watch redirect resolution
  ├── _buildTargets(resolved, original)       # desktop, mobile, mbasic
  ├── _fetchPage(target)                      # HTTP fetch + cookie extraction
  ├── _extractFromStructuredData()            # JSON: playable_url, browser_native
  └── _extractFromOpenGraph()                 # og:video, og:image fallback
  ↓
DiscoveredResource(directUrl, fileName, platform, ...)
  ↓
Download Engine → Queue → Storage → Database → Media Library
```

### Key Components

| Component | File | Function |
|-----------|------|----------|
| Platform detection | `social_platform.dart` | `SocialPlatform.fromUri()` — matches `facebook.com`, `fb.watch`, `*.facebook.com` |
| Content ID | `social_url_utils.dart` | `FacebookUri.contentIdFromUri()` — extracts from `/watch/?v=`, `/reel/`, `/photo/?fbid=`, etc. |
| Content classification | `facebook_resolver.dart` | `classifyUrl()` — Video, Reel, Photo, Page, Home, Unknown |
| URL normalization | `social_url_utils.dart` | `FacebookUri.normalize()` — strips tracking params, ensures canonical host |
| Resolver | `facebook_resolver.dart` | `discover()` / `discoverAll()` — JSON + OG extraction |
| Fetch targets | `social_url_utils.dart` | `_facebookTargets()` — desktop + mobile + mbasic |
| Video extraction | `facebook_resolver.dart` | `_extractVideoUrlsFromJson()` — playable_url_quality_hd/sd, browser_native |
| Photo extraction | `facebook_resolver.dart` | `_extractFromOpenGraph()` — og:image fallback |
| HTTP headers | `social_http_headers.dart` | Facebook Origin/Referer for page fetch and CDN download |
| File naming | `media_extractor.dart` | `buildFileNameForSocial()` — CDN basename or caption slug |
| Error formatting | `download_error_formatter.dart` | HTTP 403/404/429/5xx → user messages |
| Registry integration | `platform_social_resolver.dart` | Facebook wired into `discover()` and `discoverAll()` |

### Content Types Supported

| Content Type | URL Patterns | Status |
|-------------|-------------|--------|
| Video | `/watch/?v=`, `/<page>/videos/<id>/`, `/video.php?v=` | IMPLEMENTED |
| Reel | `/reel/<id>/`, `/reels/<id>/` | IMPLEMENTED |
| Photo | `/photo/?fbid=`, `/photo.php?fbid=`, `/<page>/photos/` | IMPLEMENTED |
| Multi-Photo | Same as Photo (via `discoverAll`) | IMPLEMENTED |
| Share/Short URL | `fb.watch/<shortcode>` | IMPLEMENTED (redirect resolution) |
| Page | `/<pagename>/` | DETECTED — returns empty (not downloadable) |
| Home | `/` | DETECTED — returns empty (not downloadable) |

### Platform Limitations

| Feature | Status |
|---------|--------|
| Private/restricted content | PLATFORM_LIMITATION — requires authentication |
| Audio-only download | NOT_SUPPORTED — platform does not expose separate audio tracks |
| Video quality selection | PARTIALLY_SUPPORTED — uses best available from resolved data |
| Live streams | NOT_SUPPORTED — real-time stream capture out of scope |

---

## Test Files

| Test File | Type | Tests | Coverage |
|-----------|------|-------|----------|
| `facebook_url_test.dart` | Unit | 68 | Platform detection, content ID, classification, normalization, security |
| `facebook_resolver_test.dart` | Unit | 23 | JSON extraction, OG fallback, error handling, file naming, thumbnails |
| `facebook_video_test.dart` | Unit | 11 | Video URL patterns, CDN detection, HD/SD preference, MIME types |
| `facebook_reel_test.dart` | Unit | 13 | Reel URL detection, reel ID extraction, reel resolution |
| `facebook_photo_test.dart` | Unit | 12 | Photo URL detection, image extraction, MIME handling |
| `facebook_multi_media_test.dart` | Unit | 7 | Multi-photo extraction, ordering, registry integration |
| `facebook_download_test.dart` | Unit | 23 | State machine, task properties, file naming, status storage |
| `facebook_error_test.dart` | Unit | 20 | HTTP errors, content errors, error formatting |
| `facebook_security_test.dart` | Unit | 24 | Unsafe schemes, private IPs, filename sanitization |

---

## Manual Test Cases

### FB-001 — Facebook Home
URL: `https://www.facebook.com/`
Expected: Platform=FACEBOOK, Content=HOME, no download

### FB-002 — Facebook Official Page
URL: `https://www.facebook.com/facebook/`
Expected: Platform=FACEBOOK, Content=PAGE, no download

### FB-003 — Public Facebook Video
Obtain: Open public video → Share → Copy link
Test: Detection → Video resolution → Metadata → Download

### FB-004 — Facebook Reel
Obtain: Open public Reel → Share → Copy link
Expected URL: `https://www.facebook.com/reel/<REEL_ID>/`
Test: Reel detection → Video → Download

### FB-005 — Facebook Photo Post
Obtain: Open public photo → Share → Copy link
Test: Photo detection → Image → Download

### FB-006 — Facebook Multi-Photo Post
Obtain: Share multi-photo public post
Test: Media count → Ordering → Individual downloads

### FB-007 — Facebook Mobile Share URL
Device: Physical mobile
Test: Copy from Facebook app → Paste → Resolve → Download

### FB-008 — Facebook Query Parameters
Test: Working URL with/without tracking params → Same content
