# Twitch Resolver Tests

Automated file: `packages/download_engine/test/twitch_resolver_test.dart` (12 tests)

| ID | Case |
|----|------|
| TW-RES-001 | Discovers clip MP4 from GQL |
| TW-RES-002 | Home returns empty |
| TW-RES-003 | Channel returns empty |
| TW-RES-004 | VOD returns empty (HLS-only) |
| TW-RES-005 | Channel clip path resolves the same clip |
| TW-RES-006 | Missing clip returns null |
| TW-RES-007 | Directory returns empty |
| TW-RES-008 | Registry uses TwitchResolver |
| TW-RES-009 | Registry does not scrape home HTML |
| TW-RES-010 | Signed clip URL includes sig and token |
| TW-RES-011 | discoverAll returns a single clip |
| TW-RES-012 | Filename includes quality suffix |
