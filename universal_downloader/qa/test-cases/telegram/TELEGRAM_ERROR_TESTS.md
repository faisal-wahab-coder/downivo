# Telegram Error Tests

Automated file: `packages/download_engine/test/telegram_error_test.dart` (21 tests)

| ID | Case |
|----|------|
| TG-ERR-001–008 | HTTP 403/404/429/500/502/503, connection, timeout → empty |
| TG-ERR-010–013 | Invalid channel/message, home, unavailable HTML |
| TG-ERR-020–025 | Shared DownloadErrorFormatter (no stack traces) |
| TG-ERR-026 | Home user message |
| TG-ERR-027 | Text-only user message |
| TG-ERR-028 | Text-only discover fails without a download |
