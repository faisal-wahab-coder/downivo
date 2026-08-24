# Reddit Integration Test Plan

**Platform:** Reddit (Posts, Videos, Images, GIFs, Galleries, Short/Share URLs, Direct Media)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition
2. Post ID extraction (slug ignored)
3. Content type classification (home, subreddit, post, comment, short, share, direct media, user)
4. URL normalization and duplicate identity
5. JSON API resolution (`/comments/<id>.json`)
6. Video, image, GIF, gallery, mixed-media extraction
7. Direct `i.redd.it` / `v.redd.it` URLs
8. Short (`redd.it`) and share (`/r/<sub>/s/<id>`) URLs
9. Download state machine
10. Error handling and security
11. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → RedditResolver
  ├── RedditUri.classifyUrl()
  ├── RedditUri.normalize() / jsonEndpoint()
  ├── share → SocialUrlResolver.resolveRedirects()
  ├── JSON API parseAllMedia()
  └── HTML fallback (MediaExtractor)
  ↓
DiscoveredResource[] → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, subreddit, user, search) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://www.reddit.com/` | No |
| Subreddit | `/r/<sub>/` | No (not bulk) |
| Post | `/r/<sub>/comments/<id>/<slug>/` | Yes, if media |
| Comment | `/r/<sub>/comments/<id>/<slug>/<cmt>/` | Parent post media |
| Short | `https://redd.it/<id>` | Yes |
| Share | `/r/<sub>/s/<code>` | Yes after redirect |
| Direct media | `i.redd.it`, `v.redd.it`, `preview.redd.it` | Yes |
| User | `/user/<name>/` | No |
| Text self-post | post without media | No |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `reddit_url_test.dart` | 54 | Detection, classification, IDs, normalize, identity |
| `reddit_resolver_test.dart` | 21 | JSON/HTML discovery, registry, MIME, naming |
| `reddit_video_test.dart` | 8 | DASH MP4, audio identification, no HLS |
| `reddit_image_test.dart` | 7 | JPG/PNG/WebP, imgur, reject YouTube links |
| `reddit_gif_test.dart` | 5 | Preserve GIF vs MP4 |
| `reddit_gallery_test.dart` | 9 | Count, order, mixed MIME, discoverAll |
| `reddit_metadata_test.dart` | 9 | Post ID, author, subreddit, duration, removed |
| `reddit_download_test.dart` | 12 | State machine, gallery item states |
| `reddit_error_test.dart` | 17 | HTTP 403–503, removed, formatter |
| `reddit_security_test.dart` | 17 | Schemes, private IPs, filenames |
| `reddit_performance_test.dart` | 3 | 50-item gallery parse |
| **Total Reddit** | **162** | |

---

## Run Commands

```bash
cd universal_downloader/packages/download_engine
flutter test test/reddit_*.dart
flutter test   # full engine regression
```

Live discovery (optional):

```bash
SOCIAL_LIVE_TEST=1 flutter test test/social_live_discovery_test.dart
```

---

## Manual Tests

Do **not** invent post IDs. Copy links from Reddit → Share → Copy link.

### RD-001 — Reddit Home

URL: `https://www.reddit.com/`

Expected: Platform=REDDIT, Content=HOME, **no download**.

### RD-002 — Public image post

Obtain: public image → Share → Copy link.

Store exact URL as RD-002. Test detection, image MIME, thumbnail, download, library.

### RD-003 — Public video post

Obtain: public video → Share → Copy link.

Store as RD-003. Test video MP4 (not m3u8), thumbnail, playback. If audio is separate DASH, document silent-video limitation unless muxer exists.

### RD-004 — GIF / GIF-like

Obtain: public animated post. Record whether media is GIF, MP4, or WebM. Do not rename MP4 to GIF.

### RD-005 — Gallery (P0)

Obtain: public multi-image post. Verify count, order, per-item state, library.

### RD-006 — Mixed media

Obtain if available. Each item independent MIME/state.

### RD-007 — Mobile share URL (P0)

Reddit app → Share → Copy link → paste into UniversalDownloader.

### RD-008 — Direct media

Legitimate `i.redd.it` / `v.redd.it/...mp4` URL. MIME + extension + download.

### RD-009 — Invalid post

`https://www.reddit.com/r/test/comments/INVALID/`

Expected: clean error, no crash, no stuck queue.

### RD-010 — Removed/unavailable

Where legitimately testable. Clear unavailable error. No auth bypass.

### Controlled fixtures (optional)

If a QA account exists: RD-QA-001 image, RD-QA-002 video, RD-QA-003 animated, RD-QA-004 gallery of 3, RD-QA-005 large gallery, RD-QA-006 mixed, RD-QA-007 Arabic title, RD-QA-008 long title.

---

## Existing live fixtures (already in repo)

These URLs were already present in `social_live_discovery_test.dart` (not invented for this phase):

- `https://www.reddit.com/r/videos/comments/6rrwyj/that_small_heart_attack/`
- `https://www.reddit.com/r/funny/comments/d8qo81/baby_crocodiles_sound_like_theyre_shooting_laser/`

Use only if still publicly available.

---

## Completion Rule

A Reddit feature is complete when implementation exists, unit tests pass, integration tests pass, manual cases are defined, errors/storage/database/library work via the shared engine, and regression passes.
