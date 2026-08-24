# Snapchat Restriction Tests

Automated file: `packages/download_engine/test/snapchat_restriction_test.dart` (6 tests)

Expected outcomes:

| Input | Result |
|-------|--------|
| `https://www.snapchat.com/chat` | RESTRICTED_CONTENT, no fetch |
| `https://www.snapchat.com/memories` | RESTRICTED_CONTENT, no fetch |
| `snapchat://chat` / `snap://memories` | Rejected by UrlValidator |
| Private / friends-only HTML | RESTRICTED_CONTENT |
| Login-wall HTML | AUTHENTICATION_REQUIRED (see auth tests) |

Do not bypass privacy controls, scrape private Stories, or use stolen sessions.
