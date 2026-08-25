# Vimeo Integration Test Plan

**Platform:** Vimeo (Videos, Player URLs, Share/Unlisted hashes, Qualities, MP4)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition
2. Video ID extraction (numeric ID; path hash is access, not identity)
3. Content type classification (home, video, player, channel, group, showcase, user, ondemand)
4. URL normalization and duplicate identity
5. Player config resolution (`/video/{id}/config`)
6. Progressive MP4 quality listing (no fabricated 4K)
7. HLS/DASH skipped
8. Download state machine
9. Error handling and security
10. Regression vs YouTube, TikTok, Instagram, Facebook, SoundCloud, Reddit, Pinterest

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.fromUri()
  ↓
ContentProviderRegistry.discover / discoverAll
  ↓
PlatformSocialResolver → VimeoResolver
  ├── VimeoUri.classifyUrl()
  ├── VimeoUri.normalize() / videoIdFromUri() / privacyHashFromUri()
  ├── GET player.vimeo.com/video/{id}/config
  ├── parseQualities() → best progressive MP4
  └── HTML window.playerConfig fallback
  ↓
DiscoveredResource → Download Engine → Queue → Storage → Database → Media Library
```

Non-downloadable pages (home, user, channel listing, On Demand, search) return empty and **do not** fall through to homepage HTML scraping.

---

## Content Types

| Type | URL | Downloadable? |
|------|-----|----------------|
| Home | `https://vimeo.com/` | No |
| Video | `https://vimeo.com/{id}` | Yes, if public progressive MP4 |
| Player | `https://player.vimeo.com/video/{id}` | Yes (same identity) |
| Unlisted | `https://vimeo.com/{id}/{hash}` | Yes, if hash supplied by user |
| Channel video | `/channels/{name}/{id}` | Yes |
| Group video | `/groups/{name}/videos/{id}` | Yes |
| Showcase video | `/showcase/{id}/video/{id}` | Yes |
| User | `https://vimeo.com/{username}` | No |
| On Demand | `/ondemand/...` | No (paywall) |
| Channel listing | `/channels/{name}` | No |

---

## Test Files

| File | Tests | Coverage |
|------|------:|----------|
| `vimeo_url_test.dart` | 47 | Detection, classification, IDs, normalize, identity |
| `vimeo_resolver_test.dart` | 13 | Config/HTML discovery, registry, naming |
| `vimeo_metadata_test.dart` | 10 | Title, author, duration, thumbs, MIME |
| `vimeo_video_test.dart` | 6 | Best MP4, skip HLS, player URL |
| `vimeo_quality_test.dart` | 7 | Actual qualities only; 720p vs 1080p |
| `vimeo_audio_video_test.dart` | 5 | Muxed MP4, silent, HLS separate_av |
| `vimeo_download_test.dart` | 11 | State machine, filename, identity |
| `vimeo_error_test.dart` | 21 | HTTP 403–503, password/private/DRM |
| `vimeo_security_test.dart` | 19 | Schemes, private IPs, filenames |
| `vimeo_performance_test.dart` | 5 | Many qualities, identity loop |
| **Total Vimeo** | **144** | |

---

## Run Commands

```bash
cd downivo/packages/download_engine
flutter test test/vimeo_url_test.dart test/vimeo_resolver_test.dart \
  test/vimeo_metadata_test.dart test/vimeo_video_test.dart \
  test/vimeo_quality_test.dart test/vimeo_audio_video_test.dart \
  test/vimeo_download_test.dart test/vimeo_error_test.dart \
  test/vimeo_security_test.dart test/vimeo_performance_test.dart
flutter test   # full engine regression
```

---

## Manual tests (P0)

Do **not** invent Vimeo IDs. Copy public URLs from Vimeo.

| ID | Case | Notes |
|----|------|-------|
| VM-001 | `https://vimeo.com/` | HOME — no download |
| VM-002 | Public video (Share → Copy link) | Full workflow |
| VM-003 | Second public video | Different duration/aspect |
| VM-004 | High-resolution if actually offered | Only listed qualities |
| VM-005 | Video with audio | Playback + A/V sync |
| VM-006 | `https://player.vimeo.com/video/{id}` | Same identity as VM-002 |
| VM-007 | Mobile share URL | P0 |
| VM-008 | Canonical + player + query variants | No duplicate identity |
| VM-009 | `https://vimeo.com/INVALID` | Clean error |
| VM-010 | Unavailable/restricted if testable | No bypass |

---

## Quality rules

- Display only qualities present in `request.files.progressive`
- Default download is highest height
- Never upscale or claim 4K unless a 2160p (or equivalent) rendition exists
- HLS/DASH are not converted
