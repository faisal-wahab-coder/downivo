# File Manager Test Cases

Maps to `docs/17_File_Manager.md`.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| FM-001 | List and sort by name | Deterministic order | existing `media_library_service_test.dart` |
| FM-002 | Rename and delete | File moved / removed | existing |
| FM-003 | Rename collision | `ArgumentError` | `media_library_ops_test.dart` |
| FM-004 | Empty rename | `ArgumentError` | `media_library_ops_test.dart` |
| FM-005 | Move between categories | Path and category update | `media_library_ops_test.dart` |
| FM-006 | Import external copy | Source remains, dest created | `media_library_ops_test.dart` |
| FM-007 | Import to category (move) | Source gone | `media_library_ops_test.dart` |
| FM-008 | `fileAt` missing path | null | `media_library_ops_test.dart` |
| FM-009 | Browse nested folders | Folder + file counts | existing |
