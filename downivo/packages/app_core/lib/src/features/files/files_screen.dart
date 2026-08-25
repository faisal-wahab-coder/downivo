import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_utils/shared_utils.dart';
import 'package:storage/storage.dart';

import 'package:universal_viewer/universal_viewer.dart';

import '../../providers/library_providers.dart';
import 'file_actions_sheet.dart';
import 'file_detail_screen.dart';
import 'file_filter_sheet.dart';
import 'file_thumbnail.dart';
import 'image_gallery_screen.dart';
import 'open_managed_media.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  final _searchController = TextEditingController();
  var _grid = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    invalidateLibrary(ref);
  }

  bool get _isSearchMode {
    final query = ref.watch(libraryQueryProvider);
    return query.search.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(libraryQueryProvider);
    final location = ref.watch(libraryLocationProvider);
    final importsAsync = ref.watch(pendingImportsProvider);

    return UdmScaffold(
      title: _titleFor(location),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: query.hasActiveFilters,
            label: const Text(''),
            child: const Icon(Icons.filter_list),
          ),
          tooltip: 'Filters',
          onPressed: () => showFileFilterSheet(context, ref),
        ),
        PopupMenuButton<LibrarySort>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          initialValue: query.sort,
          onSelected: (sort) {
            ref.read(libraryQueryProvider.notifier).state = query.copyWith(
              sort: sort,
            );
          },
          itemBuilder: (context) => LibrarySort.values
              .map(
                (sort) => PopupMenuItem(value: sort, child: Text(sort.label)),
              )
              .toList(),
        ),
        IconButton(
          icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
          tooltip: _grid ? 'List view' : 'Grid view',
          onPressed: () => setState(() => _grid = !_grid),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _refresh,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width >= UdmBreakpoints.desktop
                ? UdmSpacing.xxl
                : UdmSpacing.lg,
          ),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search all files…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(libraryQueryProvider.notifier).state = query
                              .copyWith(search: '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(libraryQueryProvider.notifier).state = query.copyWith(
                  search: value,
                );
              },
            ),
            const SizedBox(height: UdmSpacing.md),
            importsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (imports) => imports.isEmpty
                  ? const SizedBox.shrink()
                  : _ImportBanner(
                      imports: imports,
                      onReview: () => _showImportSheet(context, imports),
                    ),
            ),
            if (!_isSearchMode) ...[
              _BreadcrumbBar(
                location: location,
                onNavigate: (target) {
                  ref.read(libraryLocationProvider.notifier).state = target;
                },
              ),
              const SizedBox(height: UdmSpacing.md),
            ],
            if (_isSearchMode)
              _SearchResults(onOpenFile: _openFileDetail, grid: _grid)
            else
              _BrowseView(onOpenFile: _openFileDetail, grid: _grid),
          ],
        ),
      ),
    );
  }

  String _titleFor(LibraryLocation location) {
    return switch (location) {
      LibraryRootLocation() => 'File Manager',
      LibraryFolderLocation(:final relativeSubPath, :final category) =>
        relativeSubPath.isEmpty ? category.folderName : location.folderLabel(),
    };
  }

  Future<void> _openFileDetail(LibraryFile file) async {
    if (file.isGalleryImage) {
      final siblings = await _imageSiblings();
      if (!mounted) return;
      await openImageGallery(context, images: siblings, initial: file);
      return;
    }
    if (UniversalViewerScreen.canPlay(file.path, file.mimeType)) {
      await openLibraryFile(context, ref, file);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FileDetailScreen(filePath: file.path),
      ),
    );
  }

  Future<List<LibraryFile>> _imageSiblings() async {
    final searching = ref.read(libraryQueryProvider).search.trim().isNotEmpty;
    if (searching) {
      final files = await ref.read(libraryFilesProvider.future);
      return [
        for (final file in files)
          if (file.isGalleryImage) file,
      ];
    }
    final page = await ref.read(libraryBrowseProvider.future);
    return [
      for (final file in page.files)
        if (file.isGalleryImage) file,
    ];
  }

  Future<void> _showImportSheet(
    BuildContext context,
    List<PendingImport> imports,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ImportSheet(imports: imports, onChanged: _refresh),
    );
  }
}

