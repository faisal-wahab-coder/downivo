# Snapchat Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

Snapchat is not named in `docs/`, but the Content Provider Architecture (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) requires every provider to:

- Recognize supported URLs
- Discover downloadable resources where permitted
- Extract metadata (title, filename, MIME, thumbnail, author)
- Provide download instructions to the existing Download Engine
- Handle errors without crashing
- Sanitize filenames and prevent path traversal
- Never bypass authentication, DRM, paywalls, or platform ToS
- Ship unit tests, mock responses, invalid URL tests, and error tests

Images and videos are first-class storage categories. A public profile is a **container**, not a downloadable media resource. Private Stories, friends-only content, chat, Memories, and stolen-session access are **prohibited**.

The existing Download Engine already covers queue, pause/resume, retry, cancel, verification, storage, database, media library, file manager, notifications, and background downloads. Snapchat must not introduce a platform-specific downloader.

There is **no** authorized Snapchat authentication mechanism and **no** Snapchat Public Profile API OAuth in the app. Authenticated-only content must return `AUTHENTICATION_REQUIRED`. Private / friends-only content must return `RESTRICTED_CONTENT`. Expired ephemeral content must return `CONTENT_EXPIRED`. HLS-only streams are a `PLATFORM_LIMITATION`.

---

## Pre-implementation status

Snapchat was **MISSING_REQUIRED_FEATURE** across URL detection, content classification, resolver, and engine wiring. This pass implemented it.

---

## Feature Audit

| # | Feature | Required? | Status | Notes |
|---|---------|-----------|--------|-------|
| 1 | Snapchat URL detection | YES | IMPLEMENTED | COMPLETE |
| 2 | snapchat.com detection | YES | IMPLEMENTED | `snapchat.com` and subdomains |
| 3 | Share URL detection | YES | IMPLEMENTED | `t.snapchat.com`, `/t/{code}` |
| 4 | Profile URL detection | YES | IMPLEMENTED | `/add/`, `/@`, `/p/{id}` |
| 5 | Spotlight URL detection | YES | IMPLEMENTED | `/spotlight/{id}` |
| 6 | Story URL detection | YES | IMPLEMENTED | `story.snapchat.com/s/{user}` |
| 7 | Saved Story URL detection | YES | IMPLEMENTED | `/p/{id}/highlights/{id}` |
| 8 | Snap URL detection | YES | IMPLEMENTED | `/snap/{id}` |
| 9 | Public profile detection | YES | IMPLEMENTED | Not downloaded as media |
| 10 | Spotlight content detection | YES | IMPLEMENTED | COMPLETE |
| 11 | Public Story detection | YES | IMPLEMENTED | COMPLETE |
| 12 | Public video detection | YES | IMPLEMENTED | MP4 via OG / `<video>` / JSON |
| 13 | Public image detection | YES | IMPLEMENTED | COMPLETE |
| 14 | Media type detection | YES | IMPLEMENTED | PHOTO / VIDEO / STORY / HLS_ONLY |
| 15 | Video duration | YES where exposed | IMPLEMENTED | Open Graph / JSON |
| 16 | Video dimensions | YES where exposed | IMPLEMENTED | Open Graph |
| 17 | Thumbnail extraction | YES | IMPLEMENTED | Highest exposed `og:image` |
| 18 | Metadata extraction | YES | IMPLEMENTED | Null when unavailable |
| 19 | Creator/profile extraction | YES where public | IMPLEMENTED | COMPLETE |
| 20 | Caption/description extraction | YES where public | IMPLEMENTED | COMPLETE |
| 21 | Content ID extraction | YES | IMPLEMENTED | Spotlight / story / share / snap |
| 22 | Canonical URL extraction | YES | IMPLEMENTED | Tracking stripped |
| 23 | Download Engine integration | YES | IMPLEMENTED | Shared engine |
| 24 | Download Queue integration | YES | IMPLEMENTED | Shared |
| 25 | Storage Manager integration | YES | IMPLEMENTED | Shared |
| 26 | Database integration | YES | IMPLEMENTED | Shared |
| 27 | Media Library integration | YES | IMPLEMENTED | Shared |
| 28 | File Manager integration | YES | IMPLEMENTED | Shared |
| 29 | Notification integration | YES | IMPLEMENTED | Shared |
| 30 | Background downloads | YES | IMPLEMENTED | Shared |
| 31 | Pause/resume | YES | IMPLEMENTED | Shared |
| 32 | Retry | YES | IMPLEMENTED | Network retryable; restricted/auth/expired/HLS not retried |
| 33 | Cancel | YES | IMPLEMENTED | Shared |
| 34 | Duplicate detection | YES | IMPLEMENTED | `snapchat:spotlight:{id}` / share / story |
| 35 | File naming | YES | IMPLEMENTED | Sanitize + path traversal blocked |
| 36 | Download verification | YES | IMPLEMENTED | Shared |
| 37 | Error handling | YES | IMPLEMENTED | Home / profile / restricted / auth / expired / HLS |
| 38 | Authentication handling | YES | IMPLEMENTED | No bypass; no official login |
| 39 | Authorization handling | YES | IMPLEMENTED | Restricted |
| 40 | Restricted content handling | YES | IMPLEMENTED | Chat / Memories / private HTML |
| 41 | Expired content handling | YES | IMPLEMENTED | `CONTENT_EXPIRED` |
| 42 | Offline behavior | YES | IMPLEMENTED | Shared |
| 43 | Performance | YES | IMPLEMENTED | URL-only resources; 50-snap story parse |
| 44 | Security | YES | IMPLEMENTED | Schemes, private IPs, filenames |

