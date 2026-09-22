import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:performance/performance.dart';
import 'package:storage/storage.dart';

import 'favorites_store.dart';
import 'import_tracker.dart';
import 'library_actions.dart';
import 'library_gallery_save_result.dart';
import 'library_open_result.dart';
import 'models/category_summary.dart';
import 'models/library_browse_page.dart';
import 'models/library_date_filter.dart';
import 'models/library_file.dart';
import 'models/library_folder.dart';
import 'models/library_location.dart';
import 'models/library_query.dart';
import 'models/library_size_filter.dart';
import 'models/library_sort.dart';
import 'models/library_source_filter.dart';
import 'models/pending_import.dart';

/// Scans managed folders and performs file operations — docs/14, docs/17
class MediaLibraryService {
  MediaLibraryService({
    required StoragePaths paths,
    required FavoritesStore favorites,
    FileStore? fileStore,
    ImportTracker? importTracker,
    LibrarySourceIndex? sourceIndex,
    LibraryPathMoved? onPathMoved,
    LibraryPathDeleted? onFileDeleted,
    void Function({required bool hit})? onScanCacheLookup,
    Future<LibraryGallerySaveResult> Function(LibraryFile file)?
    saveToGalleryImpl,
  }) : _paths = paths,
       _fileStore = fileStore ?? createFileStore(),
       _favorites = favorites,
       _imports = importTracker,
       _sourceIndex = sourceIndex,
       _onPathMoved = onPathMoved,
       _onFileDeleted = onFileDeleted,
       _onScanCacheLookup = onScanCacheLookup,
       _saveToGalleryImpl = saveToGalleryImpl ?? saveLibraryFileToGallery;

  static const browsableCategories = [
    StorageCategory.videos,
    StorageCategory.images,
    StorageCategory.audio,
    StorageCategory.documents,
    StorageCategory.archives,
    StorageCategory.apk,
    StorageCategory.qrDownloads,
  ];

  final StoragePaths _paths;
  final FileStore _fileStore;
  final FavoritesStore _favorites;
  final ImportTracker? _imports;
  final LibrarySourceIndex? _sourceIndex;
  final LibraryPathMoved? _onPathMoved;
  final LibraryPathDeleted? _onFileDeleted;
  final Future<LibraryGallerySaveResult> Function(LibraryFile file)
  _saveToGalleryImpl;
  final TimedCache<String, List<LibraryFile>> _scanCache =
      TimedCache<String, List<LibraryFile>>();
  final void Function({required bool hit})? _onScanCacheLookup;

  void invalidateScanCache() => _scanCache.clear();

  Future<List<CategorySummary>> categorySummaries() async {
    final summaries = <CategorySummary>[];
    for (final category in browsableCategories) {
      final files = await _scanCategoryRecursive(category);
      summaries.add(
        CategorySummary(
          category: category,
          fileCount: files.length,
          totalBytes: files.fold<int>(0, (sum, f) => sum + f.sizeBytes),
        ),
      );
    }
    return summaries;
  }

  Future<int> totalManagedBytes() async {
    var total = 0;
    for (final category in browsableCategories) {
      final files = await _scanCategoryRecursive(category);
      total += files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    }
    return total;
  }

  Future<int> totalManagedFileCount() async {
    var total = 0;
    for (final category in browsableCategories) {
      final files = await _scanCategoryRecursive(category);
      total += files.length;
    }
    return total;
  }

  Future<LibraryBrowsePage> browse(
    LibraryLocation location, {
    LibraryQuery query = const LibraryQuery(),
  }) async {
    return switch (location) {
      LibraryRootLocation() => _browseRoot(query),
      LibraryFolderLocation(:final category, :final relativeSubPath) =>
        _browseFolder(category, relativeSubPath, query),
    };
  }

