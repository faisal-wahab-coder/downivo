# As-Built Delta vs Original `/docs`

The original `/docs` folder was written **before** implementation and assumed React Native. This table is the mapping you must apply when recreating the app.

| Original docs said | As-built (recreate this) |
|--------------------|--------------------------|
| React Native + TypeScript | Flutter 3.24+ / Dart 3.10 |
| Zustand / Redux Toolkit | flutter_riverpod |
| React Navigation | go_router + StatefulShellRoute |
| WatermelonDB / Room / Drift (ADR-002) | **sqflite** hand-written schema v4 |
| Hive for settings | shared_preferences |
| Android-only (ADR-006) | Android primary **plus** Flutter Web app |
| Separate Media Library tab | Files tab **is** the library (`media_library` backend) |
| Smart Search tab | Pushed `AppSearchScreen`, not a tab |
| Activity Center, Collections, Notification Center | **Not built** — do not add |
| Drift codegen M2 | Never landed — stay on sqflite |
| Event bus package | Riverpod streams (`tasksStream`) |
| networking package | Dio lives inside `download_engine` |
| platform_android / scanner packages | Empty stubs; **not in melos.yaml** |
| analytics package | **Melos member.** Crashlytics + PostHog behind `AnalyticsService` ([31](31_Observability_Analytics.md)) |

## ADR vs code

| ADR | Decision | Code reality |
|-----|----------|--------------|
| 001 Flutter | Accepted | Follow |
| 002 Drift | Accepted | **Override:** sqflite. Recreate sqflite. |
| 003 Melos monorepo | Accepted | Follow; `melos.yaml` lists implemented packages only |
| 004 Clean Architecture | Accepted | Follow; UI in `app_core` features talking to packages |
| 005 Riverpod | Accepted | Follow |
| 006 Android-only V1 | Accepted | Android is the product; Web exists as a second runner |

## Empty packages on disk (optional)

These folders may exist with `0` Dart files and are **not** Melos workspace members:

`activity`, `collections`, `download_source_sdk`, `mcp_server`, `metadata_extractor`, `networking`, `platform_android`, `platform_interface`, `scanner`, `settings`, `testing`, `thumbnail_generator`

A working replica does **not** need those stubs. `analytics` **is** a Melos member ([31](31_Observability_Analytics.md)).

## Product identity

Formerly **Universal Downloader**. Display name is **Downivo**. Android `applicationId` / namespace is `com.pm.downivo`. Melos root folder is `downivo/`. Storage folder and Gallery album are `Downivo`. SQLite file is `downivo.db`.
