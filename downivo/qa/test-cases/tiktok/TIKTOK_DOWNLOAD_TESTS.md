# TikTok Download Tests

**Test file:** `packages/download_engine/test/tiktok_download_test.dart`

Covers Phase 5 (Download Resolution), Phase 10 (State Machine), Phase 11 (Interruptions), Phase 12 (Duplicates).

## Run

```bash
# Unit tests only (no network)
cd packages/download_engine
flutter test test/tiktok_download_test.dart

# Live integration tests (requires network + real TikTok)
TIKTOK_LIVE_TEST=1 flutter test test/tiktok_download_test.dart
```

## Test Groups

| Group | Tests | Gate |
|-------|-------|------|
| Phase 10 — Download state machine | 4 | Always |
| Phase 12 — Duplicate download behavior | 1 | Always |
| Phase 5 — Live TikTok download resolution | 7 | `TIKTOK_LIVE_TEST=1` |
| Phase 11 — Interruption handling | 3 | Always |

## Live Test URLs

| ID | URL | Type |
|----|-----|------|
| TT-001 | `https://www.tiktok.com/@scout2015/video/6718335390845095173` | Standard |
| TT-003 | Same URL with query params | Variation |
| TT-LIVE-003 | `https://www.tiktok.com/@bnsmrh404/video/7643276616088440071` | Standard |
| TT-LIVE-004 | `https://www.tiktok.com/@twice_tiktok_official/video/7334344147525963015` | Standard |
| TT-LIVE-005 | `https://www.tiktok.com/@hshs63690/video/7673099286178958610` | With params |
| TT-LIVE-NORM | Clean vs query param comparison | Normalization |
| TT-LIVE-INVALID | Non-existent video ID | Error handling |
