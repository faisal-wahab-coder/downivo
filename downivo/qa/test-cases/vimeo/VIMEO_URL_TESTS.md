# Vimeo URL Tests

## Test File
`packages/download_engine/test/vimeo_url_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 1 | Platform detection | VM-URL-001 to VM-URL-007 |
| 2 | Content type classification | VM-URL-020 to VM-URL-031 |
| 3 | Video ID extraction | VM-URL-040 to VM-URL-048 |
| 4 | URL normalization | VM-URL-060 to VM-URL-065 |
| 5 | Duplicate identity | VM-URL-080 to VM-URL-084 |
| 6 | Downloadable vs not | VM-URL-090 to VM-URL-096 |
| 7 | Fetch targets | VM-URL-100 |

Offline fixtures only. No live Vimeo network calls.

Video ID is the identity. Player URLs, tracking params, and unlisted hashes must not create a different identity.
