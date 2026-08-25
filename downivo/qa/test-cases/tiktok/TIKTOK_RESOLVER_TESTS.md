# TikTok Resolver Tests

**Test file:** `packages/download_engine/test/tiktok_resolver_test.dart`

Covers Phase 4 (Metadata), Phase 6 (Quality), Phase 7 (Audio), Phase 8 (Muxing), Phase 14 (Headers), Phase 15 (File Naming).

## Run

```bash
cd packages/download_engine
flutter test test/tiktok_resolver_test.dart
```

## Test Groups

| Group | Tests | Coverage |
|-------|-------|----------|
| Phase 4 — TikTok downloadAddr extraction | 4 | downloadAddr, playAddr, playApi, priority |
| Phase 4 — TikTok script tag extraction | 2 | __UNIVERSAL_DATA_FOR_REHYDRATION__, SIGI_STATE |
| Phase 4 — TikTok unicode escape handling | 2 | \u002F, \u0026 decoding |
| Phase 4 — TikTok CDN URL validation | 8 | webarch rejection, /video/tos/, mime_type, tiktokcdn+mp4, empty/missing |
| Phase 4 — Metadata extraction | 5 | og:title, platform label, filename, copyWith |
| Phase 4 — Metadata gaps | 4 | Documented: no thumbnail, duration, width/height, content type |
| Phase 6 — Video quality | 1 | Single stream documented |
| Phase 7 — Audio | 1 | No audio-only documented |
| Phase 8 — Audio+Video muxing | 1 | Not applicable documented |
| Phase 14 — HTTP headers | 3 | TikTok origin/referer, UA selection |
| Phase 15 — File naming | 7 | Title slug, CDN basename, fallback, sanitize, extension |
| CDN detection | 2 | tiktokcdn.com, tiktokv.com |
