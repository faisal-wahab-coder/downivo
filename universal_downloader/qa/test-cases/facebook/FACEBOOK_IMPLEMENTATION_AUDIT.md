# Facebook Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA / Implementation Engineer

---

## Audit Summary

The Facebook platform is declared in `SocialPlatform` enum and has basic host detection, but **no dedicated resolver** exists. The `PlatformSocialResolver` returns `null` for Facebook, falling through to generic HTML/OpenGraph extraction only. This means Facebook support is minimal and most required features are **MISSING**.

---

## Feature Audit

| # | Feature | Status | Details |
|---|---------|--------|---------|
| 1 | Facebook URL detection | **IMPLEMENTED** | `SocialPlatform.fromUri()` matches `facebook.com`, `fb.watch`, `*.facebook.com` |
| 2 | Facebook URL parsing | **MISSING_REQUIRED_FEATURE** | No `FacebookUri` helper class exists (unlike `YouTubeUri`, `TikTokUri`, `TwitterUri`, `RedditUri`) |
| 3 | Facebook URL normalization | **PARTIALLY_IMPLEMENTED** | `SocialUrlUtils._normalize()` falls through to identity for Facebook. No query param stripping or canonical form. |
| 4 | Facebook platform identification | **IMPLEMENTED** | `SocialPlatform.facebook` enum value with label "Facebook" |
| 5 | Facebook video detection | **MISSING_REQUIRED_FEATURE** | No content type classification (video vs reel vs photo vs page) |
| 6 | Facebook Reel detection | **MISSING_REQUIRED_FEATURE** | No reel-specific URL parsing or content classification |
| 7 | Facebook photo post detection | **MISSING_REQUIRED_FEATURE** | No photo detection logic |
| 8 | Facebook image extraction | **PARTIALLY_IMPLEMENTED** | `MediaExtractor._extractOpenGraphImage()` is a generic fallback that works for og:image |
| 9 | Facebook video extraction | **PARTIALLY_IMPLEMENTED** | `MediaExtractor._extractDirectMediaUrl()` for Facebook only checks `og:video` / `og:video:url`. No structured JSON parsing. |
| 10 | Facebook multiple-media post detection | **MISSING_REQUIRED_FEATURE** | `PlatformSocialResolver.discoverAll()` has no Facebook case — falls through to single-item |
| 11 | Facebook post ID extraction | **MISSING_REQUIRED_FEATURE** | No helper to extract post/video/photo IDs from Facebook URLs |
| 12 | Facebook Reel ID extraction | **MISSING_REQUIRED_FEATURE** | No reel ID extraction |
| 13 | Facebook page/profile detection | **MISSING_REQUIRED_FEATURE** | No classification of page URLs vs content URLs |
| 14 | Facebook share URL detection | **PARTIALLY_IMPLEMENTED** | `fb.watch` is recognized, but no short URL redirect resolution for Facebook |
| 15 | Facebook redirect URL handling | **PARTIALLY_IMPLEMENTED** | `SocialUrlResolver.resolveRedirects()` is generic and works, but not wired into a Facebook resolver |
| 16 | Mobile copied URLs | **PARTIALLY_IMPLEMENTED** | `m.facebook.com` used in `_facebookTargets()` but no dedicated mobile URL normalization |
| 17 | Metadata extraction | **PARTIALLY_IMPLEMENTED** | Only OpenGraph tags — no structured data parsing |
| 18 | Thumbnail extraction | **PARTIALLY_IMPLEMENTED** | `og:image` fallback works generically |
| 19 | Video/audio handling | **MISSING_REQUIRED_FEATURE** | No Facebook-specific video version/quality parsing |
| 20 | Download format selection | **MISSING_REQUIRED_FEATURE** | No quality/format selection for Facebook |
| 21 | Download Engine integration | **IMPLEMENTED** | Generic `ContentProviderRegistry.discover()` flow works |
| 22 | Download Queue integration | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 23 | Storage Manager integration | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 24 | Database integration | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 25 | Media Library integration | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 26 | File Manager integration | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 27 | Notification integration | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 28 | Error handling | **PARTIALLY_IMPLEMENTED** | `DownloadErrorFormatter` handles HTTP errors generically but no Facebook-specific error mapping |
| 29 | Duplicate detection | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 30 | File naming | **PARTIALLY_IMPLEMENTED** | `MediaExtractor._buildFileName()` works generically but no Facebook content ID-based naming |
| 31 | MIME type handling | **IMPLEMENTED** | `FileNameResolver` handles all common media MIME types |
| 32 | Download verification | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 33 | Security validation | **IMPLEMENTED** | `UrlValidator` blocks non-HTTP(S) schemes |
| 34 | Background download | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 35 | Retry/resume | **IMPLEMENTED** | Inherited from Download Engine architecture |
| 36 | Offline handling | **IMPLEMENTED** | Inherited from Download Engine architecture |

---

## Required Implementation Actions

### Priority 1 — Must Implement

1. **`FacebookUri` helper class** — Extract video ID, reel ID, post ID, photo ID from Facebook URLs
2. **`FacebookResolver` class** — Dedicated resolver following `TikTokResolver` / `InstagramGraphqlResolver` pattern
3. **Facebook content type classification** — Distinguish video, reel, photo, page, home
4. **Register in `PlatformSocialResolver`** — Wire Facebook resolver into the discovery pipeline
5. **Register in `PlatformSocialResolver.discoverAll()`** — Support multi-media posts
6. **Facebook URL normalization** — Strip tracking params, canonicalize mobile/desktop
7. **Facebook-specific media extraction** — Parse structured JSON data, not just og: tags
8. **Facebook `fb.watch` redirect handling** — Resolve short URLs to canonical form

### Priority 2 — Should Implement

9. **Facebook image extraction for photo posts** — Detect and download photo-only posts
10. **Multi-photo post support** — Extract all images from carousel-like posts
11. **Content ID-based file naming** — Use video/reel/photo IDs for filenames
12. **Thumbnail extraction** — Extract thumbnail from metadata
13. **Export `FacebookResolver` from barrel** — Add to `download_engine.dart`

---

## Implementation Plan

```
1. Create FacebookUri helper class in social_url_utils.dart
2. Create facebook_resolver.dart following TikTokResolver pattern
3. Register in platform_social_resolver.dart
4. Add Facebook normalization to SocialUrlUtils._normalize()
5. Enhance MediaExtractor for Facebook-specific patterns
6. Export from download_engine.dart barrel
7. Create unit tests
8. Run tests and fix
9. Regression test other platforms
```

---

## Files to Modify

| File | Change |
|------|--------|
| `social_url_utils.dart` | Add `FacebookUri` class, add `_normalizeFacebook()` |
| `platform_social_resolver.dart` | Add `_facebook` resolver field, wire `discover()` and `discoverAll()` |
| `media_extractor.dart` | Enhance Facebook-specific extraction |
| `download_engine.dart` | Export `facebook_resolver.dart` |
| **NEW** `facebook_resolver.dart` | Full Facebook resolver |

---

*Audit complete. Proceeding to implementation.*
