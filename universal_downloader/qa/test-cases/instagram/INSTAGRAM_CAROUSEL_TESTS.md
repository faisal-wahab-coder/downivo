# Instagram Carousel Tests

## Test File
`packages/download_engine/test/instagram_carousel_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 9 | Carousel URL detection | IG-CAR-001 to IG-CAR-002 |
| 9 | Multi-item payload | IG-CAR-ITEMS-001 to IG-CAR-ITEMS-003 |

## Notes

- Carousel posts use `/p/` path (same as regular posts)
- Current implementation uses `items.first` only — multi-item not fully supported
- Tests document current behavior and expected limitations
- Carousel with first item as video will download that video only
- Carousel with all images will return null (no downloadable video)
