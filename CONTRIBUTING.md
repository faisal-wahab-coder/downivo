# Contributing to UniversalDownloader

## Welcome

Thank you for considering a contribution. Bug fixes, tests, documentation, accessibility, and well-scoped features help the project. This guide is written for someone who has not seen the repository before.

The shipping app is named **Downivo**. The GitHub project name is **UniversalDownloader**. Use Downivo in UI copy and package names; use UniversalDownloader when talking about the public repository.

## Before You Start

- Read [README.md](README.md)
- Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and, for deeper specs, [`documentation/`](documentation/README.md)
- Search existing issues in this repository for duplicates
- Check [docs/ROADMAP.md](docs/ROADMAP.md) and [docs/CONTRIBUTION_AREAS.md](docs/CONTRIBUTION_AREAS.md)
- Avoid large features that are not already discussed

Do not implement Collections, Activity Center, Notification Center, cloud sync, AI, or a sixth tab unless maintainers explicitly agree. Those ideas exist in older specs and are **not** in the as-built product.

## Development Setup

Requirements: Flutter 3.44+, Dart SDK ^3.10.0, Android SDK (API 29+), Java 17.

```bash
git clone https://github.com/faisal-wahab-coder/downivo.git
cd downivo/apps/mobile
flutter pub get
flutter run
```

Validate the workspace from `downivo/`:

```bash
bash scripts/ci.sh
```

Optional Melos (from `downivo/` after `dart pub global activate melos`):

```bash
melos bootstrap
melos run analyze
melos run test
melos run format
```

Environment variables and Firebase/PostHog are optional. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and [`.env.example`](.env.example).

Web development: [downivo/apps/web/README.md](downivo/apps/web/README.md).

## Branch Naming

```text
feature/<description>
fix/<description>
docs/<description>
refactor/<description>
performance/<description>
test/<description>
```

Examples: `feature/download-queue-priority`, `fix/duplicate-enqueue`, `docs/development-setup`.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat:
fix:
docs:
refactor:
perf:
test:
build:
ci:
chore:
```

Examples:

```text
feat: add download queue priority
fix: prevent duplicate downloads
perf: improve download list rendering
docs: update development setup
```

## Branch policy

- **`dev`** — integration branch. All contributor pull requests must target `dev`.
- **`main`** — production. No direct pushes. Maintainers merge `dev` → `main` for a release.
- Direct pushes to `dev` and `main` are blocked. Create your own branch (or work on a fork).

## Pull Request Process

1. Fork [faisal-wahab-coder/downivo](https://github.com/faisal-wahab-coder/downivo)
2. Branch from **`dev`** using the naming above
3. Implement the change in the correct package (see [docs/FEATURE_DEVELOPMENT.md](docs/FEATURE_DEVELOPMENT.md))
4. Run `bash scripts/ci.sh` from `downivo/`
5. Run analyze/tests for packages you touched if you skipped the full script
6. Update documentation when behavior or setup changes
7. Commit with a conventional message
8. Push to **your fork / your branch** (do not push to `dev` or `main`)
9. Open a pull request **against `dev`** using [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)
10. Wait for review; address feedback

Pull requests that target `main` (except a maintainer `dev` → `main` release PR) are closed automatically.

Keep pull requests focused. Prefer several small PRs over one mixed refactor + feature + format dump.

## Code Quality

- **Formatting** — `dart format` / `melos run format`. Match surrounding code.
- **Linting** — `flutter analyze` via `scripts/ci.sh`. Packages include `package:flutter_lints/flutter.yaml`.
- **Tests** — add or update tests for engine, resolvers, and user-visible behavior. Resolver tests live in `downivo/packages/download_engine/test/`.
- **Naming** — files `snake_case.dart`, classes `PascalCase`, Riverpod providers `fooProvider`.
- **Architecture** — presentation in `app_core` features; no business logic in `design_system`; widgets must not open sqflite or write files directly.
- **Dependencies** — do not add packages without discussion. Do not introduce Bloc, GetX, Drift, Hive, or GetIt. See [docs/DEPENDENCY_AUDIT.md](docs/DEPENDENCY_AUDIT.md).
- **Secrets** — never commit `google-services.json`, `key.properties`, keystores, `.env`, or API keys.

More standards: [`documentation/07_Engineering_Standards.md`](documentation/07_Engineering_Standards.md).

## Feature Contributions

Open an issue or discussion **before** implementing large features. Describe the problem, not only the implementation. Follow [docs/FEATURE_DEVELOPMENT.md](docs/FEATURE_DEVELOPMENT.md).

New social resolvers must fail closed on private/authenticated content. Do not add session-cookie bypasses.

## Bug Fixes

Include:

- Reproduction steps
- Expected vs actual behavior
- Platform (Android version or Web)
- App version (`1.2.0+4` or later)
- A test that fails without the fix when the bug is in Dart logic

## Code of Conduct

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
