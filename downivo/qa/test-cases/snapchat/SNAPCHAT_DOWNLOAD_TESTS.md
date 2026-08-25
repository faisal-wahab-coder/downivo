# Snapchat Download Tests

Automated file: `packages/download_engine/test/snapchat_download_test.dart` (10 tests)

Uses the existing global download state machine. There is no SnapchatDownloader.

| ID | Case |
|----|------|
| SC-DL-001 | queued → preparing → downloading → verifying → completed |
| SC-DL-002 | pause / resume |
| SC-DL-003 | cancel |
| SC-DL-004 | failed → retry queued |
| SC-DL-005 | Story snaps have independent states |
| SC-DL-010–014 | isActive, bytesRemaining, MIME |
