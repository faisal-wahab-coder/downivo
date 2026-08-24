# Telegram Auth Tests

Automated file: `packages/download_engine/test/telegram_auth_test.dart` (11 tests)

The app has **no** official Telegram login. Authenticated-only content must fail closed. Private/invite URLs are **RESTRICTED_CONTENT**, not authentication.

| ID | Case |
|----|------|
| TG-AUTH-001 | `/c/` → RESTRICTED_CONTENT |
| TG-AUTH-002 | Invite → RESTRICTED_CONTENT |
| TG-AUTH-003 | Private HTML → restricted |
| TG-AUTH-004 | Login wall → AUTHENTICATION_REQUIRED |
| TG-AUTH-005 | Resolver does not fetch private URLs |
| TG-AUTH-006 | Resolver does not fetch invite URLs |
| TG-AUTH-007 | Deleted post → UNAVAILABLE |
| TG-AUTH-008 | Public photo → PUBLIC |
| TG-AUTH-009 | Login HTML on a public message URL is not downloaded |
| TG-AUTH-010 | Unavailable HTML is not downloaded |
| TG-AUTH-011 | `t.me/login` → AUTHENTICATION_REQUIRED |
