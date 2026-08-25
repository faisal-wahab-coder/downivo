# Vimeo Download Tests

## Test File
`packages/download_engine/test/vimeo_download_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-DL-001 | queued → preparing → downloading → verifying → completed |
| VM-DL-002 | pause / resume |
| VM-DL-003 | cancel |
| VM-DL-004 | failed → retry queued |
| VM-DL-010 / 011 | isActive |
| VM-DL-012 | bytesRemaining |
| VM-DL-020 | MIME → `.mp4` |
| VM-DL-021 | quality in filename |
| VM-DL-030 | DownloadStatus storage |
| VM-DL-040 | canonical + player identity |

Uses the shared Download Engine state machine (`DownloadStatus`). CREATED/STARTING in the product language map to `queued` / `preparing`.
