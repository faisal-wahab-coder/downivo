# Pinterest Performance Tests

## Test File
`packages/download_engine/test/pinterest_performance_test.dart`

| ID | Case |
|----|------|
| PT-PERF-001 | 50-page Idea Pin parse (no collapsed items, unique URLs) |
| PT-PERF-002 | Deterministic parse |
| PT-PERF-003 | Small image is a single resource |
| PT-PERF-004 | Identity computation stable |

Resources are URL metadata only — full-resolution files are not loaded into memory during discovery.
