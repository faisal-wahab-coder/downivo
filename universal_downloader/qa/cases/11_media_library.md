# Media Library / Search Test Cases

Maps to `docs/13.7` and FR-045.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| ML-001 | Search by name substring | Matching files only | `media_library_ops_test.dart` |
| ML-002 | Category summaries | Counts and bytes | `media_library_ops_test.dart` |
| ML-003 | Total managed bytes/count | Sum across categories | `media_library_ops_test.dart` |
| ML-004 | Date filter today | Recent files only | `media_library_ops_test.dart` |
| ML-005 | Acknowledge imports | Pending list empty | `media_library_ops_test.dart` |
| ML-006 | Scan cache hit | Second list is a hit | existing |
