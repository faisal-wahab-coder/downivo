# Telegram Implementation Audit

Canonical copy: [`qa/test-reports/TELEGRAM_IMPLEMENTATION_AUDIT.md`](../../test-reports/TELEGRAM_IMPLEMENTATION_AUDIT.md)

Telegram is **IMPLEMENTED** for public `t.me` / `t.me/s` / `tg://resolve` / `telegram://resolve` media. Private `/c/` and invites are **RESTRICTED_CONTENT**. Login walls and `t.me/login` are **AUTHENTICATION_REQUIRED**. There is no Telegram-specific downloader. Restricted and authentication-required failures are not retried.
