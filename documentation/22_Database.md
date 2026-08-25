# 22. Database

**Package `database`.** sqflite ^2.4.2, path_provider, path. Web: `sqflite_common_ffi_web`.

`schemaVersion = 4`. Classes: `AppDatabase`, `DatabaseProvider`, `DownloadRecord`, platform `sqflite_init_*`. File name: `downivo.db`.

See 11.3 and 13.6 for SQL. `clearHistory` uses `deleteDownloadsWithStatuses` for COMPLETED, FAILED, CANCELLED.
