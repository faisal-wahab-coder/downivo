# Instagram Implementation Audit

**Date:** 2026-08-15
**Version:** v0.1.0 (download_engine)
**Auditor:** QA/Implementation Engineer

---

## Documentation Requirements

The project documentation (`docs/11_Technical_Architecture/11.5_Content_Provider_Architecture.md`) defines a generic Content Provider framework. Instagram is not explicitly named, but the architecture requires:

- Providers can download **images** and **videos**
- Providers must implement: `canHandle`, `validate`, `discoverResources`, `extractMetadata`, `buildDownloadPlan`
- Providers must handle errors gracefully
- Providers must validate inputs, sanitize filenames, prevent path traversal
- Providers must not bypass authentication, DRM, or platform ToS
- Every provider must include unit tests, mock responses, invalid URL tests, error handling tests

The Instagram provider already exists in the codebase, so all features it handles must work correctly for both videos AND images.

---

## Feature Audit

| # | Feature | Required? | Before | After | Tests | Status |
|---|---------|-----------|--------|-------|-------|--------|
| 1 | Instagram URL detection | YES | IMPLEMENTED | IMPLEMENTED | 10 | COMPLETE |
| 2 | Instagram URL parsing | YES | IMPLEMENTED | IMPLEMENTED | 12 | COMPLETE |
| 3 | Instagram URL normalization | YES | IMPLEMENTED | IMPLEMENTED | 8 | COMPLETE |
| 4 | Instagram Reel detection | YES | IMPLEMENTED | IMPLEMENTED | 6 | COMPLETE |
| 5 | Instagram photo post detection | YES | **MISSING** | **IMPLEMENTED** | 12 | COMPLETE |
| 6 | Instagram video post detection | YES | IMPLEMENTED | IMPLEMENTED | 3 | COMPLETE |
| 7 | Instagram carousel detection | YES | PARTIAL | **IMPLEMENTED** | 5 | COMPLETE |
| 8 | Instagram Story detection | NO | NOT SUPPORTED | NOT SUPPORTED | 9 | DOCUMENTED LIMITATION |
| 9 | Instagram profile detection | YES (reject) | IMPLEMENTED | IMPLEMENTED | 4 | COMPLETE |
| 10 | Instagram share URL detection | YES | IMPLEMENTED | IMPLEMENTED | 6 | COMPLETE |
| 11 | Instagram redirect resolution | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (via SocialUrlResolver) |
| 12 | Instagram post ID extraction | YES | IMPLEMENTED | IMPLEMENTED | 12 | COMPLETE |
| 13 | Instagram Reel ID extraction | YES | IMPLEMENTED | IMPLEMENTED | 6 | COMPLETE |
| 14 | Instagram Story ID extraction | NO | N/A | N/A | 3 | DOCUMENTED LIMITATION |
| 15 | Instagram username extraction | NO | N/A | N/A | 3 | INFORMATIONAL ONLY |
| 16 | Metadata extraction | YES | IMPLEMENTED | IMPLEMENTED | 8 | COMPLETE |
| 17 | Thumbnail extraction | YES | PARTIAL | IMPLEMENTED | 2 | COMPLETE (via image_versions2) |
| 18 | Image extraction | YES | **MISSING** | **IMPLEMENTED** | 12 | COMPLETE |
| 19 | Video extraction | YES | IMPLEMENTED | IMPLEMENTED | 8 | COMPLETE |
| 20 | Audio extraction | NO | N/A | N/A | — | NOT REQUIRED (docs) |
| 21 | Multiple media extraction | OPTIONAL | PARTIAL | **IMPLEMENTED** | 5 | COMPLETE (first item) |
| 22 | Carousel ordering | OPTIONAL | NOT IMPL | IMPLEMENTED | 3 | COMPLETE (first item priority) |
| 23 | Download format selection | NO | N/A | N/A | — | NOT REQUIRED (always best) |
| 24 | Download queue integration | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (via DownloadManager) |
| 25 | Download state machine | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared with all platforms) |
| 26 | Pause/resume | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 27 | Cancel | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 28 | Retry | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 29 | Background download | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 30 | Database integration | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 31 | Media Library integration | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 32 | File Manager integration | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 33 | Notification integration | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 34 | Error handling | YES | IMPLEMENTED | IMPLEMENTED | 30 | COMPLETE |
| 35 | Duplicate detection | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (canonical URL) |
| 36 | File naming | YES | IMPLEMENTED | IMPLEMENTED | 4 | COMPLETE |
| 37 | File extension handling | YES | PARTIAL | **IMPLEMENTED** | 2 | COMPLETE (.jpg for images) |
| 38 | MIME type handling | YES | PARTIAL | **IMPLEMENTED** | 4 | COMPLETE (video/mp4 + image/jpeg) |
| 39 | Download verification | YES | IMPLEMENTED | IMPLEMENTED | — | COMPLETE (shared) |
| 40 | Security validation | YES | IMPLEMENTED | IMPLEMENTED | 14 | COMPLETE |

