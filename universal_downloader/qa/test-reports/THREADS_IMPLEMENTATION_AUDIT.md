# Threads Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Documentation Requirements

Threads (Meta Threads / `threads.net` / `threads.com`) is **not named** in `docs/`. The Content Provider Architecture (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) still requires every provider to:

- Recognize supported URLs
- Discover downloadable resources where permitted
- Extract metadata (title, filename, MIME, thumbnail, author)
- Provide download instructions to the existing Download Engine
- Handle errors without crashing
- Sanitize filenames and prevent path traversal
- Never bypass authentication, DRM, paywalls, or platform ToS
- Ship unit tests, mock responses, invalid URL tests, and error tests

Images and videos are first-class storage categories. A public profile is a **container**, not a downloadable media resource. A text-only post is not a downloadable media resource. Private profiles, private posts, and stolen-session access are **prohibited**.

The existing Download Engine already covers queue, pause/resume, retry, cancel, verification, storage, database, media library, file manager, notifications, and background downloads. Threads must not introduce a platform-specific downloader.

There is **no** authorized Threads authentication mechanism in the app. Authenticated-only content must return `AUTHENTICATION_REQUIRED`. Private content must return `RESTRICTED_CONTENT`. Deleted / missing posts must return `CONTENT_UNAVAILABLE`. HLS-only streams are a `PLATFORM_LIMITATION`. Text-only posts return `NO_DOWNLOADABLE_MEDIA`.

`SocialPlatform.threads` already existed as a stub (`threads.net` host + generic Open Graph). This pass completed it.

---

## Pre-implementation status

Threads was **PARTIALLY_IMPLEMENTED**: host detection for `threads.net` only, embed fetch target, generic `og:video` scrape. Missing: `threads.com`, content types, dedicated resolver, carousel, quote/repost identity, auth/restriction, tests, QA docs.

---

## Feature Audit

