# Telegram Integration Test Plan

**Platform:** Telegram (Channels, Messages, Photos, Videos, Audio, Voice, Documents, GIFs, Albums, Share/Deep Links)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition (`t.me`, `telegram.me`, `tg://`, CDN)
2. Channel / message ID extraction
3. Content type classification
4. URL normalization and duplicate identity
5. Photo, video, GIF, audio, voice, document, album extraction
6. Public preview (`t.me/s`) and share URLs
7. Restricted / authentication handling (no bypass)
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → TelegramResolver
  ├── TelegramUri.classifyUrl()
  ├── TelegramUri.normalize() / contentIdentity()
  ├── tg://resolve → https://t.me/{channel}/{id}
  ├── Public t.me/s and ?embed=1 HTML
  └── Direct telesco.pe / telegram-cdn.org URLs
  ↓
DiscoveredResource[] → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, channel, preview, private, invite) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://t.me/` | No |
| Channel | `https://t.me/{channel}` | No |
| Public preview | `https://t.me/s/{channel}` | No |
| Message | `https://t.me/{channel}/{id}` | Yes, if media exposed |
| Public message preview | `https://t.me/s/{channel}/{id}` | Yes, if media exposed |
| Private | `https://t.me/c/{id}/{msg}` | No — RESTRICTED |
| Invite | `https://t.me/+hash` | No — RESTRICTED |
| Share | `https://t.me/share/url?...` | No |
| `tg://resolve` | public domain + post | Yes after normalize |
| Direct media | `*.telesco.pe/file/...` | Yes |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `telegram_url_test.dart` | 38 | Detection, classification, IDs, normalize, identity |
| `telegram_resolver_test.dart` | 10 | HTML, registry, naming |
| `telegram_channel_test.dart` | 5 | Channel / preview not downloaded |
| `telegram_message_test.dart` | 5 | MESSAGE, text-only, caption |
| `telegram_photo_test.dart` | 5 | Photo, MIME, dimensions |
| `telegram_video_test.dart` | 6 | MP4, `<source src>`, skip HLS |
| `telegram_audio_test.dart` | 6 | Audio + voice + `<audio src>` |
| `telegram_document_test.dart` | 4 | PDF/filename; no CDN → empty |
| `telegram_album_test.dart` | 5 | Count, order, dedupe |
| `telegram_metadata_test.dart` | 5 | Author, GIF, MIME |
| `telegram_download_test.dart` | 10 | State machine |
| `telegram_error_test.dart` | 21 | HTTP 403–503, formatter, text-only |
| `telegram_security_test.dart` | 21 | Schemes, private IPs, filenames |
| `telegram_performance_test.dart` | 5 | 50-item album parse |
| `telegram_auth_test.dart` | 11 | Restricted / auth / unavailable |
| **Total Telegram** | **157** | |

---

## Security rules

- Never bypass Telegram authentication
- Never access private `/c/` messages
- Never join invite-only groups
- Never use stolen sessions or tokens
- Never guess private channel IDs to gain access
