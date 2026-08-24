# Instagram Download Tests

## Integration Test Coverage

Instagram downloads use the shared download_engine pipeline. Integration tests are in:
- `packages/download_engine/test/integration/download_lifecycle_test.dart`

## Instagram-Specific Download Behavior

The Instagram resolver produces a `DiscoveredResource` which feeds directly into the
standard download pipeline:

```
InstagramGraphqlResolver.discover(pageUrl)
  → DiscoveredResource { directUrl, fileName, mimeType, platform }
    → DownloadManager._runDownload()
      → HTTP download with SocialHttpHeaders
        → File verification
          → Database record
            → Media Library
```

## Covered by Shared Tests

| Feature | Test File |
|---------|-----------|
| Download lifecycle | `integration/download_lifecycle_test.dart` |
| Pause/Resume | `integration/download_lifecycle_test.dart` |
| Cancel | `integration/download_lifecycle_test.dart` |
| Retry | `integration/download_lifecycle_test.dart` |
| Queue management | `integration/download_lifecycle_test.dart` |
| File verification | `integration/download_lifecycle_test.dart` |
| Crash recovery | `integration/crash_recovery_test.dart` |

## Live Integration (Env-Gated)

Live Instagram download tests require `INSTAGRAM_LIVE_TEST=1`:
- `social_live_discovery_test.dart` — verifies real Instagram resolution

## Notes

- Instagram uses the same download state machine as all platforms
- No Instagram-specific download logic exists (by design)
- File categorization (Videos/ vs Images/) is based on MIME type
- Background download, notifications, and media library are platform-agnostic
