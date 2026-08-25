# LinkedIn Security Tests

Automated file: `packages/download_engine/test/linkedin_security_test.dart` (19 tests)

| ID | Case |
|----|------|
| LI-SEC-001 | `javascript:` rejected |
| LI-SEC-002 | `file:` rejected |
| LI-SEC-003 | `data:` rejected |
| LI-SEC-004 | https LinkedIn accepted |
| LI-SEC-010–014 | localhost / 127.0.0.1 / private IP / example.com not LinkedIn |
| LI-SEC-020–025 | Path traversal, invalid filename chars, unicode, long titles |
| LI-SEC-030–033 | Player page / HLS / javascript not direct media; encoded URN still parses |

`../../../../linkedin.mp4` must never escape application storage.
