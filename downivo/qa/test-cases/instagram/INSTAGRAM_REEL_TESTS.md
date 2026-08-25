# Instagram Reel Tests

## Test File
`packages/download_engine/test/instagram_reel_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 1 | Reel URL detection | IG-REEL-001 to IG-REEL-006 |
| 2 | Reel URL normalization | IG-REEL-NORM-001 to IG-REEL-NORM-003 |
| 4 | Reel embed generation | IG-REEL-EMBED-001 to IG-REEL-EMBED-003 |
| 4 | Reel canonical URL | IG-REEL-CAN-001 to IG-REEL-CAN-003 |

## Notes

- Focused specifically on `/reel/` path handling
- Tests the most common Instagram share pattern (mobile copy-link produces reel URLs)
- Includes tracking parameter variations (utm_source, igsh)
