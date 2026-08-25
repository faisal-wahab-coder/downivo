# Instagram URL Tests

## Test File
`packages/download_engine/test/instagram_url_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 1 | Platform detection | IG-URL-001 to IG-URL-010 |
| 1 | Shortcode extraction | IG-SC-001 to IG-SC-012 |
| 1 | Content kind detection | IG-KIND-001 to IG-KIND-006 |
| 2 | URL normalization | IG-NORM-001 to IG-NORM-008 |
| 2 | Embed URL generation | IG-EMBED-001 to IG-EMBED-005 |
| 17 | Invalid URLs | IG-ERR-001 to IG-ERR-014 |
| 18 | Security | IG-SEC-001 to IG-SEC-006 |

## Notes

- All tests are offline with no network dependency
- Uses deterministic fixture URLs (not real Instagram posts)
- Tests validate current implementation behavior including known limitations
