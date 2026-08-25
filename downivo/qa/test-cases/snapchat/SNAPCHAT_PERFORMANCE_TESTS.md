# Snapchat Performance Tests

Automated file: `packages/download_engine/test/snapchat_performance_test.dart` (5 tests)

Do not load an entire Story or profile into memory. Resources are URL-only.

| ID | Case |
|----|------|
| SC-PERF-001 | 50-snap story parse stays URL-only |
| SC-PERF-002 | Parse is deterministic |
| SC-PERF-003 | Photo parse does not invent extra files |
| SC-PERF-004 | Identity stable under tracking params |
| SC-PERF-005 | Video parse returns a single URL resource |
