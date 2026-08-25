# LinkedIn Integration Test Plan

**Platform:** LinkedIn (Posts, Images, Videos, Documents, Articles, Profiles, Companies, Share/Short URLs)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition
2. Post / activity ID extraction (slug ignored)
3. Content type classification (home, feed, post, video, article, profile, company, short, direct media)
4. URL normalization and duplicate identity
5. Image, video, multi-image, document extraction
6. Direct `media.licdn.com` / `dms.licdn.com` URLs
7. Short (`lnkd.in`) and share URLs
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → LinkedInResolver
  ├── LinkedInUri.classifyUrl()
  ├── LinkedInUri.normalize() / contentIdentity()
  ├── lnkd.in → SocialUrlResolver.resolveRedirects()
  ├── HTML progressiveStreams / JSON-LD / OpenGraph
  └── Direct licdn CDN URLs
  ↓
DiscoveredResource[] → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, feed, profile, company, article) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://www.linkedin.com/` | No |
| Feed | `/feed/` | No |
| Post | `/posts/...` or `/feed/update/urn:li:activity:{id}` | Yes, if media exposed |
| Video | `/video/...` or post with progressive MP4 | Yes, if MP4 exposed |
| Article | `/pulse/...` | No |
| Profile | `/in/{slug}/` | No |
| Company | `/company/{slug}/` | No |
| Short | `https://lnkd.in/{code}` | Yes after redirect |
| Direct media | `media.licdn.com`, `dms.licdn.com` | Yes |
| Embed | `/embed/feed/update/urn:li:...` | Yes, if media |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `linkedin_url_test.dart` | 37 | Detection, classification, IDs, normalize, identity |
| `linkedin_resolver_test.dart` | 13 | HTML, redirect, registry, naming |
| `linkedin_post_test.dart` | 5 | POST, text-only, auth wall, identity |
| `linkedin_image_test.dart` | 5 | DMS image, shrink, MIME, skip logos |
| `linkedin_video_test.dart` | 6 | Best MP4, skip HLS, no invented 1080p |
| `linkedin_multi_media_test.dart` | 6 | Count, order, dedupe, filenames |
| `linkedin_document_test.dart` | 3 | PDF discovery and MIME |
| `linkedin_metadata_test.dart` | 7 | Author, duration, title, MIME |
| `linkedin_download_test.dart` | 10 | State machine, item states |
| `linkedin_error_test.dart` | 20 | HTTP 403–503, formatter |
| `linkedin_security_test.dart` | 19 | Schemes, private IPs, filenames |
| `linkedin_performance_test.dart` | 5 | 50-image carousel parse |
| **Total LinkedIn** | **136** | |

---

## Manual P0

LI-010 — On mobile: LinkedIn → Open Post → Share → Copy link → Downivo.

Store the exact copied URL. Do not invent post IDs.

---

## Security

Do not bypass LinkedIn login, privacy, DRM, or access controls. Do not use stolen cookies or unauthorized credentials.
