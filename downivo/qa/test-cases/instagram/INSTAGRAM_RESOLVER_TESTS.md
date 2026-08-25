# Instagram Resolver Tests

## Test File
`packages/download_engine/test/instagram_resolver_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 3 | GraphQL payload parsing | IG-GQL-001 to IG-GQL-008 |
| 3 | Legacy shortcode_media parsing | IG-LEGACY-001 to IG-LEGACY-004 |
| 5 | Video quality selection | IG-QUAL-001 to IG-QUAL-003 |
| 3 | Caption extraction | IG-CAP-001 to IG-CAP-004 |
| 3 | Filename generation | IG-FN-001 to IG-FN-004 |
| 8 | HTML fallback extraction | IG-HTML-001 to IG-HTML-005 |

## Notes

- Uses mock GraphQL payloads (JSON fixtures)
- Does NOT make real network calls
- Tests the `parsePayload` and `_bestVideoUrl` logic
- Tests `MediaExtractor._extractInstagramVideo` via HTML fixtures
