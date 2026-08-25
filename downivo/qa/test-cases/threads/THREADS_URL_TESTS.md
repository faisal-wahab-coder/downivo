# Threads URL Tests

Automated file: `packages/download_engine/test/threads_url_test.dart` (28 tests)

| ID | Case |
|----|------|
| TH-URL-001 | `threads.net` is Threads |
| TH-URL-002 | `www.threads.net` |
| TH-URL-003 | `threads.com` is Threads |
| TH-URL-004 | `www.threads.com` |
| TH-URL-005 | `l.threads.net` share host |
| TH-URL-006 | example.com is not Threads |
| TH-URL-007 | youtube.com is not Threads |
| TH-URL-008 | instagram.com is not Threads |
| TH-URL-020 | `/` → HOME |
| TH-URL-021 | `/@{user}` → PROFILE |
| TH-URL-022–023 | `/@user/post/{id}` on .net and .com → POST |
| TH-URL-024 | `/t/{id}` → POST |
| TH-URL-025 | embed → EMBED |
| TH-URL-026 | share host → SHARE |
| TH-URL-027 | `/login` → AUTHENTICATION |
| TH-URL-028 | `/INVALID` → NON_CONTENT |
| TH-URL-029 | `/search` → NON_CONTENT |
| TH-URL-040–043 | Post ID / username extraction |
| TH-URL-050–055 | Normalize, identity, downloadable flags |
