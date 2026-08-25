# Vimeo Security Tests

## Test File
`packages/download_engine/test/vimeo_security_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-SEC-001–004 | javascript / file / data rejected; https accepted |
| VM-SEC-010–014 | localhost / 127.0.0.1 / private IP / example.com |
| VM-SEC-020–026 | Path traversal, invalid FS chars, emoji, long title, Arabic |
| VM-SEC-030–032 | Encoded `..`, long URLs, tracking vs identity |

`../../../../test.mp4` must never escape application storage. Filenames are sanitized; `..` and path separators are removed.
