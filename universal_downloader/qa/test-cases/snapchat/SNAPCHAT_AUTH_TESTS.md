# Snapchat Auth Tests

Automated file: `packages/download_engine/test/snapchat_auth_test.dart` (7 tests)

The app has **no** official Snapchat login and **no** Public Profile API OAuth. Authenticated-only content must fail closed. Private/chat URLs are **RESTRICTED_CONTENT**, not authentication.

| ID | Case |
|----|------|
| SC-AUTH-001 | `/login` → AUTHENTICATION_REQUIRED |
| SC-AUTH-002 | Login-wall HTML → AUTHENTICATION_REQUIRED |
| SC-AUTH-003 | Resolver does not fetch login URLs |
| SC-AUTH-004 | Login HTML on a public URL is not downloaded |
| SC-AUTH-005 | Public Spotlight is PUBLIC |
| SC-AUTH-006 | `accounts.snapchat.com` is authentication |
| SC-AUTH-007 | Login is not downloadable |
