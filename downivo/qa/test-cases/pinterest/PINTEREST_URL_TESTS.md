# Pinterest URL Tests

## Test File
`packages/download_engine/test/pinterest_url_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 1 | Platform detection | PT-URL-001 to PT-URL-011 |
| 2 | Content type classification | PT-URL-020 to PT-URL-030 |
| 3 | Pin ID extraction (slug ignored) | PT-URL-040 to PT-URL-046 |
| 4 | Board / profile extraction | PT-URL-050 to PT-URL-053 |
| 5 | URL normalization | PT-URL-060 to PT-URL-065 |
| 6 | Duplicate identity | PT-URL-070 to PT-URL-075 |
| 7 | Downloadable vs not | PT-URL-080 to PT-URL-085 |
| 8 | Image URL upgrade | PT-URL-090 to PT-URL-093 |
| 9 | Fetch targets | PT-URL-100 |

Offline fixtures only. No live Pinterest network calls.
