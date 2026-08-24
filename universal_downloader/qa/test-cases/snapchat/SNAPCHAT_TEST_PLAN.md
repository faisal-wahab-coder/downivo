# Snapchat Integration Test Plan

**Platform:** Snapchat (Public Profile, Spotlight, Public Story, Saved Story, Snap, Share/Embed/Deep Links)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition (`snapchat.com`, `t.snapchat.com`, `story.snapchat.com`, `snapchat://`, CDN)
2. Profile / Spotlight / Story / Snap ID extraction
3. Content type classification
4. URL normalization and duplicate identity
5. Photo, video, multi-snap Story extraction
6. Share (`t.snapchat.com`, `/t/`) and embed URLs
7. Restricted / authentication / expiration handling (no bypass)
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn, Telegram

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → SnapchatResolver
  ├── SnapchatUri.classifyUrl()
  ├── SnapchatUri.normalize() / contentIdentity()
  ├── snapchat://spotlight → https://www.snapchat.com/spotlight/{id}
  ├── Public OG / <video> / JSON CDN URLs
  └── Direct sc-cdn.net URLs
  ↓
DiscoveredResource[] → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, profile, feed, private, login) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://www.snapchat.com/` | No |
| Public profile | `/add/{user}`, `/@{user}`, `/p/{id}` | No |
| Spotlight feed | `/spotlight` | No |
| Spotlight | `/spotlight/{id}` | Yes, if MP4 exposed |
| Public Story | `story.snapchat.com/s/{user}` | Yes, if media exposed |
| Saved Story | `/p/{id}/highlights/{id}` | Yes, if media exposed |
| Snap | `/snap/{id}` | Yes, if media exposed |
| Share | `t.snapchat.com/{code}` | Yes after resolve |
| Embed | `/embed/{id}` | Yes if underlying media public |
| Chat / Memories | `/chat`, `/memories` | No — RESTRICTED |
| Login | `/login` | No — AUTHENTICATION_REQUIRED |
| Direct media | `*.sc-cdn.net/...` | Yes |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `snapchat_url_test.dart` | 40 | Detection, classification, IDs, normalize, identity |
| `snapchat_resolver_test.dart` | 10 | HTML, registry, naming |
| `snapchat_profile_test.dart` | 5 | Profile not downloaded |
| `snapchat_spotlight_test.dart` | 6 | Spotlight video metadata |
| `snapchat_story_test.dart` | 6 | Count, order, filenames |
| `snapchat_photo_test.dart` | 5 | Photo, MIME, dimensions |
| `snapchat_video_test.dart` | 6 | MP4, `<source src>`, skip HLS |
| `snapchat_metadata_test.dart` | 5 | Creator, caption, MIME |
| `snapchat_download_test.dart` | 10 | State machine |
| `snapchat_error_test.dart` | 21 | HTTP 403–503, formatter, HLS |
| `snapchat_security_test.dart` | 21 | Schemes, private IPs, filenames |
| `snapchat_performance_test.dart` | 5 | 50-snap story parse |
| `snapchat_auth_test.dart` | 7 | Login / auth wall |
| `snapchat_restriction_test.dart` | 6 | Chat / Memories / private HTML |
| `snapchat_expiration_test.dart` | 4 | Expired Snaps |
| **Total Snapchat** | **157** | |

---

## Security rules

- Never bypass Snapchat authentication
- Never access private Stories or friends-only content
- Never use stolen sessions, cookies, or tokens
- Never circumvent disappearing-content protections or DRM
- Never invent live Snapchat URLs for manual tests
