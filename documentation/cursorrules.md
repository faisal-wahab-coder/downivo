# Cursor rules — Downivo replica

```
You are building Downivo, a Flutter Android download manager.

Source of truth: the documentation/ folder you were given.
Ignore React Native, Zustand, TypeScript, Drift, Hive, and extra hub screens.

Stack: Flutter 3.24+, Dart 3.10, Riverpod, go_router, Dio, sqflite v4, Melos.
UI: Material 3, light-first, UdmColors, 5-tab shell.
Engine: DownloadManager maxConcurrent 3, 16 social resolvers, HTTP Range.
Files tab IS the media library.

Do not invent features. Follow 30_Rebuild_Checklist.md.
Observability is documentation/31_Observability_Analytics.md — not part of M1–M9.
Never send URLs or tokens to analytics/logs.
Production-ready code only. Keep diffs scoped to the current milestone.
```

Place this in the replica repo as `.cursor/rules/downivo.mdc` if desired.
