# Twitch VOD Tests

Automated file: `packages/download_engine/test/twitch_vod_test.dart` (6 tests)

| ID | Case |
|----|------|
| TW-VOD-001 | VOD URL classified; numeric id extracted |
| TW-VOD-002 | parseVideoInfo maps streamer, duration, category |
| TW-VOD-003 | Missing VOD is unavailable |
| TW-VOD-004 | Public VOD is HLS-only (not a file download) |
| TW-VOD-005 | HLS master qualities detected, not downloaded |
| TW-VOD-006 | discover does not return an m3u8 as a file |

VOD **file** download is a documented PLATFORM_LIMITATION. Metadata and identity are required and implemented.
