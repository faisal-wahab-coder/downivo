# Universal Downloader — Rebuild Documentation

**Purpose:** This folder is a complete, as-built specification so another Cursor (or engineer) can recreate an **exact copy** of Universal Downloader.

**Status:** Production (`1.1.0+3`)  
**Captured:** 19 August 2026  
**Source of truth:** this folder describes the **running Flutter app**, not the original React Native drafts in `/docs`.

---

## How to use this folder

1. Give another Cursor **this entire `documentation/` folder** (and optionally the original `/docs` for historical context).
2. Open [`00_CURSOR_REBUILD_PROMPT.md`](00_CURSOR_REBUILD_PROMPT.md) first. Paste it as the system/user prompt.
3. Follow [`30_Rebuild_Checklist.md`](30_Rebuild_Checklist.md) in milestone order (M1 → M9).
4. Match packages, routes, schema, and APIs in [`26_Package_Catalog.md`](26_Package_Catalog.md) and [`27_Source_Map.md`](27_Source_Map.md).

Where any older document conflicts with these files, **these files win**.

---

## What this product is

Universal Downloader is a **Flutter** Android (plus Flutter Web) download manager:

- Paste or share a URL → resolve social/media sources → queue downloads
- Pause / resume (HTTP Range), background foreground service, notifications
- File manager with category folders, search, favorites, import
- In-app browser with download detection
- Clipboard monitoring, Android share target, QR scanner
- Material Design 3, Riverpod, GoRouter, sqflite

It is **not** React Native. Original `/docs` still mention RN/Zustand/TypeScript; ignore those.

---

## Document map (same numbering as `/docs`)

| File | Role |
|------|------|
| [00_CURSOR_REBUILD_PROMPT.md](00_CURSOR_REBUILD_PROMPT.md) | Master prompt for another Cursor |
| [00_As_Built_Delta.md](00_As_Built_Delta.md) | What changed vs original docs |
| [01_Project_Overview.md](01_Project_Overview.md) | Vision, goals, stack |
| [02_Product_Requirements_Document.md](02_Product_Requirements_Document.md) | PRD (V1 shipped scope) |
| [03_Functional_Requirements.md](03_Functional_Requirements.md) | FRs with implementation status |
| [04_Non_Functional_Requirements.md](04_Non_Functional_Requirements.md) | NFRs |
| [05_User_Flows.md](05_User_Flows.md) | Actual user flows |
| [06_Product_Architecture.md](06_Product_Architecture.md) | Product architecture |
| [07_Engineering_Standards.md](07_Engineering_Standards.md) | Dart/Flutter standards |
| [08_UI_Design_System.md](08_UI_Design_System.md) | Tokens + MD3 theme |
| [09_Navigation_and_Information_Architecture.md](09_Navigation_and_Information_Architecture.md) | Routes + IA |
| [10_UX_Specifications/](10_UX_Specifications/) | Per-screen UX (as-built) |
| [11_Technical_Architecture/](11_Technical_Architecture/) | System, packages, engine, CI |
| [12_System_Design/](12_System_Design/) | Module designs (implemented vs do-not-build) |
| [13_Data_Architecture/](13_Data_Architecture/) | SQLite schema as shipped |
| [14_Storage_Management.md](14_Storage_Management.md) | Folders + FileStore |
| [15_Download_Engine.md](15_Download_Engine.md) | Queue, Range, resolvers |
| [16_Background_Downloads.md](16_Background_Downloads.md) | Foreground service |
| [17_File_Manager.md](17_File_Manager.md) | Library UI |
| [18_Browser.md](18_Browser.md) | WebView browser |
| [19_Clipboard.md](19_Clipboard.md) | Clipboard intake |
| [20_Share_Extension.md](20_Share_Extension.md) | Android share target |
| [21_QR_Scanner.md](21_QR_Scanner.md) | Camera QR |
| [22_Database.md](22_Database.md) | sqflite v4 |
| [23_Security.md](23_Security.md) | Privacy + Android |
| [24_Testing.md](24_Testing.md) | Test strategy |
| [25_Roadmap.md](25_Roadmap.md) | M1–M9 complete; future |
| [26_Package_Catalog.md](26_Package_Catalog.md) | Every package, deps, APIs |
| [27_Source_Map.md](27_Source_Map.md) | Exact file tree to recreate |
| [28_Dependencies.md](28_Dependencies.md) | pubspec versions |
| [29_Platform_Android.md](29_Platform_Android.md) | Manifest, permissions, signing |
| [30_Rebuild_Checklist.md](30_Rebuild_Checklist.md) | Step-by-step recreation |
| [UI_CURRENT_SCREEN_MAP.md](UI_CURRENT_SCREEN_MAP.md) | Screen inventory |
| [UI_CURRENT_FEATURE_MAP.md](UI_CURRENT_FEATURE_MAP.md) | Feature inventory |
| [AGENTS.md](AGENTS.md) | AI engineering rules |
| [cursorrules.md](cursorrules.md) | Cursor rules for rebuild |
| [adr/](adr/) | Architecture decision records |

---

## Hard rules for a replica

1. **Flutter 3.24+ / Dart 3.10**, Melos monorepo under `universal_downloader/`.
2. **sqflite** (schema version 4) — do **not** start with Drift even though ADR-002 planned it.
3. **Riverpod + GoRouter + StatefulShellRoute** (5 tabs).
4. Recreate only **implemented** packages listed in `melos.yaml`. Empty stub folders (`activity`, `collections`, …) are optional and unused.
5. Do **not** build Collections, Activity Center, Notification Center, cloud sync, AI, or encryption vault as product features.
6. Android applicationId / label: `Universal Downloader`. Version `1.1.0+3`.
7. Max **3 concurrent** downloads. HTTP Range pause/resume. Dio HTTP client.

---

## Repository layout to recreate

```
<repo>/
├── documentation/          # this folder
├── docs/                   # original drafts (historical; do not follow blindly)
└── universal_downloader/   # the app
    ├── apps/mobile/        # Android Flutter app
    ├── apps/web/           # Flutter Web app
    ├── packages/           # feature + infra packages
    ├── melos.yaml
    ├── scripts/ci.sh
    └── qa/
```
