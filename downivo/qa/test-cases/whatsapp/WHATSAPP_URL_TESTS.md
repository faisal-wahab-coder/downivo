# WhatsApp URL Tests

Automated file: `packages/download_engine/test/whatsapp_url_test.dart` (38 tests)

| ID | Case |
|----|------|
| WA-URL-001 | `wa.me` is WhatsApp |
| WA-URL-002 | `www.whatsapp.com` |
| WA-URL-003 | `whatsapp.com` |
| WA-URL-004 | `chat.whatsapp.com` |
| WA-URL-005 | `web.whatsapp.com` |
| WA-URL-006 | `api.whatsapp.com` |
| WA-URL-007 | `whatsapp://` |
| WA-URL-008 | `/channel/{id}` |
| WA-URL-009 | example.com is not WhatsApp |
| WA-URL-010 | youtube.com is not WhatsApp |
| WA-URL-020 | `/` → HOME |
| WA-URL-021 | `wa.me/{phone}` → CHAT_LINK |
| WA-URL-022 | `wa.me/{phone}?text=` → CHAT_LINK |
| WA-URL-023 | invite → GROUP_INVITE |
| WA-URL-024 | `/channel/{id}` → PUBLIC_CHANNEL |
| WA-URL-025 | `/channel/{id}/{post}` → PUBLIC_CHANNEL_POST |
| WA-URL-026 | Web → WHATSAPP_WEB |
| WA-URL-027 | `wa.me/INVALID` → INVALID |
| WA-URL-028 | `whatsapp.com/INVALID` → INVALID |
| WA-URL-029 | `mmg.whatsapp.net` → PRIVATE_MEDIA |
| WA-URL-030 | public CDN → DIRECT_MEDIA |
| WA-URL-031 | `wa.me/message/{code}` → BUSINESS_CHAT |
| WA-URL-032–034 | `whatsapp://send` / chat / call |
| WA-URL-040–052 | Phone, text, normalize, identity, downloadable / restricted / auth flags |
