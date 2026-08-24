# Pinterest Error Tests

## Test File
`packages/download_engine/test/pinterest_error_test.dart`

| ID | Case |
|----|------|
| PT-ERR-001–006 | HTTP 403, 404, 429, 500, 502, 503 → empty |
| PT-ERR-007 | Network error |
| PT-ERR-008 | Timeout |
| PT-ERR-010 | Invalid pin |
| PT-ERR-011 | `/pin/` without id |
| PT-ERR-012 | Home |
| PT-ERR-013 | Board |
| PT-ERR-020–025 | DownloadErrorFormatter (no stack traces) |
