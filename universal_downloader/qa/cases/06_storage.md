# Storage Test Cases

Maps to `docs/14_Storage_Management.md`.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| ST-001 | Category paths under root | All `StorageCategory` folders resolvable | `storage_test.dart` |
| ST-002 | `StorageInitializer` is idempotent | Second run does not throw | `storage_test.dart` |
| ST-003 | `StoragePaths.resolve` shape | `Downloads/Universal Downloader` | `storage_test.dart` |
| ST-004 | `allCategoryPaths` count | Matches enum length | `storage_test.dart` |
| ST-005 | Zero free space label | `Calculating…` | `storage_test.dart` |