SliverGridDelegate _galleryGridDelegate(BuildContext context) {
  final wide = MediaQuery.sizeOf(context).width >= UdmBreakpoints.desktop;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: wide ? 3 : 2,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1,
  );
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.location, required this.onNavigate});

  final LibraryLocation location;
  final ValueChanged<LibraryLocation> onNavigate;

  @override
  Widget build(BuildContext context) {
    final segments = <LibraryLocation>[const LibraryRootLocation()];
    if (location is LibraryFolderLocation) {
      final folder = location as LibraryFolderLocation;
      final parts = folder.relativeSubPath.isEmpty
          ? <String>[]
          : folder.relativeSubPath.split('/');
      var current = LibraryFolderLocation(category: folder.category);
      segments.add(current);
      for (final part in parts) {
        current = current.child(part);
        segments.add(current);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const Icon(Icons.chevron_right, size: 18),
            ActionChip(
              label: Text(_labelFor(segments[i])),
              onPressed: segments[i] == location
                  ? null
                  : () => onNavigate(segments[i]),
            ),
          ],
        ],
      ),
    );
  }

  String _labelFor(LibraryLocation loc) => switch (loc) {
    LibraryRootLocation() => 'Home',
    LibraryFolderLocation(:final relativeSubPath, :final category) =>
      relativeSubPath.isEmpty ? category.folderName : loc.folderLabel(),
  };
}

class _BrowseView extends ConsumerWidget {
  const _BrowseView({required this.onOpenFile, required this.grid});

  final ValueChanged<LibraryFile> onOpenFile;
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseAsync = ref.watch(libraryBrowseProvider);
    final location = ref.watch(libraryLocationProvider);

