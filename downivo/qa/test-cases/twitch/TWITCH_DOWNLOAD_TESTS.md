# Twitch Download Tests

Automated file: `packages/download_engine/test/twitch_download_test.dart` (11 tests)

| ID | Case |
|----|------|
| TW-DL-001 | queued → preparing → downloading → verifying → completed |
| TW-DL-002 | downloading → paused → downloading → completed |
| TW-DL-003 | downloading → cancelled |
| TW-DL-004 | failed → retry queued |
| TW-DL-010 | isActive for in-flight states |
| TW-DL-011 | isActive false for terminal/paused |
| TW-DL-012 | bytesRemaining |
| TW-DL-020 | video MIME → .mp4 |
| TW-DL-021 | quality encoded in filename |
| TW-DL-030 | DownloadStatus storage round-trip |
| TW-DL-040 | Canonical and share URLs share identity |

Twitch uses the shared Download Engine. There is no Twitch-specific downloader.
