# database

SQLite metadata storage for Universal Downloader.

## M1 schema (v1)

- `downloads` — download queue records per `docs/13.6_Download_Database_Schema.md`
- `app_metadata` — initialization flags and future config keys

## Note

Uses `sqflite` directly in M1. Drift code generation will be adopted when build_runner supports the project Dart SDK (ADR-002).
