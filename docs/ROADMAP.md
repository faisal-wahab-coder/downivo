# Roadmap

Status is taken from the codebase, [`documentation/25_Roadmap.md`](../documentation/25_Roadmap.md), `downivo/README.md` milestones, and `downivo/CHANGELOG.md`. Items marked **proposed** are not commitments.

## Completed

- M1 Foundation — shell, MD3, onboarding, SQLite, storage, permissions, settings
- M2 Download engine — queue, Range pause/resume, FG service, notifications, recovery
- M3 Storage / Files library
- M4 In-app browser
- M5 File manager depth (detail, import, search filters)
- M6 Clipboard, Android share target, QR scanner
- M7 Performance caches, indexes, virtualization
- M8 History FR-049/050, accessibility on `UdmScaffold`, RC
- M9 `1.0.0` release engineering (R8, signing template, GitHub Actions)
- `1.1.0` — Save to Gallery, in-app gallery, sixteen social/media resolvers
- `1.2.0` — What's new dialog (`1.2.0+4` in pubspec)
- `1.3.0` — SmartDownload controls and Instagram carousel recovery (`1.3.0+5` in pubspec)
- `1.4.0` — Save as Video/Audio and extract audio from Files (`1.4.0+6` in pubspec)
- `1.5.0` — Files folders, Open with, and Threads media recovery (`1.5.0+7` in pubspec)

## In Progress

- Open-source GitHub preparation (this `docs/` set, license, templates)
- Observability package **exists** (`packages/analytics`) but live Crashlytics/PostHog stay off until each builder supplies keys

## Next

Proposed maintainer work after the repo is public:

- Rotate the Firebase Android API key that was in git history
- Enable GitHub private vulnerability reporting
- Pin a Flutter version in CI once a known-good stable is chosen
- Add screenshots to the README
- Decide whether empty stub packages stay or are removed

## Planned

From product docs, **not** scheduled in code:

- Production telemetry rollout (privacy policy + consent) — [documentation/31_Observability_Analytics.md](../documentation/31_Observability_Analytics.md)
- Storage folder picker
- Stronger Play-signed release automation via repository secrets (optional)

## Community Ideas

**Proposed** — discuss in issues first:

- More resolver coverage or site-specific error copy
- Accessibility pass on remaining screens
- Additional unit tests for `design_system` / `shared_types`
- Web download UX (save-to-disk, proxy docs)
- iOS — large platform project; not V1

## Long Term

**Proposed / do not treat as promised:**

- iOS
- Desktop companion
- Cloud sync
- AI organization, OCR search
- Collections, Activity Center, Notification Center
- Drift migration (ADR-002 was overridden; database is sqflite)

## Good First Issues

Tasks that match the actual project:

- Improve empty-state copy on existing `EmptyState` screens
- Add unit tests around formatters in `shared_utils`
- Improve user-facing error messages for resolver failures
- Add download speed / ETA formatting tests
- Fix `downivo/README.md` links and keep them aligned with this roadmap
- Document a first-run screenshot set (take real captures; do not invent UI)
- Accessibility: extra semantics on Downloads/Files rows
- CI: report `flutter analyze` on PRs from forks (already configured; verify on GitHub)

See [CONTRIBUTION_AREAS.md](CONTRIBUTION_AREAS.md).
