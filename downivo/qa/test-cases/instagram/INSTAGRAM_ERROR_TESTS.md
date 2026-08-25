# Instagram Error Tests

## Test File
`packages/download_engine/test/instagram_error_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 14 | Private content | IG-PRIV-001 to IG-PRIV-002 |
| 16 | Deleted/unavailable | IG-DEL-001 to IG-DEL-003 |
| 17 | Invalid URLs | IG-INV-001 to IG-INV-010 |
| 18 | Security | IG-SEC-001 to IG-SEC-008 |

## Notes

- Error tests verify graceful failure, no crashes, and correct null returns
- Security tests ensure no execution of unsafe protocols
- Private/deleted tests verify resolver returns null (not throws)
- All tests offline — no real Instagram network calls
