# Pinterest Integration Test Plan

**Platform:** Pinterest (Pins, Idea Pins, Images, Videos, Boards, Profiles, Share/Short URLs, Direct Media)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition
2. Pin ID extraction (slug ignored)
3. Content type classification (home, pin, board, profile, short, direct media, search)
4. URL normalization and duplicate identity
5. Image, video, Idea Pin, mixed-media extraction
6. Direct `i.pinimg.com` / `v1.pinimg.com` URLs
7. Short (`pin.it`) and share (`/sent/`) URLs
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → PinterestResolver
  ├── PinterestUri.classifyUrl()
  ├── PinterestUri.normalize()
  ├── pin.it → SocialUrlResolver.resolveRedirects()
  ├── HTML __PWS_DATA__ / JSON-LD / OpenGraph
  ├── pidgets + oEmbed fallback
  └── originals upgrade for pinimg stills
  ↓
DiscoveredResource[] → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, board, profile, search) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://www.pinterest.com/` | No |
| Pin | `/pin/{id}/` or `/pin/{id}/{slug}/` | Yes, if media |
| Idea Pin | same `/pin/{id}/` + `story_pin_data` | Yes, all pages |
| Board | `/{user}/{board}/` | No (not bulk) |
| Profile | `/{user}/` | No |
| Short | `https://pin.it/{code}` | Yes after redirect |
| Direct media | `i.pinimg.com`, `v1.pinimg.com` | Yes |
| Search / ideas hub | `/search/`, `/ideas/` | No |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `pinterest_url_test.dart` | 56 | Detection, classification, IDs, normalize, identity |
| `pinterest_resolver_test.dart` | 13 | PWS/HTML, pidgets, oEmbed, registry, naming |
| `pinterest_image_test.dart` | 7 | Orig PNG/WebP/JPEG, no 736x substitute |
| `pinterest_video_test.dart` | 8 | Best MP4, skip HLS, duration |
| `pinterest_idea_pin_test.dart` | 7 | Count, order, mixed MIME |
| `pinterest_multi_media_test.dart` | 6 | Dedupe, filenames, registry |
| `pinterest_metadata_test.dart` | 8 | Pin ID, author, MIME, dimensions |
| `pinterest_download_test.dart` | 13 | State machine, idea-pin item states |
| `pinterest_error_test.dart` | 18 | HTTP 403–503, formatter |
| `pinterest_security_test.dart` | 18 | Schemes, private IPs, filenames |
| `pinterest_performance_test.dart` | 4 | 50-page idea pin parse |
| **Total Pinterest** | **158** | |

---

## Run Commands

```bash
cd downivo/packages/download_engine
flutter test test/pinterest_url_test.dart test/pinterest_resolver_test.dart \
  test/pinterest_image_test.dart test/pinterest_video_test.dart \
  test/pinterest_idea_pin_test.dart test/pinterest_multi_media_test.dart \
  test/pinterest_metadata_test.dart test/pinterest_download_test.dart \
  test/pinterest_error_test.dart test/pinterest_security_test.dart \
  test/pinterest_performance_test.dart
flutter test   # full engine regression
```

Live discovery (optional):

```bash
SOCIAL_LIVE_TEST=1 flutter test test/social_live_discovery_test.dart
```

---

## Manual Tests

Do **not** invent pin IDs. Copy links from Pinterest → Share → Copy link.

### PT-001 — Pinterest Home

URL: `https://www.pinterest.com/`

Expected: Platform=PINTEREST, Content=HOME, **no download**.

### PT-002 — Public image Pin

Obtain: public image → Share → Copy link.

Store exact URL as PT-002. Test detection, original image MIME, thumbnail, download, library.

### PT-003 — Second image Pin

Different aspect ratio. Store as PT-003.

### PT-004 — Public video Pin

Store as PT-004. Test MP4 (not m3u8), thumbnail, playback, audio if present in the MP4.

### PT-005 — Idea Pin / multi-media

Store as PT-005. Test media count, order, individual states.

### PT-006 — Mobile share (P0)

Pinterest app → Open Pin → Share → Copy link → Downivo.

Store the exact copied URL.

### PT-007 — Board

Public board URL. Expected: Board detection, **no bulk download**.

### PT-008 — Profile

Public profile URL. Expected: Profile detection, **no download**.

### PT-009 — URL variation

Same pin via canonical, share, mobile, query params → same `pinterest:pin:{id}`.

### PT-010 — Invalid pin

`https://www.pinterest.com/pin/INVALID/` → clean error, no crash.
