# Snapchat Security Tests

Automated file: `packages/download_engine/test/snapchat_security_test.dart` (21 tests)

| ID | Case |
|----|------|
| SC-SEC-001–003 | javascript: / file: / data: rejected |
| SC-SEC-004 | https Snapchat accepted |
| SC-SEC-005 | Public `snapchat://spotlight` normalized to https |
| SC-SEC-006 | `snapchat://chat` rejected safely |
| SC-SEC-006b | `snap://memories` rejected safely |
| SC-SEC-010–014 | localhost / 127.0.0.1 / private IP / example.com |
| SC-SEC-020–023 | Path traversal and invalid filename characters |
| SC-SEC-030–034 | Media URL safety; `/chat` never downloadable |
