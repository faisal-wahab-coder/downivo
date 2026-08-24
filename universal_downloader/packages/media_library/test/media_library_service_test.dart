import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_library/media_library.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late MediaLibraryService service;
  late ImportTracker tracker;
  late SharedPreferences prefs;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('udm_library_test');
    final paths = StoragePaths(rootPath: root.path);
    final videosDir = Directory(paths.categoryPath(StorageCategory.videos));
    await videosDir.create(recursive: true);
    await File(p.join(videosDir.path, 'alpha.mp4')).writeAsString('aaa');
    await File(p.join(videosDir.path, 'beta.mp4')).writeAsString('bbbbbb');

    final nestedDir = Directory(p.join(videosDir.path, 'clips'));
    await nestedDir.create();
    await File(p.join(nestedDir.path, 'clip.mp4')).writeAsString('cc');

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tracker = ImportTracker(prefs);
    service = MediaLibraryService(
      paths: paths,
      favorites: FavoritesStore(prefs),
      importTracker: tracker,
    );
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('lists and sorts files by name', () async {
    final files = await service.listFiles(
      const LibraryQuery(sort: LibrarySort.nameAsc),
    );
    expect(files, hasLength(3));
    expect(files.first.name, 'alpha.mp4');
  });

  test('renames and deletes files', () async {
    final files = await service.listFiles(const LibraryQuery());
    final target = files.first;

    final renamed = await service.rename(target, 'renamed.mp4');
    expect(await File(renamed.path).exists(), isTrue);

    await service.delete(renamed);
    expect(await File(renamed.path).exists(), isFalse);
  });

  test('delete notifies onFileDeleted', () async {
    String? deletedPath;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final paths = StoragePaths(rootPath: root.path);
    final deletingService = MediaLibraryService(
      paths: paths,
      favorites: FavoritesStore(prefs),
      importTracker: tracker,
      onFileDeleted: (path) async => deletedPath = path,
    );
    final files = await deletingService.listFiles(const LibraryQuery());
    await deletingService.delete(files.first);
    expect(deletedPath, files.first.path);
  });

  test('tracks favorites', () async {
    final files = await service.listFiles(const LibraryQuery());
    await service.toggleFavorite(files.first);

    final favorites = await service.listFiles(
      const LibraryQuery(favoritesOnly: true),
    );
    expect(favorites, hasLength(1));
  });

  test('browses root and nested folders', () async {
    final rootPage = await service.browse(const LibraryRootLocation());
    expect(rootPage.folders, isNotEmpty);

    final videosFolder = rootPage.folders.firstWhere(
      (f) => f.name == StorageCategory.videos.folderName,
    );
    final videosPage = await service.browse(videosFolder.location);
    expect(videosPage.files, hasLength(2));
    expect(videosPage.folders, hasLength(1));

    final nestedPage = await service.browse(videosPage.folders.first.location);
    expect(nestedPage.files.single.name, 'clip.mp4');
  });

  test('filters by size and date', () async {
    final largeOnly = await service.listFiles(
      const LibraryQuery(sizeFilter: LibrarySizeFilter.under10Mb),
    );
    expect(largeOnly, hasLength(3));

    final none = await service.listFiles(
      const LibraryQuery(sizeFilter: LibrarySizeFilter.over100Mb),
    );
    expect(none, isEmpty);
  });

  test('filters by download source', () async {
    final listed = await service.listFiles(const LibraryQuery());
    final alpha = listed.firstWhere((file) => file.name == 'alpha.mp4');
    final beta = listed.firstWhere((file) => file.name == 'beta.mp4');

    service = MediaLibraryService(
      paths: StoragePaths(rootPath: root.path),
      favorites: FavoritesStore(prefs),
      importTracker: tracker,
      sourceIndex: () async => {
        alpha.path: LibrarySourceFilter.youtube,
        beta.path: LibrarySourceFilter.instagram,
      },
    );

    final youtube = await service.listFiles(
      const LibraryQuery(sourceFilter: LibrarySourceFilter.youtube),
    );
    expect(youtube.single.name, 'alpha.mp4');

    final imported = await service.listFiles(
      const LibraryQuery(sourceFilter: LibrarySourceFilter.unknown),
    );
    expect(imported.single.name, 'clip.mp4');
  });

  test('notifies path moves on rename', () async {
    String? from;
    String? to;
    service = MediaLibraryService(
      paths: StoragePaths(rootPath: root.path),
      favorites: FavoritesStore(prefs),
      importTracker: tracker,
      onPathMoved: (oldPath, newPath) async {
        from = oldPath;
        to = newPath;
      },
    );

    final files = await service.listFiles(
      const LibraryQuery(sort: LibrarySort.nameAsc),
    );
    final renamed = await service.rename(files.first, 'renamed.mp4');
    expect(from, files.first.path);
    expect(to, renamed.path);
  });

  test('caches repeated category scans', () async {
    var misses = 0;
    var hits = 0;
    service = MediaLibraryService(
      paths: StoragePaths(rootPath: root.path),
      favorites: FavoritesStore(prefs),
      importTracker: tracker,
      onScanCacheLookup: ({required hit}) {
        if (hit) {
          hits++;
        } else {
          misses++;
        }
      },
    );

    await service.listFiles(const LibraryQuery());
    await service.listFiles(const LibraryQuery());
    expect(misses, greaterThan(0));
    expect(hits, greaterThan(0));
  });

  test('detects pending imports after new file appears', () async {
    await service.syncKnownLibraryPaths();
    expect(await service.detectPendingImports(), isEmpty);

    final paths = StoragePaths(rootPath: root.path);
    final docDir = Directory(paths.categoryPath(StorageCategory.documents));
    await docDir.create(recursive: true);
    await File(p.join(docDir.path, 'new.txt')).writeAsString('hello');

    final pending = await service.detectPendingImports();
    expect(pending, hasLength(1));
    expect(pending.first.name, 'new.txt');
  });
}
