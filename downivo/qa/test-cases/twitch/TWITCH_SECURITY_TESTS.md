# Twitch Security Tests

Automated file: `packages/download_engine/test/twitch_security_test.dart` (19 tests)

| ID | Case |
|----|------|
| TW-SEC-001 | javascript: rejected |
| TW-SEC-002 | file: rejected |
| TW-SEC-003 | data: rejected |
| TW-SEC-004 | https Twitch URL accepted |
| TW-SEC-010 | localhost is not Twitch |
| TW-SEC-011 | 127.0.0.1 is not Twitch |
| TW-SEC-012 | Private LAN is not Twitch |
| TW-SEC-013 | 10.x is not Twitch |
| TW-SEC-014 | example.com is not Twitch |
| TW-SEC-020 | Path traversal sanitized |
| TW-SEC-021 | Slash and colon stripped |
| TW-SEC-022 | Quotes and pipes stripped |
| TW-SEC-023 | Filename cannot escape directory |
| TW-SEC-024 | Emoji title sanitized |
| TW-SEC-025 | Very long title truncated |
| TW-SEC-026 | Arabic title kept as safe filename |
| TW-SEC-030 | Encoded `..` is not a channel login |
| TW-SEC-031 | Very long URL still classifies a clip |
| TW-SEC-032 | Tracking params cannot bypass identity |

Playback tokens are appended to media URLs and are not logged.