| # | Feature | Required? | Status | Notes |
|---|---------|-----------|--------|-------|
| 1 | Threads URL detection | YES | IMPLEMENTED | COMPLETE |
| 2 | threads.net detection | YES | IMPLEMENTED | `threads.net` and subdomains |
| 3 | threads.com detection | YES | IMPLEMENTED | `threads.com` and subdomains |
| 4 | Threads share URL detection | YES | IMPLEMENTED | `xmt` / tracking; `l.threads.net` |
| 5 | Threads profile URL detection | YES | IMPLEMENTED | `/@{username}` — not downloaded |
| 6 | Threads post URL detection | YES | IMPLEMENTED | `/@user/post/{id}`, `/t/{id}`, `/post/{id}` |
| 7 | Threads media URL detection | YES | IMPLEMENTED | Public `cdninstagram.com` / `fbcdn.net` only |
| 8 | Image detection | YES | IMPLEMENTED | COMPLETE |
| 9 | Video detection | YES | IMPLEMENTED | Progressive MP4; HLS skipped |
| 10 | Carousel / multi-media detection | YES | IMPLEMENTED | Order preserved; URL-only |
| 11 | Post metadata extraction | YES | IMPLEMENTED | Null when unavailable |
| 12 | Profile metadata extraction | YES | IMPLEMENTED | Display only; no profile download |
| 13 | Author extraction | YES | IMPLEMENTED | `full_name` / `og:title` |
| 14 | Author username | YES | IMPLEMENTED | URL + JSON |
| 15 | Author ID | YES where public | IMPLEMENTED | `pk` when present |
| 16 | Post ID | YES | IMPLEMENTED | Shortcode |
| 17 | Canonical URL | YES | IMPLEMENTED | `www.threads.net/@user/post/{id}` |
| 18 | Thumbnail extraction | YES | IMPLEMENTED | Highest exposed `og:image` |
| 19 | Caption/text extraction | YES | IMPLEMENTED | COMPLETE |
| 20 | Published date | YES where public | IMPLEMENTED | `taken_at` / `article:published_time` |
| 21 | Media dimensions | YES where exposed | IMPLEMENTED | Open Graph / JSON |
| 22 | Video duration | YES where exposed | IMPLEMENTED | Open Graph / JSON |
| 23 | MIME detection | YES | IMPLEMENTED | From resolved metadata + URL |
| 24 | File extension | YES | IMPLEMENTED | Shared sanitizer |
| 25 | Download Engine integration | YES | IMPLEMENTED | Shared engine |
| 26 | Download Queue integration | YES | IMPLEMENTED | Shared |
| 27 | Storage Manager integration | YES | IMPLEMENTED | Shared |
| 28 | Database integration | YES | IMPLEMENTED | Shared |
| 29 | Media Library integration | YES | IMPLEMENTED | Shared |
| 30 | File Manager integration | YES | IMPLEMENTED | Shared |
| 31 | Notification integration | YES | IMPLEMENTED | Shared |
| 32 | Background downloads | YES | IMPLEMENTED | Shared |
| 33 | Pause/resume | YES | IMPLEMENTED | Shared |
| 34 | Retry | YES | IMPLEMENTED | Network retryable; restricted/auth/text-only not retried |
| 35 | Cancel | YES | IMPLEMENTED | Shared |
| 36 | Duplicate detection | YES | IMPLEMENTED | `threads:post:{id}` |
| 37 | File naming | YES | IMPLEMENTED | Sanitize + path traversal blocked |
| 38 | Download verification | YES | IMPLEMENTED | Shared |
| 39 | Error handling | YES | IMPLEMENTED | Home / profile / text / restricted / auth / unavailable / HLS |
| 40 | Authentication handling | YES | IMPLEMENTED | No bypass; no official login |
| 41 | Private-content handling | YES | IMPLEMENTED | `RESTRICTED_CONTENT` |
| 42 | Deleted-content handling | YES | IMPLEMENTED | `CONTENT_UNAVAILABLE` |
| 43 | Expired/unavailable handling | YES | IMPLEMENTED | Same unavailable path |
| 44 | Offline behavior | YES | IMPLEMENTED | Shared network errors |
| 45 | Performance | YES | IMPLEMENTED | URL-only carousel parse |
| 46 | Security | YES | IMPLEMENTED | Scheme / private IP / filename |

---

## Content model

| Type | Source | Downloadable? |
|------|--------|----------------|
| HOME | `/` | No |
| PROFILE | `/@{user}` | No |
| POST | `/@user/post/{id}`, `/t/{id}` | Yes if public media exposed |
| IMAGE / VIDEO / CAROUSEL / MULTI_MEDIA | Resolved HTML | Yes |
| TEXT | Resolved HTML | No — `NO_DOWNLOADABLE_MEDIA` |
| QUOTE_POST / REPOST | Resolved HTML | Media from exposed original; identity prefers original post ID |
| AUTHENTICATION | `/login` or login-wall HTML | No |
| UNKNOWN / NON_CONTENT | `/INVALID` | No |

---

## Security / privacy

- No session, cookie, or token theft
- No private-profile scraping
- No DRM / HLS remux
- CDN hosts shared with Instagram/Facebook are **not** claimed as Threads at the platform-detection layer
- `javascript:`, `file:`, localhost, and private IPs are rejected

---

## Production files

| File | Purpose |
|------|---------|
| `threads_resolver.dart` | Public HTML → media; auth/restricted/unavailable/text/HLS errors |
| `social_url_utils.dart` | `ThreadsUri` + `ThreadsContentType` |
| `social_platform.dart` | `threads.net` + `threads.com` |
| `platform_social_resolver.dart` | `discover` / `discoverAll` → Threads |
| `content_provider_registry.dart` | No homepage/profile HTML scrape |
| `media_extractor.dart` | Direct Threads CDN only; skip HLS |
| `download_manager.dart` | Threads user errors; no retry for permanent failures |
| `download_engine.dart` | Export resolver |
