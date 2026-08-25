# Pinterest Security Tests

## Test File
`packages/download_engine/test/pinterest_security_test.dart`

| ID | Case |
|----|------|
| PT-SEC-001–004 | javascript / file / data rejected; https accepted |
| PT-SEC-010–014 | localhost, 127.0.0.1, private IP, example.com |
| PT-SEC-020–025 | Filename sanitization, path traversal, emoji, long title |
| PT-SEC-030 | Encoded `..` collapsed (no fake pin ID) |
| PT-SEC-031 | Very long URL still classifies |
| PT-SEC-032 | Tracking params cannot bypass pin identity |
