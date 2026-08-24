# Vimeo Metadata Tests

## Test File
`packages/download_engine/test/vimeo_metadata_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-META-001 | Video ID, title, author, duration, dimensions |
| VM-META-002 | Missing title is not fabricated |
| VM-META-003 | Missing description is not fabricated |
| VM-META-004 | Description used when present |
| VM-META-005 | Largest thumbnail |
| VM-META-006 | Aspect ratio from selected size |
| VM-META-007 | Frame rate from selected quality |
| VM-META-008 | Resource title/platform/thumbnail |
| VM-META-009 | MIME mapping |
| VM-META-010 | Author ID stringified |

Uses `VimeoVideoInfo` from player-config fixtures.
