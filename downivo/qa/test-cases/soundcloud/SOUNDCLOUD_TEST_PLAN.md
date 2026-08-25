# SoundCloud Integration Test Plan

**Platform:** SoundCloud (Tracks, Playlists/Sets, Profiles, Short URLs)
**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)

---

## Scope

1. URL detection and platform recognition
2. Content type classification (track, playlist/set, profile, home, short URL)
3. URL normalization and canonical identity
4. Track resolution (hydration → transcoding → CDN audio)
5. Playlist/set resolution with ordering and partial failure
6. Metadata, artwork, MIME, filename
7. Download state machine (shared engine)
8. Error handling and security
9. Regression against YouTube, TikTok, Instagram, Facebook

---

## Architecture

```
User URL
  ↓
ContentProviderRegistry.canHandle(uri) → SocialPlatform.soundcloud
  ↓
PlatformSocialResolver.discover / discoverAll
  ↓
SoundCloudResolver
  ├── SoundCloudUri.classifyUrl
  ├── fetch public page (follow redirects)
  ├── __sc_hydration + client_id
  ├── progressive transcoding → CDN audio URL
  └── DiscoveredResource → Download Engine
```

Profile, home, likes, and system pages return empty. They are not downloaded.

---

## Automated Test Files

| Test File | Coverage |
|-----------|----------|
| `soundcloud_url_test.dart` | Detection, classification, normalization, identity, security |
| `soundcloud_resolver_test.dart` | Hydration, playlist, OG fallback, registry |
| `soundcloud_track_test.dart` | Track resolve, artwork fallback, SNIP/private |
| `soundcloud_playlist_test.dart` | Ordering, stubs, mixed failure |
| `soundcloud_metadata_test.dart` | Title, artwork, MIME mapping |
| `soundcloud_audio_test.dart` | MP3/M4A/HLS-only |
| `soundcloud_download_test.dart` | State machine, MIME, playlist states |
| `soundcloud_error_test.dart` | HTTP 403/404/429/5xx, formatter |
| `soundcloud_security_test.dart` | Schemes, private IPs, filename |
| `soundcloud_performance_test.dart` | Large playlist, long URL |

All automated tests are offline with fixtures. No live SoundCloud URLs.

---

## Manual Tests (real public URLs only)

Copy links from SoundCloud → Share → Copy link. Do not invent IDs.

| ID | Case | Expected |
|----|------|----------|
| SC-001 | `https://soundcloud.com/` | Platform SOUNDCLOUD, content HOME, no download |
| SC-002 | Public track (share link) | Detect TRACK, metadata, artwork, audio, download, library |
| SC-003 | Second public track | Different content identity from SC-002 |
| SC-004 | Track with artwork | Thumbnail + library artwork |
| SC-005 | Track without custom artwork | Avatar / app fallback, no crash |
| SC-006 | Public playlist/set | Track count, order, per-track state |
| SC-007 | Mobile share URL | Same identity as desktop (P0) |
| SC-008 | Track URL + query params | Same identity |
| SC-009 | Fake `.../INVALID/INVALID` | Clean failure |
| SC-010 | Deleted/unavailable public URL | Unavailable error, no retry loop |

Controlled content (if an account you own is available): SC-QA-001 … SC-QA-006.

Do not bypass login, privacy, or Go+ restrictions.

---

## Platform Limitations

- Private tracks without a user-supplied `secret_token`
- Go+ SNIP / preview-only
- HLS-only (no single-file progressive URL)
- Profile bulk download (not a media item)
