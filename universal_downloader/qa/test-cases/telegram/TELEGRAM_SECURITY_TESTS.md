# Telegram Security Tests

Automated file: `packages/download_engine/test/telegram_security_test.dart` (21 tests)

| ID | Case |
|----|------|
| TG-SEC-001–003 | javascript: / file: / data: rejected |
| TG-SEC-004 | https Telegram accepted |
| TG-SEC-005 | Public `tg://resolve` normalized to https |
| TG-SEC-006 | `tg://join` rejected safely |
| TG-SEC-006b | `telegram://join` rejected safely |
| TG-SEC-010–014 | localhost / 127.0.0.1 / private IP / example.com |
| TG-SEC-020–023 | Path traversal and invalid filename characters |
| TG-SEC-030–034 | Media URL safety; `/c/` never downloadable |
