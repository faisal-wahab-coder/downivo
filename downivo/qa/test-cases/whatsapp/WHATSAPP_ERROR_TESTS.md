# WhatsApp Error Tests

Automated file: `packages/download_engine/test/whatsapp_error_test.dart` (26 tests)

| ID | Case |
|----|------|
| WA-ERR-001–006 | HTTP 403 / 404 / 429 / 500 / 502 / 503 → empty |
| WA-ERR-007 | Connection error → empty |
| WA-ERR-008 | Timeout → empty |
| WA-ERR-010 | `wa.me/INVALID` → empty |
| WA-ERR-011 | `whatsapp.com/INVALID` → empty |
| WA-ERR-012 | Home → empty |
| WA-ERR-013 | Unavailable HTML → empty |
| WA-ERR-020–025 | Error formatter (403/404/429/timeout/network/no stack) |
| WA-ERR-026 | Home user message |
| WA-ERR-027 | Chat link: “WhatsApp link detected” |
| WA-ERR-028 | Text-only Channel: no downloadable media |
| WA-ERR-029 | Invite: group invitation |
| WA-ERR-030 | Web: authentication required |
| WA-ERR-031 | Invalid WhatsApp URL |
| WA-ERR-032 | Disappeared content unavailable |
| WA-ERR-033 | Login HTML is not downloaded |
