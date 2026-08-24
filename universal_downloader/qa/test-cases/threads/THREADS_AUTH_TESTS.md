# Threads Auth Tests

Automated file: `packages/download_engine/test/threads_auth_test.dart` (6 tests)

There is **no** authorized Threads login in the app. Authenticated-only content returns AUTHENTICATION_REQUIRED. No session/cookie/token bypass.

| ID | Case |
|----|------|
| TH-AUTH-001 | `/login` is AUTHENTICATION_REQUIRED |
| TH-AUTH-002 | Login-wall HTML is AUTHENTICATION_REQUIRED |
| TH-AUTH-003 | Resolver does not fetch login URLs |
| TH-AUTH-004 | Login HTML on a public URL is not downloaded |
| TH-AUTH-005 | Public post is PUBLIC |
| TH-AUTH-006 | No official Threads login exists |
