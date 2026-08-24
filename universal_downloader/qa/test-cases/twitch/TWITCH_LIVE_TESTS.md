# Twitch Live Tests

Automated file: `packages/download_engine/test/twitch_live_test.dart` (5 tests)

| ID | Case |
|----|------|
| TW-LIVE-001 | Live user has title, category, thumbnail, viewer count |
| TW-LIVE-002 | Offline user is not live |
| TW-LIVE-003 | Missing user is null |
| TW-LIVE-004 | Live channel URL is not downloadable |
| TW-LIVE-005 | discover never starts a live recording |

Live recording is **NOT_REQUIRED** by project documentation. Detection is implemented; auto-download is forbidden.
