# Reddit Performance Tests

## Test File
`packages/download_engine/test/reddit_performance_test.dart`

## Coverage

50-item gallery parse (count, unique URLs/filenames); deterministic parse; single-image posts stay one resource. Full-resolution media is never loaded into memory during resolve — only metadata URLs.
