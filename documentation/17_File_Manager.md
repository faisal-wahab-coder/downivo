# 17. File Manager

**UI:** `files_screen.dart`, `image_gallery_screen.dart`, `file_detail_screen.dart`, sheets, thumbnails  
**Backend:** `media_library`

## Features

- Breadcrumb navigation root → category → subfolders
- Recursive scan + global search
- Sort + size/date filters
- Favorites (star + Favorites folder)
- File detail (from the image viewer 3-dot, or tap of a non-image) — metadata only
- In-app image gallery (tap image → full-screen; swipe siblings; on-image More actions)
- Open / Open with (Android app chooser) / Show in Files / share / save to gallery (photos & videos) / rename / move / delete
- User folders inside a category (New folder, Move to folder). Long-press selects files; Move to folder sends the selection into a category folder or another category.
- Delete on list/grid rows and in `FileActionsSheet` (confirm)
- Import banner (FR-035)
- List default + grid toggle (grid tiles fill with the image)
- In-app AV via universal_viewer
- Update download `file_path` on rename/move
- Clear download `file_path` on delete (history stays; Downloads shows Removed from Files)

## Providers

`libraryQueryProvider`, `libraryLocationProvider`, `libraryBrowseProvider`, `pendingImportsProvider`.
