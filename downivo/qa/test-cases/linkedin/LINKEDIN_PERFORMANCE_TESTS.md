# LinkedIn Performance Tests

Automated file: `packages/download_engine/test/linkedin_performance_test.dart` (5 tests)

Resolver returns **URLs only** — full-resolution binaries are not loaded into memory.

| ID | Case |
|----|------|
| LI-PERF-001 | 50-image carousel parse, unique URLs/names |
| LI-PERF-002 | Deterministic parse |
| LI-PERF-003 | Single image is one resource |
| LI-PERF-004 | Identity loop is stable |
| LI-PERF-005 | Parse does not embed binary media |