  Future<List<LibraryFile>> listFiles(LibraryQuery query) async {
    final favorites = _favorites.paths;
    final files = <LibraryFile>[];

    final categories = query.category != null
        ? [query.category!]
        : browsableCategories;

    for (final category in categories) {
      final scanned = await _scanCategoryRecursive(category);
      files.addAll(
        scanned.map(
          (file) => file.copyWith(isFavorite: favorites.contains(file.path)),
        ),
      );
    }

    return _applyQueryFilters(files, query);
  }

  Future<List<PendingImport>> detectPendingImports() async {
    if (_imports == null) return [];

    if (_imports!.knownPaths.isEmpty) {
      await syncKnownLibraryPaths();
      return [];
    }

    invalidateScanCache();

    final allPaths = <String>[];
    for (final category in browsableCategories) {
      final files = await _scanCategoryRecursive(category);
      allPaths.addAll(files.map((f) => f.path));
    }

    final rootEntries = await _fileStore.list(_paths.rootPath);
    for (final entry in rootEntries) {
      if (!entry.isDirectory) {
        allPaths.add(entry.path);
      }
    }

    final known = _imports!.knownPaths;
    final pending = allPaths.where((path) => !known.contains(path)).toList();

    final results = <PendingImport>[];
    for (final path in pending) {
      if (!await _fileStore.exists(path)) continue;
      results.add(
        PendingImport(
          path: path,
          name: p.basename(path),
          sizeBytes: await _fileStore.length(path),
          modifiedAt: await _fileStore.modifiedAt(path),
          suggestedCategory: categoryForPath(path)?.folderName,
        ),
      );
    }

    results.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return results;
  }

  Future<void> acknowledgeImports(Iterable<String> paths) async {
    await _imports?.acknowledgePaths(paths);
  }

  Future<void> syncKnownLibraryPaths() async {
    if (_imports == null) return;
    invalidateScanCache();
    final files = await listFiles(const LibraryQuery());
    await _imports!.rememberPaths(files.map((f) => f.path));
  }

  Future<LibraryFile?> fileAt(String path) async {
    if (!await _fileStore.exists(path)) return null;
    final category = categoryForPath(path);
    if (category == null) return null;
    final file = LibraryFile(
      path: path,
      name: p.basename(path),
      category: category,
      sizeBytes: await _fileStore.length(path),
      modifiedAt: await _fileStore.modifiedAt(path),
      isFavorite: _favorites.isFavorite(path),
      mimeType: lookupMimeType(path),
    );
    final withSource = await _attachSources([file]);
    return withSource.first;
  }

  StorageCategory? categoryForPath(String filePath) {
    final normalized = p.normalize(filePath);
    for (final category in browsableCategories) {
      final dir = p.normalize(_paths.categoryPath(category));
      if (normalized.startsWith(dir)) {
        return category;
      }
    }
    return null;
  }

  Future<LibraryFile> rename(LibraryFile file, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('File name cannot be empty.');
    }
    final dir = p.dirname(file.path);
    final target = p.join(dir, trimmed);
    if (await _fileStore.exists(target)) {
      throw ArgumentError('A file with that name already exists.');
    }

    final oldPath = file.path;
    await _fileStore.rename(oldPath, target);
    invalidateScanCache();
    if (_favorites.isFavorite(oldPath)) {
      await _favorites.toggle(oldPath);
      await _favorites.toggle(target);
    }

    await _onPathMoved?.call(oldPath, target);

