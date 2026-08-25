# YouTube Download Tests

**Test file:** `packages/download_engine/test/youtube_download_test.dart`

Covers Phase 9 (State Machine), Phase 11 (Duplicates), Phase 12 (Errors), Phase 13 (File Validation), and live integration tests for Phase 2/3/7.

## Run

```bash
# Unit tests only
cd packages/download_engine
flutter test test/youtube_download_test.dart

# With live YouTube resolution
YOUTUBE_LIVE_TEST=1 flutter test test/youtube_download_test.dart
```

## Unit Test Groups (Always Run)

| Group | Tests | Status |
|-------|-------|--------|
| Phase 9 — DownloadStatus state values | 4 | PASS |
| Phase 11 — Duplicate download detection | 1 | PASS |
| Phase 12 — Error formatting | 2 | PASS |
| Phase 13 — YouTube file extension validation | 6 | PASS |

**Unit Total: 13 PASS, 0 FAIL**

## Live Integration Test Groups (Gated)

| Group | Tests | Gate |
|-------|-------|------|
| Live — Standard YouTube video resolution | 6 | `YOUTUBE_LIVE_TEST=1` |
| Live — YouTube Shorts resolution | 6 | `YOUTUBE_LIVE_TEST=1` |
| Live — Invalid YouTube URLs | 5 | `YOUTUBE_LIVE_TEST=1` |

**Live Total: 17 tests (skipped when gate is not set)**
