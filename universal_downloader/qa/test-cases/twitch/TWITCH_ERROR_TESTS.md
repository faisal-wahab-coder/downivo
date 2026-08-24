# Twitch Error Tests

Automated file: `packages/download_engine/test/twitch_error_test.dart` (19 tests)

| ID | Case |
|----|------|
| TW-ERR-001 | HTTP 403 → null |
| TW-ERR-002 | HTTP 404 → null |
| TW-ERR-003 | HTTP 429 → null |
| TW-ERR-004 | HTTP 500 → null |
| TW-ERR-005 | HTTP 502 → null |
| TW-ERR-006 | HTTP 503 → null |
| TW-ERR-007 | Network error → null |
| TW-ERR-008 | Timeout → null |
| TW-ERR-010 | Deleted clip not downloaded |
| TW-ERR-011 | Restricted clip not downloaded |
| TW-ERR-012 | INVALID VOD path empty |
| TW-ERR-013 | Home discoverAll empty |
| TW-ERR-014 | Empty GQL → null |
| TW-ERR-020–025 | Formatter 403/404/429/timeout/network; no stack traces |

User-facing messages (DownloadManager): home, directory, channel (no recording), VOD HLS-only, unavailable clip. No internal stack traces.
