# Non-Functional Requirements

Project: Downivo  
Version: 1.0.0 as-built

---

# 1. Performance

| ID | Requirement | As-built mechanism |
|----|-------------|-------------------|
| NFR-P1 | Startup recorded and shown in Settings performance panel | `performance` package `recordStartup` |
| NFR-P2 | Download progress UI must not rebuild every byte | `ThrottleGate` 250ms |
| NFR-P3 | File lists virtualized; completed/failed collapsible | Downloads + Files screens |
| NFR-P4 | Library scan cached | 30s TTL cache |
| NFR-P5 | Image thumbnails downsized | file thumbnail helpers |
| NFR-P6 | Parallel startup init | prefs + storage paths concurrent in `bootstrap` |

---

# 2. Reliability

- Persist every task to sqflite.
- Restore queue on launch.
- HTTP Range resume when the server supports it.
- Retry failed transfers up to 3 times.
- Network loss → auto-pause; reconnect → resume.

---

# 3. Security and privacy

- No user accounts. No cloud sync. All download metadata on-device.
- V1: no analytics SDK. Next milestone may add Crashlytics + PostHog behind `AnalyticsService` with URL/token sanitization ([31](31_Observability_Analytics.md)).
- HTTPS for downloads; Dio default.
- Do not download private WhatsApp media CDNs.
- Camera permission only for QR.
- Clipboard monitoring is opt-in (settings + onboarding).
- Android release: R8 minify, shrink resources, ProGuard rules.

---

# 4. Accessibility

- `UdmScaffold` semantic headers / screen labels.
- History row semantics `{fileName}, {status}`.
- Minimum touch 44px on filled/outlined buttons (theme).
- NavigationBar labels always shown.

---

# 5. Compatibility

- Android 10+ (API 29).
- Flutter Web: no foreground service, no camera QR, share stub, web file store / sqflite ffi web.

---

# 6. Maintainability

- Melos packages with barrel files.
- `flutter analyze` in CI (`scripts/ci.sh`).
- Feature UI isolated under `app_core/lib/src/features/<feature>/`.

---

# 7. Size and resources

- Single dataSync foreground service (not a fleet of workers).
- App size target < 60 MB.
- One Dio client per DownloadManager.

---

# 8. Localization

V1 ships **English-only** UI strings. Do not add l10n unless asked.
