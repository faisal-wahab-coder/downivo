# WhatsApp Resolver Tests

Automated file: `packages/download_engine/test/whatsapp_resolver_test.dart` (11 tests)

| ID | Case |
|----|------|
| WA-RES-001 | Public Channel HTML yields an image |
| WA-RES-002 | discover uses mocked Channel HTML |
| WA-RES-003 | Chat link is not discovered |
| WA-RES-004 | Invite URL is not fetched |
| WA-RES-005 | Registry skips home / chat / invite / web |
| WA-RES-006 | Registry discovers a public Channel image |
| WA-RES-007 | Filename is sanitized from title |
| WA-RES-008 | Public CDN URL is downloadable |
| WA-RES-009 | Text-only Channel HTML yields no media |
| WA-RES-010 | Private HTML is not parsed as media |
| WA-RES-011 | Encrypted `mmg` URL is not downloaded |
