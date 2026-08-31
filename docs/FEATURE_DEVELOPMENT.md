# Feature development

How contributors should add behavior without breaking the as-built architecture.

```text
Idea
 ↓
GitHub Discussion / Issue
 ↓
Technical Design
 ↓
Implementation
 ↓
Tests
 ↓
Documentation
 ↓
Pull Request
 ↓
Code Review
 ↓
Merge
```

## 1. Idea

Match the problem to [ROADMAP.md](ROADMAP.md) and [CONTRIBUTION_AREAS.md](CONTRIBUTION_AREAS.md). If the idea is Collections, Activity Center, cloud sync, AI, OCR, Drift, or a sixth tab, it is **out of scope** unless maintainers explicitly accept it.

## 2. GitHub Discussion / Issue

Open an issue (feature template) **before** large work. Explain the user problem. Search for duplicates.

## 3. Technical Design

For non-trivial changes, comment on the issue with:

- Package(s) that will change
- Data (new sqflite columns need a schema bump — current is v4)
- UI surfaces
- Test plan
- Privacy (no new telemetry fields that include URLs)

## 4. Implementation — where code goes

| Kind of change | Location |
| -------------- | -------- |
| Screen / dialog / sheet | `downivo/packages/app_core/lib/src/features/<feature>/` |
| Route | `app_core/lib/src/navigation/app_router.dart` and `shared_types` routes |
| Theme / generic widget | `packages/design_system` only if it has **no** business logic |
| Shell / onboarding chrome | `packages/navigation` |
| Queue, HTTP, resolvers | `packages/download_engine` |
| New site resolver | `download_engine/lib/src/content_providers/` + `ContentProviderRegistry` / `PlatformSocialResolver` |
| Clipboard / share / QR models | `packages/content_intake`; UI still in `app_core` |
| Browser tabs / detection | `packages/browser` |
| Files scan / actions | `packages/media_library` |
| Paths / FileStore | `packages/storage` |
| SQLite | `packages/database` (migrations must be tested) |
| FG service | `packages/job_manager` |
| Notifications | `packages/notifications` |
| Search | `packages/search` (`udm_search`) |
| Local AV playback | `packages/universal_viewer` |
| Crash / events | `packages/analytics` via `AnalyticsService` |
| Shared enums | `packages/shared_types` |
| Format helpers | `packages/shared_utils` |
| Android app wiring | `apps/mobile` (keep thin) |
| Web-only | `apps/web` (proxy, wasm, stubs) |

Do **not** implement features in empty stub packages (`activity`, `collections`, …) until they are added to `melos.yaml` with real code.

Widgets must not open sqflite or write files. Call `DownloadManager`, `media_library`, or providers.

## 5. Tests

- Engine / resolver: `packages/download_engine/test/`
- Widget/history/onboarding: `app_core/test/`, `apps/mobile/test/`
- Privacy: `packages/analytics/test/`
- Run `bash scripts/ci.sh` from `downivo/`

Fail closed: private CDNs, DRM, and auth walls must not be bypassed. Add tests like the existing WhatsApp private CDN cases.

## 6. Documentation

Update:

- User-facing: `README.md` features list only if the feature **ships**
- Contributor: this folder, `downivo/CHANGELOG.md` under Unreleased
- As-built specs in `documentation/` only when maintainers want the rebuild docs to stay in sync

## 7. Pull Request

Use [.github/PULL_REQUEST_TEMPLATE.md](../.github/PULL_REQUEST_TEMPLATE.md). Keep the diff scoped. No secrets, no drive-by dependency upgrades.

## 8. Code Review

Reviewers check architecture boundaries, tests, and privacy. See [PROJECT_GOVERNANCE.md](PROJECT_GOVERNANCE.md).

## 9. Merge

Maintainers merge contributor PRs into `dev`. Production updates are `dev` → `main`. Do not push to `dev` or `main`.