---

## Production Code Changes Made

### File: `instagram_graphql_resolver.dart`

**Change 1: Added image extraction to `_parsePayload`**

- Before: Only extracted video from `video_versions` / `video_url`. Image posts returned `null`.
- After: Falls back to `_bestImageUrl()` when no video is found. Returns `DiscoveredResource` with `mimeType: 'image/jpeg'`.

**Change 2: Added `_bestImageUrl` static method**

- Extracts highest-resolution image from `image_versions2.candidates`
- Falls back to `display_url` or `thumbnail_src`
- Validates all URLs start with `http`

**Change 3: Added `_parseCarouselFirstMedia` method**

- When `carousel_media` array is present, iterates items
- Returns first downloadable media (video preferred, then image)
- Handles mixed-media carousels

**Change 4: Updated `_parseLegacyShortcodeMedia`**

- Before: Only returned video (`video_url`). No video = `null`.
- After: Falls back to `display_url` / `thumbnail_src` for image posts.

---

## Stories — Documented Limitation

**Reason:** Instagram Stories require authentication to access. The project documentation explicitly prohibits bypassing authentication (`11.5 §Security`, `23_Security.md`).

**Current behavior:**
- Story URLs (`/stories/<username>/<id>/`) are correctly detected as Instagram
- `shortcodeFromUri` returns `null` (no `/reel/`, `/p/`, `/tv/` path)
- `discover()` returns `null`
- Download Engine shows user-friendly error: "Could not find downloadable media"
- No crash, no infinite retry, no stuck queue

**Classification:** PLATFORM LIMITATION — correct graceful handling in place.

---

## Profile URLs — Correct Rejection

**Current behavior:**
- Profile URLs (`/<username>/`) are detected as Instagram
- No shortcode extractable → `discover()` returns `null`
- User receives meaningful error
- No download created

**Classification:** EXPECTED BEHAVIOR — profiles are not downloadable media.

---

## Relevant Source Files

| File | Role |
|------|------|
| `packages/download_engine/lib/src/content_providers/instagram_graphql_resolver.dart` | Main resolver (MODIFIED) |
| `packages/download_engine/lib/src/content_providers/social_platform.dart` | Platform detection |
| `packages/download_engine/lib/src/content_providers/social_url_utils.dart` | URL normalization, embed targets |
| `packages/download_engine/lib/src/content_providers/media_extractor.dart` | HTML fallback |
| `packages/download_engine/lib/src/content_providers/social_http_headers.dart` | Request headers |
| `packages/download_engine/lib/src/content_providers/content_provider_registry.dart` | Registry/orchestrator |
| `packages/download_engine/lib/src/content_providers/platform_social_resolver.dart` | Platform router |
| `packages/download_engine/lib/src/content_providers/models/discovered_resource.dart` | Output model |
| `packages/download_engine/lib/src/download_manager.dart` | Download lifecycle |

---

## Test Coverage

| Test File | Tests |
|-----------|-------|
| `instagram_url_test.dart` | 52 |
| `instagram_resolver_test.dart` | 27 |
| `instagram_reel_test.dart` | 18 |
| `instagram_post_test.dart` | 15 |
| `instagram_photo_test.dart` | 12 |
| `instagram_carousel_test.dart` | 5 |
| `instagram_story_test.dart` | 9 |
| `instagram_error_test.dart` | 30 |
| **Total Instagram tests** | **168** |
| **Full download_engine suite** | **486 pass, 26 skipped** |
