# YouTube Shorts Tests

**Test file:** `packages/download_engine/test/youtube_shorts_test.dart`

Covers Phase 7 (Shorts) — URL recognition, ID extraction, normalization, detection gaps.

## Run

```bash
cd packages/download_engine
flutter test test/youtube_shorts_test.dart
```

## Test Groups

| Group | Tests | Status |
|-------|-------|--------|
| Phase 7 — Shorts URL recognition | 24 | PASS |
| Phase 7 — Shorts normalization | 3 | PASS |
| Phase 7 — Shorts vs Standard detection gaps | 4 | PASS |
| Phase 7 — Shorts edge cases | 3 | PASS |

**Total: 34 PASS, 0 FAIL**

## Edge Cases Discovered

- **YTS-EDGE-001:** `/shorts/` with trailing slash may fail to extract ID (regex-dependent)
- **YTS-EDGE-002:** `/shorts/` with query parameters works correctly
- **YTS-EDGE-003:** `/shorts/` with fragment works correctly
