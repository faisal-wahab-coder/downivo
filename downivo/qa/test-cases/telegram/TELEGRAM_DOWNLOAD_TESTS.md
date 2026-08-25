# Telegram Download Tests

Automated file: `packages/download_engine/test/telegram_download_test.dart` (10 tests)

Uses the existing global download state machine. No Telegram-specific downloader.

| ID | Case |
|----|------|
| TG-DL-001 | queued → preparing → downloading → verifying → completed |
| TG-DL-002 | pause → resume → completed |
| TG-DL-003 | cancel |
| TG-DL-004 | failed → retry queued |
| TG-DL-005 | album items have independent states |
| TG-DL-010–014 | isActive, bytesRemaining, MIME |
