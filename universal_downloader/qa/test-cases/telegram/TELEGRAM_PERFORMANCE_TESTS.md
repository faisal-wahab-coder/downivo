# Telegram Performance Tests

Automated file: `packages/download_engine/test/telegram_performance_test.dart` (5 tests)

| ID | Case |
|----|------|
| TG-PERF-001 | 50-item album parse stays URL-only |
| TG-PERF-002 | Parse is deterministic |
| TG-PERF-003 | Photo parse does not invent extra files |
| TG-PERF-004 | Identity stable under tracking params |
| TG-PERF-005 | Video parse returns a single URL resource |

Do not load entire media collections into memory. Resources are URL metadata only until the Download Engine streams the file.
