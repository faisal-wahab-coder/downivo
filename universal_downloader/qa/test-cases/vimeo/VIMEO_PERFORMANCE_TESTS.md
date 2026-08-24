# Vimeo Performance Tests

## Test File
`packages/download_engine/test/vimeo_performance_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-PERF-001 | Many qualities parsed without inventing extras |
| VM-PERF-002 | Deterministic parse |
| VM-PERF-003 | Single video → one resource |
| VM-PERF-004 | Identity loop (50×) |
| VM-PERF-005 | Parse stores URLs only — no media bytes |

Discovery never loads the video file into memory. Large-file streaming is the shared Download Engine.
