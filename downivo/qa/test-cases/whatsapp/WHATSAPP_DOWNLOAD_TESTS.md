# WhatsApp Download Tests

Automated file: `packages/download_engine/test/whatsapp_download_test.dart` (10 tests)

| ID | Case |
|----|------|
| WA-DL-001 | queued → preparing → downloading → verifying → completed |
| WA-DL-002 | pause at 20% then resume |
| WA-DL-003 | cancel |
| WA-DL-004 | failed → retry queued |
| WA-DL-005 | multi-file share independent states |
| WA-DL-010 | isActive for in-flight states |
| WA-DL-011 | isActive false for terminal/paused |
| WA-DL-012 | bytesRemaining |
| WA-DL-013 | video MIME stays video/mp4 |
| WA-DL-014 | voice MIME stays audio/ogg |
