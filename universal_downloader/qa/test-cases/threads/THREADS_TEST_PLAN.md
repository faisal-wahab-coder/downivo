# Threads Integration Test Plan

**Platform:** Threads (Profile, Post, Image, Video, Carousel, Quote, Repost, Share/Embed)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection (`threads.net`, `threads.com`, share hosts)
2. Profile / post ID / username extraction
3. Content type classification
4. URL normalization and duplicate identity
5. Image, video, carousel, multi-media extraction
6. Text-only, quote, and repost handling
7. Restricted / authentication / unavailable handling (no bypass)
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn, Telegram, Snapchat

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → ThreadsResolver
  ├── ThreadsUri.classifyUrl()
  ├── ThreadsUri.normalize() / contentIdentity()
  ├── Public OG / JSON CDN URLs
  └── carousel_media / video_versions / image_versions2
  ↓
DiscoveredResource[] → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, profile, login, invalid) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL / HTML | Downloadable? |
|------|------------|----------------|
| Home | `https://www.threads.net/` | No |
| Profile | `/@{user}` | No |
| Post | `/@user/post/{id}`, `/t/{id}` | Yes, if public media exposed |
| Embed | `/post/{id}/embed` | Yes if underlying media public |
| Share | tracking params / `l.threads.net` | Yes after normalize |
| Text-only | resolved HTML | No — NO_DOWNLOADABLE_MEDIA |
| Login | `/login` | No — AUTHENTICATION_REQUIRED |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `threads_url_test.dart` | 28 | Detection, classification, IDs, normalize, identity |
| `threads_resolver_test.dart` | 10 | HTML, registry, naming, text-only |
| `threads_profile_test.dart` | 5 | Profile not downloaded |
| `threads_post_test.dart` | 6 | Text / quote / repost |
| `threads_image_test.dart` | 5 | Image, MIME, dimensions |
| `threads_video_test.dart` | 5 | MP4, skip HLS |
| `threads_carousel_test.dart` | 5 | Count, order, filenames |
| `threads_metadata_test.dart` | 7 | Author, caption, MIME, date |
| `threads_thumbnail_test.dart` | 4 | Thumbnail + failure |
| `threads_download_test.dart` | 10 | State machine |
| `threads_auth_test.dart` | 6 | Login wall |
| `threads_restriction_test.dart` | 5 | Private / unavailable |
| `threads_error_test.dart` | 16 | HTTP 403–503, messages |
| `threads_security_test.dart` | 21 | Schemes, private IPs, filenames |
| `threads_performance_test.dart` | 5 | Large carousel, identity |

---

## Security

Never bypass authentication, private profiles, private posts, DRM, or platform access controls. Never use stolen sessions, cookies, or tokens. Only public HTML/OG/embed data is parsed.
