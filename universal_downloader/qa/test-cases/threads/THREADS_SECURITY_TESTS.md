# Threads Security Tests

Automated file: `packages/download_engine/test/threads_security_test.dart` (21 tests)

| ID | Case |
|----|------|
| TH-SEC-001–003 | `javascript:` / `file:` / `data:` rejected |
| TH-SEC-004–005 | https threads.net / threads.com accepted |
| TH-SEC-010–014 | localhost / 127.0.0.1 / LAN / example.com not Threads |
| TH-SEC-020–024 | Filename sanitization, path traversal, unicode |
| TH-SEC-030–035 | Page URLs / javascript / localhost / private IP not direct media |
