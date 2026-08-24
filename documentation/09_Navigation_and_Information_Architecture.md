# Navigation and Information Architecture (as-built)

Sources: `packages/shared_types/lib/src/app_routes.dart`, `packages/app_core/lib/src/navigation/app_router.dart`, `packages/navigation`.

---

# 1. Shell

Five destinations, left-to-right:

1. Home  
2. Downloads  
3. Browser  
4. Files  
5. Settings  

Implementation: `StatefulShellRoute.indexedStack` + `MainShell` + `NavigationBar`.

Placeholder `tab_screens.dart` in navigation **must not** be used as live screens.

---

# 2. Route table

| Route constant | Path | In shell | Widget |
|----------------|------|----------|--------|
| `AppRoutes.onboarding` | `/onboarding` | No | `OnboardingFlow` |
| `AppRoutes.home` | `/home` | 0 | `HomeScreen` |
| `AppRoutes.downloads` | `/downloads` | 1 | `DownloadsScreen` |
| `AppRoutes.downloadHistory` | `/downloads/history` | Nested | `DownloadHistoryScreen` |
| `AppRoutes.browser` | `/browser` | 2 | `BrowserScreen` |
| `AppRoutes.files` | `/files` | 3 | `FilesScreen` |
| `AppRoutes.settings` | `/settings` | 4 | `SettingsScreen` |
| `AppRoutes.permissions` | `/permissions` | **No GoRoute** | Dead constant — keep for compatibility, do not wire |

Initial location: onboarding if `showOnboarding`, else home.

---

# 3. Unnamed Navigator routes (push)

| Screen | From |
|--------|------|
| `QrScannerScreen` | Home |
| `ClipboardHistoryScreen` | Home |
| `FileDetailScreen` | Gallery 3-dot or non-image tap |
| `ImageGalleryScreen` | Full-screen image + swipe siblings |
| `AppSearchScreen` | Home / Downloads |
| `UniversalViewerScreen` | Open local AV |

---

# 4. Overlays (not routes)

| Overlay | Purpose |
|---------|---------|
| `DownloadWizardDialog` | Add URL |
| `MediaSelectionSheet` | Multi-item pick |
| `FormatPickerSheet` | Quality/format |
| `showIntakeActionSheet` | Clipboard/share/QR confirm |
| `FileActionsSheet` | File ops |
| `FileFilterSheet` | Size/date |
| `_ImportSheet` | Categorize imports |
| Browser sheets | tabs, history, bookmarks, page downloads |

---

# 5. Graph

```
Onboarding → Home
              ├─ QR (push)
              ├─ Clipboard history (push)
              ├─ Search (push)
              ├─ Files (tab)
              ├─ Downloads (tab) → history (stack)
              │                    → wizard (dialog)
              │                    → media sheet
              ├─ Browser (tab) → sheets
              └─ Settings (tab) → history
Files → image gallery (images) → file detail (push) → actions sheet
     → file detail (non-image)
```

---

# 6. Deep links

V1: launcher + share intents only. No universal HTTP app links required for replica.

Share: `ACTION_SEND` text/plain and `*/*`, `ACTION_SEND_MULTIPLE` `*/*`. Activity `singleTask`.

---

# 7. Original docs screens that are NOT routes

Media Library, Media Details, Storage Center, Smart Search tab, Activity Center, Collections, Notification Center, Download Details, full-screen Download Wizard.

Files **is** the media library. Search is pushed. Wizard is a dialog.
