# Twitch Metadata Tests

Automated file: `packages/download_engine/test/twitch_metadata_test.dart` (10 tests)

| ID | Case |
|----|------|
| TW-META-001 | Public clip fields (title, channel, creator, category, duration, thumb, date, URL) |
| TW-META-002 | Missing title is not fabricated |
| TW-META-003 | Missing description is not fabricated |
| TW-META-004 | Description used when present |
| TW-META-005 | VOD metadata without inventing quality files |
| TW-META-006 | Highlight `broadcastType` |
| TW-META-007 | Live channel metadata |
| TW-META-008 | Offline channel does not invent live title |
| TW-META-009 | Resource title and platform |
| TW-META-010 | MIME mapping (mp4 vs m3u8) |
