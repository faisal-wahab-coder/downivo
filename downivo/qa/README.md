# Downivo QA

Production QA system for the Flutter monorepo. Implements `docs/24_Testing.md` against the current packages.

## Pipeline

1. Repository QA Audit — `01_audit/REPOSITORY_QA_AUDIT.md`
2. Folder structure — this directory
3. Download test cases — `cases/03_download.md`
4. Download test server — `server/`
5. Download automated tests — `packages/download_engine/test/`
6. Storage tests — `cases/06_storage.md` + `packages/storage/test/`
7. Database tests — `cases/07_database.md` + `packages/database/test/`
8. File manager tests — `cases/08_file_manager.md` + `packages/media_library/test/`
9. Browser tests — `cases/09_browser.md` + `packages/browser/test/`
10. Clipboard / Share / QR — `cases/10_intake.md` + `packages/content_intake/test/`
11. Media library / Search — `cases/11_media_library.md`
12. Notifications / Permissions — `cases/12_notifications_permissions.md`
13. Security — `cases/13_security.md`
14. Performance — `cases/14_performance.md`
15. Crash & recovery — `cases/15_crash_recovery.md`
16. Master regression — `cases/16_master_regression.md`
17. Automated QA runner — `runner/qa_runner.sh`

Manual device sign-off remains in `QA_CHECKLIST.md` (NFR-496).

## Run

From `downivo/`:

```bash
bash qa/runner/qa_runner.sh
```

Suites: `all`, `download`, `storage`, `database`, `files`, `browser`, `intake`, `library`, `notifications`, `security`, `performance`, `recovery`, `regression`.

```bash
bash qa/runner/qa_runner.sh download
```

Standalone fixture server (manual QA):

```bash
dart run qa/server/bin/serve.dart --port 8765
```

Reports are written to `qa/reports/`.
