# Reddit URL Tests

## Test File
`packages/download_engine/test/reddit_url_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 1 | Platform detection | RD-URL-001 to RD-URL-011 |
| 2 | Content type classification | RD-URL-020 to RD-URL-030 |
| 3 | Post ID extraction (slug ignored) | RD-URL-040 to RD-URL-048 |
| 4 | Subreddit extraction | RD-URL-050 to RD-URL-053 |
| 5 | URL normalization | RD-URL-060 to RD-URL-066 |
| 6 | JSON endpoint | RD-URL-070 to RD-URL-073 |
| 7 | Duplicate identity | RD-URL-080 to RD-URL-082 |
| 8 | Downloadable vs not | RD-URL-090 to RD-URL-093 |
| 9 | Fetch targets | RD-URL-100 |

Offline fixtures only. No live Reddit network calls.
