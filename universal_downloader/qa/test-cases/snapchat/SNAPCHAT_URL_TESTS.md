# Snapchat URL Tests

Automated file: `packages/download_engine/test/snapchat_url_test.dart` (40 tests)

| ID | Case |
|----|------|
| SC-URL-001 | `snapchat.com` is Snapchat |
| SC-URL-002 | `www.snapchat.com` |
| SC-URL-003 | `t.snapchat.com` |
| SC-URL-004 | `story.snapchat.com` |
| SC-URL-005 | `snapchat://` |
| SC-URL-006 | `sc-cdn.net` CDN |
| SC-URL-006b | `snap://` |
| SC-URL-007 | example.com is not Snapchat |
| SC-URL-008 | youtube.com is not Snapchat |
| SC-URL-020 | `/` → HOME |
| SC-URL-021 | `/@{user}` → PUBLIC_PROFILE |
| SC-URL-022 | `/add/{user}` → PUBLIC_PROFILE |
| SC-URL-023 | `/p/{id}` → PUBLIC_PROFILE |
| SC-URL-024 | `/spotlight/{id}` → SPOTLIGHT |
| SC-URL-025 | `/spotlight` → SPOTLIGHT_FEED |
| SC-URL-026 | story host → PUBLIC_STORY |
| SC-URL-027 | highlights → SAVED_STORY |
| SC-URL-028–029 | share URLs → SHARE |
| SC-URL-030 | embed → EMBED |
| SC-URL-031 | CDN → DIRECT_MEDIA |
| SC-URL-032 | `/INVALID` → NON_CONTENT |
| SC-URL-033 | `/chat` → PRIVATE |
| SC-URL-034 | `/login` → AUTHENTICATION |
| SC-URL-035–038 | `snapchat://add` / spotlight / chat / snap |
| SC-URL-040–051 | IDs, normalize, identity, downloadable / restricted / auth flags |
