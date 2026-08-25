# AGENTS.md — Downivo (rebuild)

## Purpose

Rules for AI assistants recreating or extending this app.

## Must

- Read `documentation/00_CURSOR_REBUILD_PROMPT.md` first
- Follow Flutter/Dart, not TypeScript
- Follow Clean Architecture and feature packages
- Match as-built routes, schema, and settings keys
- Write tests for engine and history-clear
- Keep `design_system` free of business logic

## Must never

- Add Collections, Activity Center, Notification Center, cloud sync, or AI
- Replace sqflite with Drift “because ADR-002 said so”
- Add a sixth tab
- Put live screens in `navigation/tab_screens.dart`
- Commit secrets, `key.properties`, or PostHog API keys
- Send full URLs, tokens, cookies, or file contents to Crashlytics / PostHog / logs

## Roles (mapped from original)

| Original role | V1 equivalent |
|---------------|----------------|
| React Native Engineer | Flutter engineer |
| Solution Architect | Package boundaries + ADRs |
| Product Engineer | FR traceability |
| QA | `scripts/ci.sh` + qa checklist |

## Stack reminder

Riverpod, go_router, Dio, sqflite, Melos, MD3.
