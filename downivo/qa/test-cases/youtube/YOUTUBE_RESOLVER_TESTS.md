# YouTube Resolver Tests

**Test file:** `packages/download_engine/test/youtube_resolver_test.dart`

Covers Phase 2 (Metadata Extraction), Phase 3 (Download Resolution), Phase 4/5/6 (Quality/Audio/Muxing capabilities).

## Run

```bash
cd packages/download_engine
flutter test test/youtube_resolver_test.dart
```

## Test Groups

| Group | Tests | Status |
|-------|-------|--------|
| Phase 2 — YouTube metadata from HTML | 7 | PASS |
| Phase 2 — YouTube itag preference | 2 | PASS |
| Phase 3 — DiscoveredResource structure | 2 | PASS |
| Phase 3 — YouTube file naming | 3 | PASS |
| Phase 4/5/6 — Quality and audio capability | 3 | PASS |
| YouTube HTTP headers | 2 | PASS |

**Total: 19 PASS, 0 FAIL**
