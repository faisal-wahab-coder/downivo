# WhatsApp Security Tests

Automated file: `packages/download_engine/test/whatsapp_security_test.dart` (22 tests)

| ID | Case |
|----|------|
| WA-SEC-001 | `javascript:` rejected |
| WA-SEC-002 | `file:` rejected |
| WA-SEC-003 | `data:` rejected |
| WA-SEC-004 | HTTPS WhatsApp URL accepted |
| WA-SEC-005 | `whatsapp://send` normalized to https |
| WA-SEC-006 | `whatsapp://chat` rejected (invitation) |
| WA-SEC-010–014 | localhost / 127.0.0.1 / LAN / 10.x / example.com not WhatsApp |
| WA-SEC-020–024 | Filename sanitization, unicode, emoji |
| WA-SEC-030 | `wa.me` is not a direct media URL |
| WA-SEC-031 | javascript media rejected |
| WA-SEC-032 | localhost media rejected |
| WA-SEC-033 | Encoded wa.me still classifies |
| WA-SEC-034 | Encrypted `mmg` never downloadable |
| WA-SEC-035 | Invite never downloadable |
