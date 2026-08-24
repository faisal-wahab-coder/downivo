# TikTok Photo Tests

**Test file:** `packages/download_engine/test/tiktok_photo_test.dart`

Covers Phase 9 (Photo/Carousel Posts).

## Run

```bash
cd packages/download_engine
flutter test test/tiktok_photo_test.dart
```

## Test Groups

| Group | Tests | Coverage |
|-------|-------|----------|
| Phase 9 — TikTok photo post support | 5 | Video-only extraction, photo HTML behavior |
| Phase 9 — Photo post type detection gaps | 2 | /photo/ path handling |

## Status

**TikTok photo/carousel posts are NOT SUPPORTED.** All tests document and verify this limitation:

- The resolver only searches for video fields (`downloadAddr`, `playAddr`, `playApi`)
- Photo posts use `imagePost.images` which the resolver does not parse
- `DiscoveredResource` has a single `directUrl`, not a list of image URLs
- The `/photo/` path pattern is not matched by `TikTokUri.videoIdFromUri()`
- Photo post URLs are still correctly detected as TikTok platform

## Recommendation

To support photo posts in the future:

1. Add `/photo/(\d+)` pattern to `TikTokUri.videoIdFromUri()`
2. Add `imagePost` JSON field parsing to `TikTokResolver._extractVideoUrl()`
3. Add `List<String>? imageUrls` to `DiscoveredResource`
4. Add image download logic to `DownloadManager`
5. Handle correct ordering and naming of carousel images
