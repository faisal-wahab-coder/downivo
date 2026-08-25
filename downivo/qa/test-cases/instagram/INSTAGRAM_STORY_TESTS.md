# Instagram Story Tests

## Test File
`packages/download_engine/test/instagram_story_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 10 | Story URL detection | IG-STORY-001 to IG-STORY-004 |
| 10 | Story URL parsing | IG-STORY-PARSE-001 to IG-STORY-PARSE-003 |

## Notes

- Stories (`/stories/<username>/<id>/`) are NOT currently supported by the resolver
- `shortcodeFromUri` returns null for story URLs
- Tests document that story URLs are correctly recognized as Instagram platform
  but do not produce a downloadable resource
- This is a known limitation, not a bug
- Stories are ephemeral — automated tests must not depend on live story content
