# Current Screen Map

Source of truth for rebuild. Shell tabs: **Home · Downloads · Browser · Files · Settings**.  
Router: `AppRouter` (`GoRouter` + `StatefulShellRoute.indexedStack`).  
Routes: `packages/shared_types/lib/src/app_routes.dart`.

Placeholder widgets in `packages/navigation/lib/src/screens/tab_screens.dart` are **not** used.

---

## Route table

| Screen | Route | In shell | Presentation |
|---|---|---|---|
| Onboarding | `/onboarding` | No | Full-screen `GoRoute` |
| Home | `/home` | Yes (0) | Shell |
| Downloads | `/downloads` | Yes (1) | Shell |
| Download history | `/downloads/history` | Nested | Stack |
| Browser | `/browser` | Yes (2) | Shell |
| Files | `/files` | Yes (3) | Shell |
| Settings | `/settings` | Yes (4) | Shell |
| Permissions | `/permissions` declared | **No GoRoute** | Dead constant |
| QR Scanner | none | No | `Navigator.push` |
| Clipboard history | none | No | `Navigator.push` |
| File details | none | No | `Navigator.push` |
| Image gallery | none | No | `Navigator.push` |
| Search | none | No | `Navigator.push` |
| In-app viewer | none | No | `Navigator.push` |
| Download wizard | none | No | `AlertDialog` |
| Media selection | none | No | Modal bottom sheet |
| Intake | none | No | Modal bottom sheet |
| File / browser sheets | none | No | Modal bottom sheets |

**Not present:** Media Library tab, Storage Center, Smart Search tab, Activity Center, Collections, Notification Center, Download Details route.

---

## Screens to build

### 1. Onboarding — `/onboarding`

5-step `OnboardingFlow`. Entry: cold start when `showOnboarding`. Exit: `/home`. Actions: next, back, request permission, open OS settings, finish.

### 2. App shell

`MainShell` + `NavigationBar`. `navigationShell.goBranch`. Mobile bottom bar only.

### 3. Home — `/home`

Paste URL hero, storage dashboard, intake shortcuts (QR, clipboard, browser, search, files), active queue, recent completed (max 5). Components: `HomeScreen`, `UrlInputField`, `MediaPreviewCard`, `StorageDashboard`, `DownloadTaskCard`, `UdmScaffold`.

### 4. Downloads — `/downloads`

Queue grouped: downloading / queued (reorderable) / paused / completed / failed. Filters All/Active/Completed/Failed. FAB add URL. Pause all / resume all / history / search.

### 5. Download history — `/downloads/history`

Completed/failed/cancelled. Clear confirm. Hidden clear when empty.

### 6. Download wizard (dialog)

URL, optional name, priority Low/Normal/High/Urgent.

### 7. Media selection sheet

Thumbnails, mime, select all/none, Download N.

### 8. Files — `/files`

Folder browser, breadcrumbs, search, sort, filters, favorites, import banner, list default + grid toggle. File rows include Delete and more actions. Tap image → in-app gallery.

### 9. Image gallery (push)

Full-screen image, swipe siblings in the folder or Files search, pinch-zoom. App-bar 3-dot opens file details. Bottom **More actions** button (icon + label) opens `FileActionsSheet`. List/grid **More actions** stay on the tile.

### 10. File details (push)

Name, Category, Size, Modified, Type, Location. Metadata only; actions live on the viewer overlay and the Files tile. Images enter here from the gallery 3-dot (or non-image tap).

### 11. Browser — `/browser`

WebView + toolbar + start page. Tabs, history, bookmarks, page downloads.

### 12. Settings — `/settings`

Theme, preferred quality/format, clipboard toggle, history link, storage dashboard + path (read-only), performance, clear caches, about v1.0.0.

### 13. QR Scanner (push)

`mobile_scanner`. Home entry.

### 14. Clipboard history (push)

Past detections. Clear. Tap to download.

### 15. Intake sheet

Download / Open in browser / Import / Show text / Dismiss. Copy **Download detected**.

---

## Navigation graph

```
Onboarding → Home
                ├─ QR Scanner (push)
                ├─ Clipboard history (push)
                ├─ Files (tab)
                ├─ Downloads (tab)
                └─ Download history (stack)
Downloads → Wizard → Media sheet
          → History
Files → Image gallery → File details → Actions / Filters / Import
     → File details (non-image)
Browser → Tabs / History / Bookmarks / Page downloads
Settings → History
```
