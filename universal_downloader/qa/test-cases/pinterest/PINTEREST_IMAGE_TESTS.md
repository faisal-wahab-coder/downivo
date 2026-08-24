# Pinterest Image Tests

## Test File
`packages/download_engine/test/pinterest_image_test.dart`

| ID | Case |
|----|------|
| PT-IMG-001 | Original PNG, not 736x JPEG |
| PT-IMG-002 | WebP MIME preserved (not renamed to JPG) |
| PT-IMG-003 | JPEG orig → image/jpeg |
| PT-IMG-004 | `images.orig` preferred regardless of map order |
| PT-IMG-005 | OG 736x upgraded to `/originals/` |
| PT-IMG-006 | Thumbnail present |
| PT-IMG-007 | Direct pinimg URL upgrades |
