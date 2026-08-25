# Twitch Performance Tests

Automated file: `packages/download_engine/test/twitch_performance_test.dart` (6 tests)

| ID | Case |
|----|------|
| TW-PERF-001 | Many clip qualities do not invent extra items |
| TW-PERF-002 | Parse is deterministic |
| TW-PERF-003 | Single clip stays one resource |
| TW-PERF-004 | Identity computation is cheap and stable |
| TW-PERF-005 | Parse does not load media bytes |
| TW-PERF-006 | HLS master parse is URL-only |

Resolver returns URLs only. The Download Engine streams files incrementally. Entire VODs/clips are never buffered in memory by the provider.
