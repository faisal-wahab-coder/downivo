# LinkedIn URL Tests

Automated file: `packages/download_engine/test/linkedin_url_test.dart` (37 tests)

| ID | Case |
|----|------|
| LI-URL-001 | `www.linkedin.com` is LinkedIn |
| LI-URL-002 | `linkedin.com` without www |
| LI-URL-003 | `m.linkedin.com` |
| LI-URL-004 | `lnkd.in` short URL |
| LI-URL-005 | `media.licdn.com` |
| LI-URL-006 | `dms.licdn.com` |
| LI-URL-007 | example.com is not LinkedIn |
| LI-URL-008 | youtube.com is not LinkedIn |
| LI-URL-020 | `/` → HOME |
| LI-URL-021 | `/feed/` → FEED |
| LI-URL-022 | `/posts/...` → POST |
| LI-URL-023 | feed update URN → POST |
| LI-URL-024 | ugcPost URN → POST |
| LI-URL-025 | `/embed/` → EMBED |
| LI-URL-026 | `/pulse/` → ARTICLE |
| LI-URL-027 | `/in/` → PROFILE |
| LI-URL-028 | `/company/` → COMPANY |
| LI-URL-029 | `lnkd.in` → SHORT_URL |
| LI-URL-030 | licdn CDN → DIRECT_MEDIA |
| LI-URL-031 | `/video/` → VIDEO |
| LI-URL-032 | `/posts/` empty → NON_CONTENT |
| LI-URL-033 | `/jobs/` → JOBS |
| LI-URL-034 | `/mwlite/in/` → PROFILE |
| LI-URL-040–047 | Activity / ugcPost / share IDs, author, company |
| LI-URL-050–055 | Identity, tracking strip, downloadable flags, embed targets |
