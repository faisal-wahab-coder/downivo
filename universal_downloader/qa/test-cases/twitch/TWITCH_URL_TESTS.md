# Twitch URL Tests

Automated file: `packages/download_engine/test/twitch_url_test.dart` (35 tests)

| ID | Case |
|----|------|
| TW-URL-001 | `www.twitch.tv/{channel}` is Twitch |
| TW-URL-002 | `twitch.tv` without www |
| TW-URL-003 | `m.twitch.tv` |
| TW-URL-004 | `clips.twitch.tv` |
| TW-URL-005 | `player.twitch.tv` |
| TW-URL-006 | Home is Twitch |
| TW-URL-007 | example.com is not Twitch |
| TW-URL-008 | youtube.com is not Twitch |
| TW-URL-009 | vimeo.com is not Twitch |
| TW-URL-020 | Home → HOME |
| TW-URL-021 | Channel → CHANNEL |
| TW-URL-022 | `/videos/{id}` → VOD |
| TW-URL-023 | `/{login}/video/{id}` → VOD |
| TW-URL-024 | clips host → CLIP |
| TW-URL-025 | `/{login}/clip/{slug}` → CLIP |
| TW-URL-026 | `/directory` → DIRECTORY |
| TW-URL-027 | player `?video=` → VOD |
| TW-URL-028 | player `?channel=` → CHANNEL |
| TW-URL-029 | player `?clip=` → CLIP |
| TW-URL-030 | `/search` → NON_CONTENT |
| TW-URL-040–046 | VOD id, v-prefix, clip slug, channel login, INVALID, home |
| TW-URL-050–057 | Normalize, identity, downloadable=clips only |
