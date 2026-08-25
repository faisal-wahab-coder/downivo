# Database Test Cases

Maps to `docs/22_Database.md` and `docs/13.6`.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| DB-001 | Schema create + initialized flag | `isInitialized` true | `database_test.dart` |
| DB-002 | Insert / getById / update / delete | Round-trip fields | `database_test.dart` |
| DB-003 | Delete by status | Only matching rows removed | `database_test.dart` |
| DB-004 | Metadata get/set | Queue-order key persists | `database_test.dart` |
| DB-005 | v1 → v2 upgrade | Rows kept, new indexes present | `database_test.dart` |
| DB-006 | `DownloadRecord.fromMap` | Null-safe defaults | `database_test.dart` |
