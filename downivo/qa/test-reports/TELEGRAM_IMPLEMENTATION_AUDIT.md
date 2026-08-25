# Telegram Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

Telegram is not named in `docs/`, but the Content Provider Architecture (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) requires every provider to:

- Recognize supported URLs
- Discover downloadable resources where permitted
- Extract metadata (title, filename, MIME, thumbnail, author)
- Provide download instructions to the existing Download Engine
- Handle errors without crashing
- Sanitize filenames and prevent path traversal
- Never bypass authentication, DRM, paywalls, or platform ToS
- Ship unit tests, mock responses, invalid URL tests, and error tests

Images, videos, audio, voice, documents, and GIFs are first-class storage categories. Channel-level bulk download is **not** required. Text-only export is **not** required. Private channels, invite-only groups, and stolen-session access are **prohibited**.

The existing Download Engine already covers queue, pause/resume, retry, cancel, verification, storage, database, media library, file manager, notifications, and background downloads. Telegram must not introduce a platform-specific downloader.

There is **no** authorized Telegram authentication mechanism in the app. Authenticated-only content must return `AUTHENTICATION_REQUIRED`. Restricted `/c/` and invite links must return `RESTRICTED_CONTENT`.

---

## Feature Audit

| # | Feature | Required? | Status | Notes |
|---|---------|-----------|--------|-------|
| 1 | Telegram URL detection | YES | IMPLEMENTED | COMPLETE |
| 2 | Telegram domain detection | YES | IMPLEMENTED | `t.me`, `telegram.me`, `telegram.org`, `telegram.dog` |
| 3 | `t.me` detection | YES | IMPLEMENTED | COMPLETE |
| 4 | `telegram.me` detection | YES | IMPLEMENTED | COMPLETE |
| 5 | `tg://` detection | YES | IMPLEMENTED | Also `telegram://` |
| 6 | Telegram URL parsing | YES | IMPLEMENTED | `TelegramUri` |
| 7 | Telegram URL normalization | YES | IMPLEMENTED | COMPLETE |
| 8 | Channel detection | YES | IMPLEMENTED | COMPLETE |
| 9 | Group detection | YES (classify) | IMPLEMENTED | Invite / private |
| 10 | Message detection | YES | IMPLEMENTED | COMPLETE |
| 11 | Public channel detection | YES | IMPLEMENTED | COMPLETE |
| 12 | Public message detection | YES | IMPLEMENTED | COMPLETE |
| 13 | Private/restricted detection | YES | IMPLEMENTED | `/c/`, invite — no fetch |
| 14 | Authentication requirement detection | YES | IMPLEMENTED | Login-wall HTML + `/login`; not conflated with private URLs |
| 15 | Media type detection | YES | IMPLEMENTED | COMPLETE |
| 16 | Photo detection | YES | IMPLEMENTED | COMPLETE |
| 17 | Video detection | YES | IMPLEMENTED | `<video src>` and `<source src>` |
| 18 | Document detection | YES | IMPLEMENTED | COMPLETE |
| 19 | Audio detection | YES | IMPLEMENTED | COMPLETE |
| 20 | Voice message detection | YES | IMPLEMENTED | `data-voice` and `<audio src>` |
| 21 | GIF/animation detection | YES | IMPLEMENTED | MP4 animation |
| 22 | Album/media-group detection | YES | IMPLEMENTED | COMPLETE |
| 23 | File detection | YES | IMPLEMENTED | When CDN URL exposed |
| 24 | Message ID extraction | YES | IMPLEMENTED | COMPLETE |
| 25 | Channel identifier extraction | YES | IMPLEMENTED | COMPLETE |
| 26 | Author information | YES where public | IMPLEMENTED | COMPLETE |
| 27 | Channel name | YES | IMPLEMENTED | COMPLETE |
| 28 | Message text/caption | YES | IMPLEMENTED | COMPLETE |
| 29 | Thumbnail | YES | IMPLEMENTED | COMPLETE |
| 30 | Media dimensions | YES where exposed | IMPLEMENTED | Open Graph |
| 31 | Duration | YES where exposed | IMPLEMENTED | COMPLETE |
| 32 | File size | YES where available | IMPLEMENTED | Shared HTTP Content-Length |
| 33 | MIME type | YES | IMPLEMENTED | COMPLETE |
| 34 | Filename | YES | IMPLEMENTED | Sanitize + path traversal blocked |
| 35 | Download Engine integration | YES | IMPLEMENTED | Shared engine |
| 36 | Download Queue integration | YES | IMPLEMENTED | Shared |
| 37 | Storage Manager integration | YES | IMPLEMENTED | Shared; `.ogg`/`.opus`/`.oga`/`.m4a` → audio |
| 38 | Database integration | YES | IMPLEMENTED | Shared |
| 39 | Media Library integration | YES | IMPLEMENTED | Shared |
| 40 | File Manager integration | YES | IMPLEMENTED | Shared |
| 41 | Notification integration | YES | IMPLEMENTED | Shared |
| 42 | Background download | YES | IMPLEMENTED | Shared |
| 43 | Pause/resume | YES | IMPLEMENTED | Shared |
| 44 | Retry | YES | IMPLEMENTED | Network retryable; restricted/auth/text-only not retried |
| 45 | Cancel | YES | IMPLEMENTED | Shared |
| 46 | Duplicate detection | YES | IMPLEMENTED | `telegram:message:{ch}:{id}` |
| 47 | File naming | YES | IMPLEMENTED | COMPLETE |
| 48 | Download verification | YES | IMPLEMENTED | Shared |
| 49 | Error handling | YES | IMPLEMENTED | Login wall / unavailable / text-only surfaced to the user |
| 50 | Security validation | YES | IMPLEMENTED | Schemes, private IPs, filenames |
| 51 | Authentication handling | YES | IMPLEMENTED | No bypass |
| 52 | Authorization handling | YES | IMPLEMENTED | Restricted |
| 53 | Offline behavior | YES | IMPLEMENTED | Shared |
| 54 | Performance | YES | IMPLEMENTED | URL-only resources |
| 55 | Large-file handling | YES | IMPLEMENTED | Shared incremental write |

