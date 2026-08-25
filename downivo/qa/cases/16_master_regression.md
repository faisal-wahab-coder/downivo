# Master Regression

Run via `bash qa/runner/qa_runner.sh regression` (same as `all`).

## Automated gate

Every suite below must pass:

1. Download lifecycle + existing engine unit tests
2. Storage
3. Database
4. File manager + media library
5. Browser
6. Clipboard / Share / QR
7. Notifications / Permissions
8. Security
9. Performance primitives
10. Crash & recovery
11. Mobile bootstrap / onboarding smoke (`apps/mobile`)
12. app_core widget smokes (history, intake sheet)

## Manual gate (release)

Complete `QA_CHECKLIST.md` on a physical Android device (API 29+) before Play upload.

## Known exclusions

- Live social discovery (`SOCIAL_LIVE_TEST=1`) — opt-in, not CI
- `BackgroundDownloadCoordinator` foreground service
- In-app WebView navigation
- Camera QR capture (resolver is covered; camera hardware is not)
