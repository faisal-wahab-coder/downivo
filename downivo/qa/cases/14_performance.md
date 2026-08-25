# Performance Test Cases

Maps to NFR-001–005 and `docs/24_Testing.md` §20.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| PF-001 | TimedCache TTL expiry | Entry gone after TTL | existing `performance_test.dart` |
| PF-002 | LRU eviction | Oldest dropped | existing |
| PF-003 | ThrottleGate | Suppresses bursts | existing |
| PF-004 | Library list of 200 files | Completes under 1 s | `media_library_ops_test.dart` |
| PF-005 | Cold start (device) | ≤ 2 s mid-range Android | Manual — `QA_CHECKLIST.md` |
