# Threads Performance Tests

Automated file: `packages/download_engine/test/threads_performance_test.dart` (5 tests)

Carousel items are URL references only. Media bytes are never loaded into memory during resolve.

| ID | Case |
|----|------|
| TH-PERF-001 | 50-item carousel stays URL-only |
| TH-PERF-002 | Parse is deterministic |
| TH-PERF-003 | Image parse does not invent extra files |
| TH-PERF-004 | Identity stable under tracking params |
| TH-PERF-005 | Video parse returns a single URL resource |
