# Vimeo Quality Tests

## Test File
`packages/download_engine/test/vimeo_quality_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-QUAL-001 | Lists only existing progressive qualities |
| VM-QUAL-002 | Does not invent 4K |
| VM-QUAL-003 | Best = highest height |
| VM-QUAL-004 | 720p selectable when present |
| VM-QUAL-005 | HLS not listed |
| VM-QUAL-006 | 360p-only source stays 360p |
| VM-QUAL-007 | Missing label is not selected |

UI/engine must only expose qualities actually present on the source.
