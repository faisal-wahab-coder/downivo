# Pinterest Download Tests

## Test File
`packages/download_engine/test/pinterest_download_test.dart`

Uses the shared Download Engine state machine (`DownloadTask` / `DownloadStatus`).

| ID | Case |
|----|------|
| PT-DL-001 | queued → preparing → downloading → verifying → completed |
| PT-DL-002 | pause / resume |
| PT-DL-003 | cancel |
| PT-DL-004 | failed → retry queued |
| PT-DL-005 | Idea Pin items have independent states |
| PT-DL-010–012 | isActive, bytesRemaining |
| PT-DL-020–023 | MIME → extension (mp4, jpg, webp, png) |
| PT-DL-030 | DownloadStatus storage round-trip |
