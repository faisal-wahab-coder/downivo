# Telegram Restriction Tests

Covered by `telegram_auth_test.dart` and `telegram_security_test.dart`.

Expected outcomes:

| Input | Result |
|-------|--------|
| `https://t.me/c/{id}/{msg}` | RESTRICTED_CONTENT, no fetch |
| `https://t.me/+invite` / `joinchat` | RESTRICTED_CONTENT, no fetch |
| `tg://join?invite=` | Rejected by UrlValidator |
| Login-wall HTML | AUTHENTICATION_REQUIRED |
| Deleted / unavailable HTML | CONTENT_UNAVAILABLE |

Do not bypass privacy controls, guess private IDs, or use stolen sessions.
