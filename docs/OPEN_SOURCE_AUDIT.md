# Open-source repository audit

**Project:** UniversalDownloader (product name **Downivo**)  
**Audited:** 31 August 2026  
**App version in tree:** `1.2.0+4` (`downivo/apps/mobile/pubspec.yaml`)  
**Git branch at audit:** `dev` (same commit as `main`)

This document records what the repository **actually contains**. It does not invent features.

---

## Current project status

Downivo is a **Flutter Melos monorepo** that ships an Android download manager plus a Flutter Web runner. Milestones M1–M9 and follow-on gallery / social resolvers / "what's new" are implemented in code and documented as complete.

| Item | Value |
| ---- | ----- |
| Display name | Downivo |
| Slogan | Download. Manage. Enjoy. |
| Android applicationId | `com.pm.downivo` |
| Workspace folder | `downivo/` |
| Language | Dart 3 (`sdk: ^3.10.0`) |
| UI framework | Flutter (strictest constraint `>=3.44.0` on mobile and `job_manager`) |
| Package manager | Pub (`flutter pub get` / Melos bootstrap) |
| Workspace tool | Melos 8 (`downivo/melos.yaml`) |
| State | Riverpod 2.6 |
| Navigation | go_router 16, five-tab `StatefulShellRoute` |
| HTTP | Dio 5.9 inside `download_engine` |
| Database | sqflite schema v4 |
| Min Android | API 29 (Android 10) |
| Java | 17 |
| Backend / accounts | None |
| License (before this work) | **Missing** |
| Root README (before this work) | **Missing** (only `downivo/README.md`) |
| CI | GitHub Actions: `flutter-ci.yml`, `release.yml` |
| Public GitHub | [github.com/faisal-wahab-coder/downivo](https://github.com/faisal-wahab-coder/downivo) (create this repo before the first push) |

---

## Architecture summary

As built (see [ARCHITECTURE.md](ARCHITECTURE.md) and [`documentation/06_Product_Architecture.md`](../documentation/06_Product_Architecture.md)):

```text
apps/mobile · apps/web          thin main() + platform plugins
        ↓
packages/app_core               bootstrap, Riverpod, GoRouter, all live screens
        ↓
download_engine                 queue, Dio, social resolvers, FileStore writes
job_manager                     Android foreground service + connectivity
content_intake · browser        clipboard, share, QR, WebView
media_library · storage         scan, favorites, category folders
database                        sqflite
notifications · permissions · performance · analytics
design_system                   MD3 only — no business logic
```

**Melos members:** `apps/mobile`, `apps/web`, and the packages listed in `downivo/melos.yaml` (including `analytics`, `search`, `universal_viewer`).

**Empty stub folders** (README only, **not** Melos members): `activity`, `collections`, `download_source_sdk`, `mcp_server`, `metadata_extractor`, `networking`, `platform_android`, `platform_interface`, `scanner`, `settings`, `testing`, `thumbnail_generator`.

---

## Build requirements

| Command | Where | Purpose |
| ------- | ----- | ------- |
| `flutter pub get` | each package or `apps/mobile` | Install deps |
| `flutter run` | `apps/mobile` | Debug on device/emulator |
| `flutter run -d chrome` | `apps/web` | Web runner |
| `dart run tool/cors_proxy.dart` | `apps/web` | Loopback proxy for Web social URLs |
| `flutter analyze` | per package | Lint |
| `flutter test` | packages with `test/` | Unit/widget tests |
| `bash scripts/ci.sh` | `downivo/` | pub get + analyze + test |
| `melos run format` | `downivo/` | `dart format` |
| `flutter build apk --release` | `apps/mobile` | Sideload APK |
| `flutter build appbundle --release` | `apps/mobile` | Play AAB |

Signing: `key.properties.example` exists. Live `key.properties` / keystores were **not** present in the working tree.

---

## Dependency overview

All workspace packages use `publish_to: none` and path dependencies internally. External packages are from **pub.dev** (Riverpod, Dio, sqflite, Firebase, PostHog, etc.). No private npm/pub registries were found.

Versions are caret-pinned (`^x.y.z`), not `*`. `apps/mobile` has two **exact** `dependency_overrides` for Android plugin implementations.

See [DEPENDENCY_AUDIT.md](DEPENDENCY_AUDIT.md).

---

## Security concerns

1. **`google-services.json` was tracked in Git** and contains a live Firebase Android API key and project identifiers. It must not be in a public tree. The working copy can remain for local Crashlytics.
2. **Git origin** pointed at a private Bitbucket project. Changelog/release docs linked that host.
3. **Commit metadata** uses a company email address (see [GIT_HISTORY_SECURITY.md](GIT_HISTORY_SECURITY.md)).
4. **Twitch GraphQL `Client-ID`** in source is documented as the public twitch.tv web client id, not an app secret.
5. SoundCloud `client_id` values in tests are fixtures / page-extraction tests, not uploaded user secrets.
6. PostHog keys are **compile-time** `String.fromEnvironment` — no hardcoded production key found.
7. `.cursor/mcp.json` is gitignored; `.cursor/mcp.json.example` uses placeholders (including a local filesystem path template).
8. `.agents/` and `.cursor/plugins/` are Cursor/Stitch **design tooling**, not the Flutter app. They include example passwords in skill docs (`password: '123456'` in a commented fetch example) — not app credentials.

No `.env`, `.pem`, `.jks`, or `key.properties` (non-example) files were found in the working tree.

---

## Secrets found

| Location | Kind | Action |
| -------- | ---- | ------ |
| `downivo/apps/mobile/android/app/google-services.json` | Firebase Android API key + project ids | Untrack, gitignore, keep local file, **rotate key before public push** |
| `downivo/CHANGELOG.md` / `RELEASE.md` (at audit) | Private Bitbucket URLs | Remove from docs |
| Git commit author | Company email | Do not rewrite unless the owner chooses to; document |
| Git remote URL | Bitbucket username in remote | Local git config only; not a tracked file |

Secret **values are not copied** into this document.

---

## Documentation gaps (at audit)

- No root README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- No GitHub issue/PR templates
- Existing `documentation/` is excellent **rebuild** documentation, not contributor onboarding
- `downivo/README.md` still mentioned `../docs/` which does not exist (specs are in `documentation/`)
- Product changelog compared versions on Bitbucket

---

## Testing gaps

Strengths: ~200 Dart test files, heavy coverage of `download_engine` resolvers, plus `app_core`, `database`, `browser`, `analytics` sanitizer tests. Manual QA lives under `downivo/qa/`.

Gaps:

- `scripts/ci.sh` (at audit) omitted Melos members `analytics`, `search`, `universal_viewer`
- `design_system` and `shared_types` have no `test/` directory
- No automated Android instrumented / Firebase Test Lab job
- Web is not built in CI
- `melos run format` is not a CI gate

---

## CI/CD gaps

- Workflows exist and call `scripts/ci.sh`
- Flutter version is **not pinned** (channel `stable` only)
- AAB job on `main` uses **debug signing** when `key.properties` is absent (correct for public CI; must not be confused with Play uploads)
- `release.yml` uploads artifacts but does not create a GitHub Release
- Current git default branch for work is `dev`; CI originally listened only to `main` and `develop`

---

## Recommended improvements

1. MIT LICENSE (no copyleft conflict found among typical Flutter deps)
2. Untrack Firebase config; rotate the leaked API key
3. Root README + contributor/security docs
4. Align `ci.sh` with Melos members that have tests
5. Replace private host URLs in changelog/release notes
6. Owner: enable GitHub private vulnerability reporting and Discussions if desired
7. Optional later: pin Flutter version in Actions; add `dart format --set-exit-if-changed` once the tree is known-clean

---

## Open-source readiness score (at inspection, before preparation)

| Area | Score | Notes |
| ---- | ----- | ----- |
| Security | 5/10 | Live Firebase file in git; otherwise no accounts/backend |
| Documentation | 6/10 | Deep internal specs; missing OSS entry points |
| Architecture | 8/10 | Clear packages; some unused stub folders |
| Testing | 8/10 | Strong engine tests; CI package list incomplete |
| CI/CD | 6/10 | Present; unsigned AAB; no Flutter pin |
| Contribution | 2/10 | No templates, license, or contributor guide |
| Maintainability | 7/10 | Clean Architecture + Melos; mixed Flutter min versions |
| **Overall** | **6/10** | Ship-quality app; not yet a public GitHub project |

Target after the preparation pass: **8+/10**, with remaining P0 items owned by the human (key rotation, GitHub repo creation, history decision).
