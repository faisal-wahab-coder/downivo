# Threads Download Tests

Automated file: `packages/download_engine/test/threads_download_test.dart` (10 tests)

Uses the existing global `DownloadStatus` state machine (no ThreadsDownloader).

| ID | Case |
|----|------|
| TH-DL-001 | queued → preparing → downloading → verifying → completed |
| TH-DL-002 | pause → resume → completed |
| TH-DL-003 | cancelled |
| TH-DL-004 | failed → retry queued |
| TH-DL-005 | restricted stays failed |
| TH-DL-006 | authentication stays failed |
| TH-DL-007 | text-only stays failed |
| TH-DL-008 | pause keeps received bytes |
| TH-DL-009 | completed is terminal |
| TH-DL-010 | cancelled is terminal |
