# TikTok Error Tests

**Test file:** `packages/download_engine/test/tiktok_error_test.dart`

Covers Phase 13 (Invalid URLs), Phase 14 (Private/Restricted), Phase 16 (Security).

## Run

```bash
cd packages/download_engine
flutter test test/tiktok_error_test.dart
```

## Test Groups

| Group | Tests | Coverage |
|-------|-------|----------|
| Phase 13 — Invalid TikTok URL handling | 10 | Homepage, profile, empty ID, non-numeric ID, invalid short URL |
| Phase 14 — Private/restricted content handling | 6 | Private, deleted, age-restricted, region-restricted |
| Phase 13 — Error formatting | 2 | Message formatting, truncation |
| Phase 16 — TikTok security edge cases | 7 | javascript:, data:, file:, localhost, private IP, SSRF |
| Regression — existing TikTok unit tests | 7 | Preserves tests from filename_resolver_test.dart |