    return file.copyWith(
      path: target,
      name: trimmed,
      modifiedAt: await _fileStore.modifiedAt(target),
      mimeType: lookupMimeType(target),
    );
  }

  Future<LibraryFile> move(
    LibraryFile file,
    StorageCategory targetCategory,
  ) async {
    if (file.category == targetCategory) return file;

    final targetDir = _paths.categoryPath(targetCategory);
    if (!await _fileStore.directoryExists(targetDir)) {
      await _fileStore.createDirectory(targetDir);
    }

    var targetPath = p.join(targetDir, file.name);
    if (await _fileStore.exists(targetPath)) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(file.name);
      final base = p.basenameWithoutExtension(file.name);
      targetPath = p.join(targetDir, '${base}_$stamp$ext');
    }

    final oldPath = file.path;
    await _fileStore.rename(oldPath, targetPath);
    invalidateScanCache();
    if (_favorites.isFavorite(oldPath)) {
      await _favorites.toggle(oldPath);
      await _favorites.toggle(targetPath);
    }
    await _onPathMoved?.call(oldPath, targetPath);

    return file.copyWith(
      path: targetPath,
      category: targetCategory,
      modifiedAt: await _fileStore.modifiedAt(targetPath),
      mimeType: lookupMimeType(targetPath),
    );
  }

  Future<LibraryFile> importExternalFile(
    String sourcePath,
    StorageCategory targetCategory,
  ) async {
    if (!await _fileStore.exists(sourcePath)) {
      throw ArgumentError('Shared file no longer exists.');
    }

    final targetDir = _paths.categoryPath(targetCategory);
    if (!await _fileStore.directoryExists(targetDir)) {
      await _fileStore.createDirectory(targetDir);
    }

    var targetPath = p.join(targetDir, p.basename(sourcePath));
    if (await _fileStore.exists(targetPath)) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(sourcePath);
      final base = p.basenameWithoutExtension(sourcePath);
      targetPath = p.join(targetDir, '${base}_$stamp$ext');
    }

    await _fileStore.copy(sourcePath, targetPath);
    invalidateScanCache();
    await _imports?.acknowledgePaths([targetPath]);

    return LibraryFile(
      path: targetPath,
      name: p.basename(targetPath),
      category: targetCategory,
      sizeBytes: await _fileStore.length(targetPath),
      modifiedAt: await _fileStore.modifiedAt(targetPath),
      mimeType: lookupMimeType(targetPath),
    );
  }

  Future<LibraryFile> importToCategory(
    String sourcePath,
    StorageCategory targetCategory,
  ) async {
    if (!await _fileStore.exists(sourcePath)) {
      throw ArgumentError('File no longer exists.');
    }

    final targetDir = _paths.categoryPath(targetCategory);
    if (!await _fileStore.directoryExists(targetDir)) {
      await _fileStore.createDirectory(targetDir);
    }

    var targetPath = p.join(targetDir, p.basename(sourcePath));
    if (await _fileStore.exists(targetPath)) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(sourcePath);
      final base = p.basenameWithoutExtension(sourcePath);
      targetPath = p.join(targetDir, '${base}_$stamp$ext');
    }

    await _fileStore.rename(sourcePath, targetPath);
    invalidateScanCache();
    await _imports?.acknowledgePaths([sourcePath, targetPath]);
    await _onPathMoved?.call(sourcePath, targetPath);

    return LibraryFile(
      path: targetPath,
      name: p.basename(targetPath),
      category: targetCategory,
      sizeBytes: await _fileStore.length(targetPath),
      modifiedAt: await _fileStore.modifiedAt(targetPath),
      mimeType: lookupMimeType(targetPath),
    );
  }

  Future<Uint8List> readFile(String path) => _fileStore.readBytes(path);

  Future<int> fileLength(String path) => _fileStore.length(path);

  Future<Uint8List> readFileAt(String path, int offset, int length) =>
      _fileStore.readAt(path, offset, length);

  /// Writes a new library file and leaves any source file in place.
  Future<LibraryFile> addGeneratedFile({
    required String fileName,
    required List<int> bytes,
    required StorageCategory category,
    String? mimeType,
  }) async {
    final targetDir = _paths.categoryPath(category);
    if (!await _fileStore.directoryExists(targetDir)) {
      await _fileStore.createDirectory(targetDir);
    }

    final safeName = p.basename(fileName);
    var targetPath = p.join(targetDir, safeName);
    if (await _fileStore.exists(targetPath)) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(safeName);
      final base = p.basenameWithoutExtension(safeName);
      targetPath = p.join(targetDir, '${base}_$stamp$ext');
    }

    await _fileStore.writeBytes(targetPath, bytes);
    invalidateScanCache();
    await _imports?.acknowledgePaths([targetPath]);

    return LibraryFile(
      path: targetPath,
      name: p.basename(targetPath),
      category: category,
      sizeBytes: bytes.length,
      modifiedAt: await _fileStore.modifiedAt(targetPath),
      mimeType: mimeType ?? lookupMimeType(targetPath),
    );
  }

  Future<void> delete(LibraryFile file) async {
    if (await _fileStore.exists(file.path)) {
      await _fileStore.delete(file.path);
    }
    invalidateScanCache();
    if (_favorites.isFavorite(file.path)) {
      await _favorites.toggle(file.path);
    }
    await _onFileDeleted?.call(file.path);
  }

  Future<bool> toggleFavorite(LibraryFile file) {
    return _favorites.toggle(file.path);
  }

  Future<LibraryOpenResult> open(LibraryFile file) =>
      openLibraryFile(file, _fileStore);

  Future<void> share(LibraryFile file) {
    return shareLibraryFile(file, _fileStore);
  }

  /// Copies a photo or video into the system gallery. The original stays
  /// in the managed library.
  Future<LibraryGallerySaveResult> saveToGallery(LibraryFile file) {
    if (!file.canSaveToGallery) {
      return Future.value(
        const LibraryGallerySaveResult(
          success: false,
          message: 'Only photos and videos can be saved to the Gallery.',
        ),
      );
    }
    return _saveToGalleryImpl(file);
  }

  String absolutePathFor(LibraryFolderLocation location) {
    final base = _paths.categoryPath(location.category);
    if (location.relativeSubPath.isEmpty) return base;
    return p.join(base, location.relativeSubPath);
  }

  Future<LibraryBrowsePage> _browseRoot(LibraryQuery query) async {
    final summaries = await categorySummaries();
    final folders = summaries
        .map(
          (summary) => LibraryFolder(
            name: summary.category.folderName,
            path: _paths.categoryPath(summary.category),
            location: LibraryFolderLocation(category: summary.category),
            itemCount: summary.fileCount,
          ),
        )
        .toList();

    final rootFiles = <LibraryFile>[];
    final rootEntries = await _fileStore.list(_paths.rootPath);
    for (final entry in rootEntries) {
      if (entry.isDirectory) continue;
      rootFiles.add(
        LibraryFile(
          path: entry.path,
          name: entry.name,
          category: StorageCategory.documents,
          sizeBytes: entry.sizeBytes,
          modifiedAt: entry.modifiedAt,
          isFavorite: _favorites.isFavorite(entry.path),
          mimeType: lookupMimeType(entry.path),
        ),
      );
    }

    return LibraryBrowsePage(
      location: const LibraryRootLocation(),
      folders: folders,
      files: await _applyQueryFilters(rootFiles, query),
    );
  }

  Future<LibraryBrowsePage> _browseFolder(
    StorageCategory category,
    String relativeSubPath,
    LibraryQuery query,
  ) async {
    final location = LibraryFolderLocation(
      category: category,
      relativeSubPath: relativeSubPath,
    );
    final dirPath = absolutePathFor(location);
    if (!await _fileStore.directoryExists(dirPath)) {
      return LibraryBrowsePage(location: location, folders: [], files: []);
    }

    final folders = <LibraryFolder>[];
    final files = <LibraryFile>[];

    final entries = await _fileStore.list(dirPath);
    for (final entry in entries) {
      if (entry.isDirectory) {
        final count = await _countDescendants(entry.path, category);
        folders.add(
          LibraryFolder(
            name: entry.name,
            path: entry.path,
            location: location.child(entry.name),
            itemCount: count,
          ),
        );
      } else {
        files.add(
          LibraryFile(
            path: entry.path,
            name: entry.name,
            category: category,
            sizeBytes: entry.sizeBytes,
            modifiedAt: entry.modifiedAt,
            isFavorite: _favorites.isFavorite(entry.path),
            mimeType: lookupMimeType(entry.path),
          ),
        );
      }
    }

    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return LibraryBrowsePage(
      location: location,
      folders: folders,
      files: await _applyQueryFilters(files, query),
    );
  }

  Future<int> _countDescendants(
    String dirPath,
    StorageCategory category,
  ) async {
    final normalized = p.normalize(dirPath);
    final prefix = normalized.endsWith('/') ? normalized : '$normalized/';
    final files = await _scanCategoryRecursive(category);
    return files
        .where((file) => p.normalize(file.path).startsWith(prefix))
        .length;
  }

  Future<List<LibraryFile>> _scanCategoryRecursive(
    StorageCategory category,
  ) async {
    final cacheKey = '${_paths.rootPath}:${category.name}';
    final cached = _scanCache.get(cacheKey);
    if (cached != null) {
      _onScanCacheLookup?.call(hit: true);
      return cached;
    }

    _onScanCacheLookup?.call(hit: false);
    final files = await _performCategoryScan(category);
    _scanCache.set(cacheKey, files);
    return files;
  }

  Future<List<LibraryFile>> _performCategoryScan(
    StorageCategory category,
  ) async {
    final dirPath = _paths.categoryPath(category);
    if (!await _fileStore.directoryExists(dirPath)) return [];

    final files = <LibraryFile>[];
    final entries = await _fileStore.list(dirPath, recursive: true);
    for (final entry in entries) {
      if (entry.isDirectory) continue;
      files.add(
        LibraryFile(
          path: entry.path,
          name: entry.name,
          category: category,
          sizeBytes: entry.sizeBytes,
          modifiedAt: entry.modifiedAt,
          mimeType: lookupMimeType(entry.path),
        ),
      );
    }
    return files;
  }

  Future<List<LibraryFile>> _applyQueryFilters(
    List<LibraryFile> files,
    LibraryQuery query,
  ) async {
    var result = await _attachSources(files);

    if (query.favoritesOnly) {
      result = result.where((f) => f.isFavorite).toList();
    }

    final search = query.search.trim().toLowerCase();
    if (search.isNotEmpty) {
      result = result
          .where(
            (f) =>
                f.name.toLowerCase().contains(search) ||
                f.extension.contains(search),
          )
          .toList();
    }

    if (query.sizeFilter != LibrarySizeFilter.any) {
      result = result
          .where((f) => query.sizeFilter.matches(f.sizeBytes))
          .toList();
    }

    if (query.dateFilter != LibraryDateFilter.any) {
      result = result
          .where((f) => query.dateFilter.matches(f.modifiedAt))
          .toList();
    }

    if (query.sourceFilter != LibrarySourceFilter.any) {
      result = result
          .where((f) => query.sourceFilter.matches(f.source))
          .toList();
    }

    result.sort(_compare(query.sort));
    return result;
  }

  Future<List<LibraryFile>> _attachSources(List<LibraryFile> files) async {
    final lookup = _sourceIndex;
    if (lookup == null || files.isEmpty) return files;

    final index = await lookup();
    if (index.isEmpty) return files;

    final normalized = <String, LibrarySourceFilter>{
      for (final entry in index.entries) p.normalize(entry.key): entry.value,
    };

    return [
      for (final file in files)
        file.copyWith(
          source:
              normalized[p.normalize(file.path)] ?? LibrarySourceFilter.unknown,
        ),
    ];
  }

  int Function(LibraryFile a, LibraryFile b) _compare(LibrarySort sort) {
    return switch (sort) {
      LibrarySort.newest => (a, b) => b.modifiedAt.compareTo(a.modifiedAt),
      LibrarySort.oldest => (a, b) => a.modifiedAt.compareTo(b.modifiedAt),
      LibrarySort.nameAsc => (a, b) => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
      LibrarySort.nameDesc => (a, b) => b.name.toLowerCase().compareTo(
        a.name.toLowerCase(),
      ),
      LibrarySort.largest => (a, b) => b.sizeBytes.compareTo(a.sizeBytes),
      LibrarySort.smallest => (a, b) => a.sizeBytes.compareTo(b.sizeBytes),
    };
  }
}
