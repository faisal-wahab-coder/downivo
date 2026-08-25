# Threads Error Tests

Automated file: `packages/download_engine/test/threads_error_test.dart` (16 tests)

| ID | Case |
|----|------|
| TH-ERR-001–006 | HTTP 403 / 404 / 429 / 500 / 502 / 503 → empty |
| TH-ERR-007 | Connection error → empty |
| TH-ERR-008 | Timeout → empty |
| TH-ERR-020 | Home → home message |
| TH-ERR-021 | Profile → profile message |
| TH-ERR-022 | `/INVALID` → Unable to identify |
| TH-ERR-023 | Text-only → no downloadable media |
| TH-ERR-024 | Unavailable → no longer available |
| TH-ERR-025 | Restricted |
| TH-ERR-026 | Authentication |
| TH-ERR-027 | HLS-only |
