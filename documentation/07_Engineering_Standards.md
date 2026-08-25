# Engineering Standards

Project: Downivo  
Version: 1.0.0 as-built  
Status: Mandatory for rebuild

---

# Purpose

Every contributor and AI assistant must follow these standards so the replica stays maintainable and matches the original codebase.

---

# Principles

Simplicity, readability, maintainability, testability, performance, security, accessibility, reuse.

Production-ready only. No temporary architecture. No duplicated download logic in UI.

---

# Language and stack

- **Dart 3** with null safety. `sdk: ^3.10.0`.
- Flutter `>=3.24.0`. `useMaterial3: true`.
- No TypeScript. No React Native.

---

# SOLID and Clean Architecture

Four layers: Presentation → Application → Domain → Data. Dependencies flow down only.

- Widgets may call providers and package APIs.
- Widgets must not open sqflite or write files.
- `design_system` has **no** business logic.
- Feature screens live in `app_core/lib/src/features/<name>/`.
- Shared enums in `shared_types`.

---

# Feature-based packages

Organize by capability (`download_engine`, `browser`, `media_library`), not by technical layer-only folders at repo root.

Each package:

- `lib/<package>.dart` barrel export
- `lib/src/` implementation
- `test/` when logic exists
- `pubspec.yaml` `publish_to: none`

---

# State

- Riverpod: `Provider`, `NotifierProvider`, `StreamProvider` as used in `app_providers.dart` / feature providers.
- Overrides only in `bootstrap()` for graph roots (prefs, manager, router).
- Do not introduce Bloc/GetX/Zustand.

---

# Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Providers: `fooProvider`
- Private widgets: `_FooTile`
- Storage enums: uppercase string values (`QUEUED`, `NORMAL`)

---

# UI rules

- 8-point spacing (`UdmSpacing`).
- Cards radius 12, sheets 16.
- Empty states use `EmptyState`.
- Scaffolds use `UdmScaffold` (semantics).
- Snackbars floating (theme).
- Do not add a sixth tab.

---

# Async and errors

- Dio errors formatted via `download_error_formatter.dart`.
- User-facing failures → SnackBar or `EmptyState`, never uncaught in UI.
- Cancel via `CancelToken` per task.

---

# Testing

- `flutter test` per package.
- Engine resolver tests live under `download_engine/test`.
- Widget tests for history and onboarding copy.
- Integration: enqueue persistence; history clear keeps files.
- `scripts/ci.sh`: pub get → analyze → test for listed packages.

---

# Forbidden

- Business logic in widgets beyond view-state.
- New dependencies without matching `28_Dependencies.md`.
- Implementing out-of-scope screens from old 10.9–10.12 docs.
- `--no-verify` or skipping analyze to “finish”.
- Secrets in git (`key.properties` from template only).
