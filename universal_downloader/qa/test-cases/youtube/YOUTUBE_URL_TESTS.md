# YouTube URL Tests

**Test file:** `packages/download_engine/test/youtube_url_test.dart`

Covers Phase 1 (URL Parsing), Phase 7 (Shorts parsing), Phase 8 (URL Variations), Phase 12 (Invalid URLs).

## Run

```bash
cd packages/download_engine
flutter test test/youtube_url_test.dart
```

## Test Groups

| Group | Tests | Status |
|-------|-------|--------|
| Phase 1 — YouTube platform detection | 6 | PASS |
| Phase 1 — Standard YouTube video ID extraction | 6 | PASS |
| Phase 7 — YouTube Shorts video ID extraction | 8 | PASS |
| Phase 8 — URL variations all resolve to same video ID | 6 | PASS |
| Phase 1 — Additional URL forms | 5 | PASS |
| Phase 12 — Invalid YouTube URLs | 8 | PASS |
| Phase 1 — YouTubeResolver HTML extraction | 4 | PASS |
| Phase 1 — Content type detection gaps | 2 | PASS |
| Phase 1 — URL normalization | 3 | PASS |

**Total: 48 PASS, 0 FAIL**
