# Repository QA Audit

Date: 2026-08-15  
Scope: `universal_downloader/` Flutter monorepo  
Source of truth: `docs/24_Testing.md`, `docs/15_Download_Engine.md`, `docs/04_Non_Functional_Requirements.md`

## Snapshot

| Metric | Value |
|--------|-------|
| Melos packages | 16 |
| Existing `*_test.dart` before this QA pass | 17 |
| Packages with no tests before this pass | design_system, navigation, notifications, permissions, shared_types |
| Integration tests before this pass | 1 (`download_history_integration_test.dart`) |
| Shared test helpers | Inline `_FakePathProvider` only |
| HTTP fixture server | None |

## Coverage by domain

| Domain | Before | Gap |
|--------|--------|-----|
| Download lifecycle (pause/resume/cancel/retry/range) | Untested on `DownloadManager` | Critical |
| Filename / URL validation | Partial (happy path) | Path traversal, bad schemes |
| Recovery after crash | `recovery_test.dart` only copies a task | Does not call `loadFromDatabase` |
| Storage paths | Category folder creation | `resolve`, initializer, info |
| Database | Schema + delete-by-status | CRUD, metadata, v1→v2 migration |
| File manager | list/rename/delete/favorites/browse | move, import, summaries, search |
| Browser | URL normalize + download detect | Tabs, history, bookmarks, CDN hosts |
| Clipboard / Share / QR | Analyzer + partial QR | Monitor, history stores, share parser |
| Notifications / Permissions | None | Action dispatch, clipboard grant |
| Security | None | Scheme reject, HTML reject, traversal |
| Performance | Cache/throttle primitives | Library scan smoke |
| Background coordinator | Helper-only test | Platform-heavy; deferred |

## CI

`scripts/ci.sh` runs `flutter analyze` on all packages and `flutter test` when `test/` exists. Live social discovery (`SOCIAL_LIVE_TEST=1`) is not enabled in CI.

## Decisions

- Automated tests live in package `test/` dirs so Melos/CI pick them up.
- HTTP fixtures use an in-process `udm_qa_server` (also runnable as a CLI).
- Manual Play-store sign-off stays in `QA_CHECKLIST.md`.
- `BackgroundDownloadCoordinator` and platform WebView remain device/manual until a foreground-task fake exists.
- `UrlValidator` allows localhost so the QA server can drive real downloads. Private-IP SSRF hardening is an open product gap, not silently changed here.
