# Telegram URL Tests

Automated file: `packages/download_engine/test/telegram_url_test.dart` (38 tests)

| ID | Case |
|----|------|
| TG-URL-001 | `t.me` is Telegram |
| TG-URL-002 | `www.t.me` |
| TG-URL-003 | `telegram.me` |
| TG-URL-004 | `telegram.org` |
| TG-URL-005 | `tg://` |
| TG-URL-006 | `telesco.pe` CDN |
| TG-URL-006b | `cdn.telegram.org` CDN |
| TG-URL-006c | `telegram://` |
| TG-URL-007 | example.com is not Telegram |
| TG-URL-008 | youtube.com is not Telegram |
| TG-URL-020 | `/` → HOME |
| TG-URL-021 | `/{channel}` → CHANNEL |
| TG-URL-022 | `/{channel}/{id}` → MESSAGE |
| TG-URL-023 | `/s/{channel}` → PUBLIC_CHANNEL_PREVIEW |
| TG-URL-024 | `/s/{channel}/{id}` → PUBLIC_MESSAGE_PREVIEW |
| TG-URL-025 | `/c/{id}/{msg}` → PRIVATE_MESSAGE |
| TG-URL-026–027 | invite / joinchat → INVITE |
| TG-URL-028 | `/share/` → SHARE |
| TG-URL-029 | `/addstickers/` → STICKERS |
| TG-URL-030 | `/iv` → INSTANT_VIEW |
| TG-URL-031 | CDN → DIRECT_MEDIA |
| TG-URL-032 | invalid message path → NON_CONTENT |
| TG-URL-033–036 | `tg://resolve` / join / invalid |
| TG-URL-040–050 | IDs, normalize, identity, downloadable / restricted / auth flags |

| ID | Case |
|----|------|
| TG-URL-001 | `t.me` is Telegram |
| TG-URL-002 | `www.t.me` |
| TG-URL-003 | `telegram.me` |
| TG-URL-004 | `telegram.org` |
| TG-URL-005 | `tg://` |
| TG-URL-006 | `telesco.pe` CDN |
| TG-URL-007 | example.com is not Telegram |
| TG-URL-008 | youtube.com is not Telegram |
| TG-URL-020 | `/` → HOME |
| TG-URL-021 | `/{channel}` → CHANNEL |
| TG-URL-022 | `/{channel}/{id}` → MESSAGE |
| TG-URL-023 | `/s/{channel}` → PUBLIC_CHANNEL_PREVIEW |
| TG-URL-024 | `/s/{channel}/{id}` → PUBLIC_MESSAGE_PREVIEW |
| TG-URL-025 | `/c/{id}/{msg}` → PRIVATE_MESSAGE |
| TG-URL-026–027 | invite / joinchat → INVITE |
| TG-URL-028 | `/share/` → SHARE |
| TG-URL-029 | `/addstickers/` → STICKERS |
| TG-URL-030 | `/iv` → INSTANT_VIEW |
| TG-URL-031 | CDN → DIRECT_MEDIA |
| TG-URL-032 | invalid message path → NON_CONTENT |
| TG-URL-033–036 | `tg://resolve` / join / invalid |
| TG-URL-040–050 | IDs, normalize, identity, downloadable / restricted flags |