---

## Hardening in this pass

Independent audit found Telegram already wired as a content provider. The following required gaps were closed:

1. `cdn.telegram.org` was a Telegram CDN host in `TelegramUri` but missing from `SocialPlatform.fromUri`.
2. `requiresAuthentication` previously equalled `isRestricted`, conflating private/invite with login.
3. Login-wall / unavailable / text-only HTML returned an empty discover result, so the download manager showed a generic “no media” message and retried.
4. Public embed `<audio src>` and `<source src>` were not parsed.
5. Voice/audio extensions `.ogg` / `.oga` / `.opus` / `.m4a` were not mapped to the audio storage category when MIME was missing.

---

## Production Code

| File | Role |
|------|------|
| `telegram_resolver.dart` | Resolver: public HTML → media; auth/unavailable/text-only errors |
| `social_url_utils.dart` | `TelegramUri` + `TelegramContentType` |
| `social_platform.dart` | Host / scheme detection including `cdn.telegram.org` |
| `platform_social_resolver.dart` | Registry wiring |
| `content_provider_registry.dart` | Skip non-downloadable pages |
| `media_extractor.dart` | Direct Telegram CDN only |
| `download_manager.dart` | Telegram errors; no retry for permanent failures |
| `download_repository.dart` | Public `tg://resolve` → `https://t.me` |
| `filename_resolver.dart` | `audio/opus` |

---

## Platform Limitations

| Feature | Classification | Reason |
|---------|----------------|--------|
| Private `/c/` message | RESTRICTED_CONTENT | Auth / privacy bypass prohibited |
| Invite-only channel/group | RESTRICTED_CONTENT | Cannot join or enumerate |
| Login-walled public-looking URL | AUTHENTICATION_REQUIRED | No official Telegram login in the app |
| Document with only a `t.me` href | PLATFORM_LIMITATION | File not exposed on the public CDN |
| Channel / preview bulk download | NOT_REQUIRED | Channel is not a media item |
| Text-only export as a file | NOT_REQUIRED | Docs do not require text export |
| Stolen sessions / MTProto user API | PROHIBITED | Never implemented |
| HLS-only streams | PLATFORM_LIMITATION | Not a single downloadable file |
| Fabricated higher resolution | NOT_REQUIRED | Must not upscale |

---

*Audit complete after implementation and regression. See TELEGRAM_TEST_REPORT.md for results.*