    return browseAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(UdmSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load folder',
        subtitle: error.toString(),
      ),
      data: (page) {
        if (page.isEmpty) {
          return EmptyState(
            icon: Icons.folder_outlined,
            title: location.isRoot ? 'No files yet' : 'Folder is empty',
            subtitle: location.isRoot
                ? 'Download files or import them into category folders.'
                : 'This folder has no files or subfolders.',
          );
        }

        return grid
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: _galleryGridDelegate(context),
                itemCount: page.folders.length + page.files.length,
                itemBuilder: (context, index) {
                  if (index < page.folders.length) {
                    final folder = page.folders[index];
                    return _FolderTile(
                      folder: folder,
                      onTap: () {
                        ref.read(libraryLocationProvider.notifier).state =
                            folder.location;
                      },
                    );
                  }
                  final file = page.files[index - page.folders.length];
                  return _FileGridTile(
                    file: file,
                    onTap: () => onOpenFile(file),
                    onMore: () => _openActions(context, ref, file),
                    onDelete: () => _deleteFile(context, ref, file),
                  );
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: page.folders.length + page.files.length,
                itemBuilder: (context, index) {
                  if (index < page.folders.length) {
                    final folder = page.folders[index];
                    return _FolderTile(
                      folder: folder,
                      onTap: () {
                        ref.read(libraryLocationProvider.notifier).state =
                            folder.location;
                      },
                    );
                  }

                  final file = page.files[index - page.folders.length];
                  return _FileTile(
                    file: file,
                    onTap: () => onOpenFile(file),
                    onMore: () => _openActions(context, ref, file),
                    onDelete: () => _deleteFile(context, ref, file),
                  );
                },
              );
      },
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    LibraryFile file,
  ) async {
    await showFileActionsSheet(
      context: context,
      ref: ref,
      file: file,
      onChanged: () async => invalidateLibrary(ref),
    );
  }

  Future<void> _deleteFile(
    BuildContext context,
    WidgetRef ref,
    LibraryFile file,
  ) {
    return confirmAndDeleteLibraryFile(
      context: context,
      ref: ref,
      file: file,
      onChanged: () async => invalidateLibrary(ref),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.onOpenFile, required this.grid});

  final ValueChanged<LibraryFile> onOpenFile;
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(libraryFilesProvider);

    return filesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(UdmSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Search failed',
        subtitle: error.toString(),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No matching files',
            subtitle: 'Try a different search term or clear filters.',
          );
        }

        return grid
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: _galleryGridDelegate(context),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return _FileGridTile(
                    file: file,
                    onTap: () => onOpenFile(file),
                    onMore: () => _openActions(context, ref, file),
                    onDelete: () => _deleteFile(context, ref, file),
                  );
                },
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return _FileTile(
                    file: file,
                    onTap: () => onOpenFile(file),
                    onMore: () => _openActions(context, ref, file),
                    onDelete: () => _deleteFile(context, ref, file),
                  );
                },
              );
      },
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    LibraryFile file,
  ) {
    return showFileActionsSheet(
      context: context,
      ref: ref,
      file: file,
      onChanged: () async => invalidateLibrary(ref),
    );
  }

  Future<void> _deleteFile(
    BuildContext context,
    WidgetRef ref,
    LibraryFile file,
  ) {
    return confirmAndDeleteLibraryFile(
      context: context,
      ref: ref,
      file: file,
      onChanged: () async => invalidateLibrary(ref),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.onTap});

  final LibraryFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(folder.name),
        subtitle: Text(
          '${folder.itemCount} item${folder.itemCount == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _FileGridTile extends StatelessWidget {
  const _FileGridTile({
    required this.file,
    required this.onTap,
    required this.onMore,
    required this.onDelete,
  });

  final LibraryFile file;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FileThumbnail(file: file, expand: true, borderRadius: 0),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.scrim.withValues(alpha: 0),
                      scheme.scrim.withValues(alpha: 0.72),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    UdmSpacing.sm,
                    UdmSpacing.xl,
                    UdmSpacing.sm,
                    UdmSpacing.sm,
                  ),
                  child: Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: UdmSpacing.xs,
              right: UdmSpacing.xs,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GridIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: UdmSpacing.xs),
                  _GridIconButton(
                    icon: Icons.more_vert,
                    tooltip: 'More actions',
                    onPressed: onMore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridIconButton extends StatelessWidget {
  const _GridIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onInverseSurface,
        backgroundColor: scheme.inverseSurface.withValues(alpha: 0.72),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(6),
      ),
      onPressed: onPressed,
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.onTap,
    required this.onMore,
    required this.onDelete,
  });

  final LibraryFile file;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: FileThumbnail(file: file),
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${file.source.label} · ${file.category.folderName} · ${TransferFormat.bytes(file.sizeBytes)} · ${_formatDate(file.modifiedAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isFavorite)
              Padding(
                padding: const EdgeInsets.only(right: UdmSpacing.xs),
                child: Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More actions',
              visualDensity: VisualDensity.compact,
              onPressed: onMore,
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onMore,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _ImportBanner extends StatelessWidget {
  const _ImportBanner({required this.imports, required this.onReview});

  final List<PendingImport> imports;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: UdmSpacing.lg),
      child: ListTile(
        leading: Icon(
          Icons.file_download_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        title: Text(
          '${imports.length} new file${imports.length == 1 ? '' : 's'} detected',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        subtitle: Text(
          'Review and organize imported files',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: FilledButton(
          onPressed: onReview,
          child: const Text('Review'),
        ),
      ),
    );
  }
}

class _ImportSheet extends ConsumerWidget {
  const _ImportSheet({required this.imports, required this.onChanged});

  final List<PendingImport> imports;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(mediaLibraryServiceProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UdmSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New files', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: UdmSpacing.sm),
            Text(
              'These files were added to your download folder.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: UdmSpacing.lg),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: imports.length,
                itemBuilder: (context, index) {
                  final item = imports[index];
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${TransferFormat.bytes(item.sizeBytes)} · ${item.suggestedCategory ?? 'Unsorted'}',
                    ),
                    trailing: PopupMenuButton<StorageCategory>(
                      icon: const Icon(Icons.drive_file_move_outline),
                      tooltip: 'Move to category',
                      onSelected: (category) async {
                        try {
                          await service.importToCategory(item.path, category);
                          await service.acknowledgeImports([item.path]);
                          await onChanged();
                          if (context.mounted) Navigator.pop(context);
                        } on ArgumentError catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error.message ?? 'Import failed'),
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => MediaLibraryService
                          .browsableCategories
                          .map(
                            (category) => PopupMenuItem(
                              value: category,
                              child: Text(category.folderName),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: UdmSpacing.md),
            FilledButton(
              onPressed: () async {
                await service.acknowledgeImports(imports.map((i) => i.path));
                await onChanged();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Acknowledge all'),
            ),
          ],
        ),
      ),
    );
  }
}
