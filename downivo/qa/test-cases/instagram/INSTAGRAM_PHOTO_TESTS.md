# Instagram Photo Tests

## Test File
`packages/download_engine/test/instagram_photo_test.dart`

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 4 | Modern payload image extraction | IG-PHOTO-001 to IG-PHOTO-007 |
| 4 | Legacy payload image extraction | IG-PHOTO-LEGACY-001 to IG-PHOTO-LEGACY-003 |
| 14 | Photo filename and MIME | IG-PHOTO-FN-001 to IG-PHOTO-FN-002 |

## Notes

- Photo post support was IMPLEMENTED as part of this testing phase
- `image_versions2.candidates` is the primary extraction path
- `display_url` and `thumbnail_src` are fallbacks
- Video always takes priority over image when both are present
- MIME type is `image/jpeg` for all Instagram images
- File extension is `.jpg` (from CDN URL basename)
