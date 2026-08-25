# Instagram Post Tests

## Test File
`packages/download_engine/test/instagram_post_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 1 | Post URL detection | IG-POST-001 to IG-POST-005 |
| 8 | Image vs video distinction | IG-POST-TYPE-001 to IG-POST-TYPE-003 |
| 1 | IGTV URL detection | IG-TV-001 to IG-TV-003 |
| 3 | Post metadata | IG-POST-META-001 to IG-POST-META-003 |

## Notes

- `/p/` path can contain video OR image content
- Current implementation only supports video posts (returns null for image-only)
- This is a documented limitation, not a bug
