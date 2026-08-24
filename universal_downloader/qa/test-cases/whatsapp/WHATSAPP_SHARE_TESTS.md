# WhatsApp Share Tests

Automated file: `packages/download_engine/test/whatsapp_share_test.dart` (9 tests)

| ID | Case |
|----|------|
| WA-SHARE-001 | `IMG-…jpg` → IMAGE |
| WA-SHARE-002 | `VID-…mp4` → VIDEO |
| WA-SHARE-003 | `AUD-…mp3` → AUDIO |
| WA-SHARE-004 | `PTT-…opus` → VOICE_NOTE |
| WA-SHARE-005 | PDF → PDF |
| WA-SHARE-006 | ZIP → ARCHIVE |
| WA-SHARE-007 | vCard → CONTACT (not auto-saved) |
| WA-SHARE-008 | Shared filename sanitization |
| WA-SHARE-009 | Multiple files keep independent types |
