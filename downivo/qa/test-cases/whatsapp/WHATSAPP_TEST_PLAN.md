# WhatsApp Integration Test Plan

**Platform:** WhatsApp (Click-to-chat, Group Invite, Public Channel, Share/Import, Voice Note, Document, Archive)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection (`wa.me`, `whatsapp.com`, `chat.whatsapp.com`, `web.whatsapp.com`, `whatsapp://`)
2. Click-to-chat phone / text extraction (no auto-send)
3. Content type classification
4. URL normalization and duplicate identity
5. Public Channel metadata and OG media
6. User-exported file import (image, video, audio, voice, PDF, document, archive, vCard)
7. Restricted / authentication / disappearing-content handling (no bypass)
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest, Vimeo, Twitch, LinkedIn, Telegram, Snapchat, Threads

---

## Architecture

```
User URL or shared file
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → WhatsAppResolver
  ├── WhatsAppUri.classifyUrl()
  ├── WhatsAppUri.normalize() / contentIdentity()
  ├── whatsapp://send → https://wa.me/{phone}
  ├── Public Channel OG CDN URLs
  └── classifyImportedFile(fileName, mime)
  ↓
DiscoveredResource[] → Download Engine
  OR
Shared file → File Import Engine → Storage → Database → Media Library
```

Non-downloadable pages (home, chat link, invite, Web, status) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL / file | Downloadable? |
|------|------------|----------------|
| Home | `https://www.whatsapp.com/` | No |
| Chat link | `https://wa.me/{phone}` | No — OPEN_EXTERNALLY |
| Chat + text | `https://wa.me/{phone}?text=` | No — do not auto-send |
| Group invite | `https://chat.whatsapp.com/{code}` | No — RESTRICTED |
| Public Channel | `/channel/{id}` | Yes, if public OG media exposed |
| Channel post | `/channel/{id}/{post}` | Yes, if public media exposed |
| WhatsApp Web | `web.whatsapp.com` | No — AUTHENTICATION_REQUIRED |
| Encrypted CDN | `mmg.whatsapp.net` | No — AUTHENTICATION_REQUIRED |
| Public CDN | `*.fbcdn.net` image/video | Yes |
| User-exported file | Share / File Import | Yes through import engine |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `whatsapp_url_test.dart` | 38 | Detection, classification, phone, normalize, identity |
| `whatsapp_resolver_test.dart` | 11 | HTML, registry, naming, no private fetch |
| `whatsapp_share_test.dart` | 9 | Share MIME / WhatsApp filename prefixes |
| `whatsapp_import_test.dart` | 11 | Import type mapping |
| `whatsapp_image_test.dart` | 5 | Image, MIME, dimensions, logo skip |
| `whatsapp_video_test.dart` | 5 | MP4, duration, skip HLS |
| `whatsapp_audio_test.dart` | 6 | Audio + voice note |
| `whatsapp_document_test.dart` | 7 | PDF / office / vCard |
| `whatsapp_archive_test.dart` | 5 | ZIP/RAR/7z, no auto-extract |
| `whatsapp_metadata_test.dart` | 5 | Channel, phone, MIME |
| `whatsapp_download_test.dart` | 10 | State machine |
| `whatsapp_error_test.dart` | 26 | HTTP 403–503, formatter, chat/invite/web |
| `whatsapp_security_test.dart` | 22 | Schemes, private IPs, filenames, `mmg` |
| `whatsapp_performance_test.dart` | 6 | URL-only parse, stable identity |

---

## Security rules

- Do not bypass WhatsApp encryption or authentication
- Do not scrape private chats
- Do not steal sessions, cookies, or tokens
- Do not auto-join groups or auto-send messages
- Do not recover disappearing content
