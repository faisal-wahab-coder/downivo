# TikTok URL Tests

**Test file:** `packages/download_engine/test/tiktok_url_test.dart`

Covers Phase 1 (URL Parsing), Phase 2 (Normalization), Phase 13 (Invalid URLs), Phase 16 (Security), Phase 17 (Player/Embed URLs).

## Run

```bash
cd packages/download_engine
flutter test test/tiktok_url_test.dart
```

## Test Groups

| Group | Tests | Coverage |
|-------|-------|----------|
| Phase 1 — TikTok platform detection | 10 | Platform host matching |
| Phase 1 — TikTok video ID extraction | 8 | `/video/` and `/v/` path parsing |
| Phase 1 — TikTok username extraction | 6 | `/@username/` path parsing |
| Phase 1 — Short URL host recognition | 6 | vm, vt, t subdomain detection |
| Phase 2 — URL normalization | 8 | Deduplication, fetch targets |
| Phase 13 — Invalid TikTok URLs | 10 | Error handling for bad URLs |
| Phase 16 — Security | 8 | Malformed/dangerous URL rejection |
| Phase 17 — Player/embed URL classification | 4 | `/player/v1/` path handling |
