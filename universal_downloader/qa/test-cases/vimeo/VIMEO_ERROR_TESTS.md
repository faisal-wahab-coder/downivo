# Vimeo Error Tests

## Test File
`packages/download_engine/test/vimeo_error_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-ERR-001–006 | HTTP 403, 404, 429, 500, 502, 503 → no crash, empty result |
| VM-ERR-007–008 | Network / timeout |
| VM-ERR-010 | Password |
| VM-ERR-011 | Private |
| VM-ERR-012 | Unavailable |
| VM-ERR-013 | DRM |
| VM-ERR-014–016 | Home / INVALID / On Demand empty |
| VM-ERR-020–025 | `DownloadErrorFormatter` (no stack traces) |

Do not retry infinitely. Do not bypass access restrictions.
