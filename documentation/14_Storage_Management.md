# 14. Storage Management

**Package:** `storage` (~23 Dart files)

## Public concepts

- `StorageCategory` enum with `folderName`
- `StoragePaths.resolve()` — IO / web / stub
- `StorageInitializer` — create tree
- `FileStore` — read/write/delete
- `StorageInfo` — volume stats (Android StatFs)

## Categories (exact folder names)

Videos, Images, Audio, Documents, Archives, APK, QR Downloads, Favorites, Vault, Temp, Logs

## UI

`StorageDashboard` on Home and Settings. Managed used bytes + optional volume totals. Path displayed from settings; **not** a folder picker.

## Web

Web file store / path resolve; dashboard hides volume when `hasVolumeStats` is false.
