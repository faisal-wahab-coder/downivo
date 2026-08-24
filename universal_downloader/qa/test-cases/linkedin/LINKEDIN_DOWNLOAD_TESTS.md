# LinkedIn Download Tests

Automated file: `packages/download_engine/test/linkedin_download_test.dart` (10 tests)

Uses the **existing** Download Engine state machine (`queued` → `preparing` → `downloading` → `verifying` → `completed`). No LinkedIn-specific states.

| ID | Case |
|----|------|
| LI-DL-001 | Full success path |
| LI-DL-002 | Pause / resume |
| LI-DL-003 | Cancel |
| LI-DL-004 | Failed → retry queued |
| LI-DL-005 | Multi-image independent states |
| LI-DL-010 | `isActive` in-flight |
| LI-DL-011 | `isActive` false for terminal/paused |
| LI-DL-012 | `bytesRemaining` |
| LI-DL-013 | video/mp4 MIME |
| LI-DL-014 | application/pdf MIME |