---

## Content model

URL-level `SnapchatContentType`:

`HOME` · `PUBLIC_PROFILE` · `PUBLIC_STORY` · `SAVED_STORY` · `SPOTLIGHT` · `SPOTLIGHT_FEED` · `SNAP` · `SHARE` · `EMBED` · `LENS` · `PRIVATE` · `AUTHENTICATION` · `DEEP_LINK` · `DIRECT_MEDIA` · `NON_CONTENT`

Media-level `SnapchatMediaType`:

`PHOTO` · `VIDEO` · `STORY` · `HLS_ONLY` · `UNKNOWN`

A Snapchat public profile URL is **not** classified as `VIDEO` and is **not** downloaded.

---

## Production Code

| File | Role |
|------|------|
| `snapchat_resolver.dart` | Public HTML → media; auth / restricted / expired / HLS errors |
| `social_url_utils.dart` | `SnapchatUri` + `SnapchatContentType` |
| `social_platform.dart` | `snapchat.com`, `t.snapchat.com`, `sc-cdn.net`, `snapchat://` |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Snapchat |
| `content_provider_registry.dart` | Skip home / profile / private pages |
| `media_extractor.dart` | Direct Snapchat CDN only; skip HLS |
| `download_manager.dart` | Snapchat user errors; no retry for permanent failures |
| `download_repository.dart` | Public `snapchat://` → `https://www.snapchat.com` |
| `social_http_headers.dart` | Snapchat origin |
| `download_engine.dart` | Export resolver |

---

## Platform Limitations

| Feature | Classification | Reason |
|---------|----------------|--------|
| Private Story / chat / Memories / friends-only | RESTRICTED_CONTENT | Privacy bypass prohibited |
| Login wall / `/login` / `accounts.snapchat.com` | AUTHENTICATION_REQUIRED | No official Snapchat login in the app |
| Snapchat Public Profile API OAuth | AUTHENTICATION_REQUIRED | Not implemented; not in docs as a required auth flow |
| HLS-only Spotlight / Story | PLATFORM_LIMITATION | Not saved as a single file (same as Twitch VOD) |
| Expired / disappeared Snap | CONTENT_EXPIRED | No unauthorized recovery |
| Profile bulk download | NOT_REQUIRED | Profile is a container |
| Lens / unlock pages | NOT_REQUIRED | Not media files |
| Stolen cookies / sessions / tokens | PROHIBITED | Never implemented |

---

## Security / privacy

- No authentication bypass
- No private Story scraping
- No friends-only extraction
- No stolen cookies, sessions, or tokens
- No DRM circumvention
- Restricted and authentication-required URLs are not fetched
- Filenames cannot escape the application storage directory
- `javascript:`, `file:`, localhost, and private IPs are rejected
