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

  setUp(() async {
    root = await Directory.systemTemp.createTemp('udm_library_ops_');
    final paths = StoragePaths(rootPath: root.path);
    final videosDir = Directory(paths.categoryPath(StorageCategory.videos));
    await videosDir.create(recursive: true);
    await File(p.join(videosDir.path, 'alpha.mp4')).writeAsString('aaa');
    await File(p.join(videosDir.path, 'beta.mp4')).writeAsString('bbbbbb');

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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

  test('FM-003 rename collision throws', () async {
    final files = await service.listFiles(const LibraryQuery());
    expect(
      () => service.rename(files.first, files.last.name),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('FM-004 empty rename throws', () async {
    final files = await service.listFiles(const LibraryQuery());
    expect(
      () => service.rename(files.first, '   '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('FM-005 move between categories', () async {
    final files = await service.listFiles(const LibraryQuery());
    final moved = await service.move(files.first, StorageCategory.documents);
    expect(moved.category, StorageCategory.documents);
    expect(await File(moved.path).exists(), isTrue);
    expect(await File(files.first.path).exists(), isFalse);
  });

  test('FM-006 importExternalFile copies source', () async {
    final source = File(p.join(root.path, 'shared.pdf'));
    await source.writeAsString('pdf');
    final imported = await service.importExternalFile(
      source.path,
      StorageCategory.documents,
    );
    expect(await source.exists(), isTrue);
    expect(await File(imported.path).exists(), isTrue);
    expect(imported.category, StorageCategory.documents);
  });

  test('FM-007 importToCategory moves source', () async {
    final source = File(p.join(root.path, 'inbox.txt'));
    await source.writeAsString('txt');
    final imported = await service.importToCategory(
      source.path,
      StorageCategory.documents,
    );
    expect(await source.exists(), isFalse);
    expect(await File(imported.path).exists(), isTrue);
  });

  test('FM-011 addGeneratedFile keeps the source and writes audio', () async {
    final paths = StoragePaths(rootPath: root.path);
    final source = File(p.join(paths.categoryPath(StorageCategory.videos), 'alpha.mp4'));
    final saved = await service.addGeneratedFile(
      fileName: 'alpha.m4a',
      bytes: [1, 2, 3, 4],
      category: StorageCategory.audio,
      mimeType: 'audio/mp4',
    );

    expect(await source.exists(), isTrue);
    expect(saved.category, StorageCategory.audio);
    expect(saved.name, 'alpha.m4a');
    expect(await File(saved.path).readAsBytes(), [1, 2, 3, 4]);
  });

  test('FM-009 saveToGallery rejects non-media', () async {
    final paths = StoragePaths(rootPath: root.path);
    final docs = Directory(paths.categoryPath(StorageCategory.documents));
    await docs.create(recursive: true);
    await File(p.join(docs.path, 'note.pdf')).writeAsString('pdf');
    service.invalidateScanCache();

    final files = await service.listFiles(const LibraryQuery());
    final pdf = files.firstWhere((f) => f.name == 'note.pdf');
    final result = await service.saveToGallery(pdf);
    expect(result.success, isFalse);
    expect(result.message, contains('photos and videos'));
  });

  test('FM-010 saveToGallery copies via injected saver', () async {
    LibraryFile? saved;
    final paths = StoragePaths(rootPath: root.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final galleryService = MediaLibraryService(
      paths: paths,
      favorites: FavoritesStore(prefs),
      importTracker: ImportTracker(prefs),
      saveToGalleryImpl: (file) async {
        saved = file;
        return const LibraryGallerySaveResult(
          success: true,
          message: 'Saved to Gallery',
        );
      },
    );

    final files = await galleryService.listFiles(const LibraryQuery());
    final video = files.firstWhere((f) => f.name == 'alpha.mp4');
    final result = await galleryService.saveToGallery(video);
    expect(result.success, isTrue);
    expect(saved?.name, 'alpha.mp4');
    expect(await File(video.path).exists(), isTrue);
  });

  test('FM-008 fileAt returns null for missing path', () async {
    expect(await service.fileAt(p.join(root.path, 'missing.bin')), isNull);
  });

  test('ML-001 search filters by name', () async {
    final files = await service.listFiles(const LibraryQuery(search: 'alpha'));
    expect(files, hasLength(1));
    expect(files.single.name, 'alpha.mp4');
  });

  test('ML-002 and ML-003 category summaries and totals', () async {
    final summaries = await service.categorySummaries();
    final videos = summaries.firstWhere(
      (item) => item.category == StorageCategory.videos,
    );
    expect(videos.fileCount, 2);
    expect(await service.totalManagedFileCount(), 2);
    expect(await service.totalManagedBytes(), greaterThan(0));
  });

  test('ML-004 date filter today keeps recent files', () async {
    final files = await service.listFiles(
      const LibraryQuery(dateFilter: LibraryDateFilter.today),
    );
    expect(files, hasLength(2));
  });

  test('ML-005 acknowledgeImports clears pending', () async {
    await service.syncKnownLibraryPaths();
    final paths = StoragePaths(rootPath: root.path);
    final docs = Directory(paths.categoryPath(StorageCategory.documents));
    await docs.create(recursive: true);
    final added = File(p.join(docs.path, 'new.txt'));
    await added.writeAsString('hello');

    final pending = await service.detectPendingImports();
    expect(pending, hasLength(1));
    await service.acknowledgeImports(pending.map((item) => item.path));
    expect(await service.detectPendingImports(), isEmpty);
  });

  test('PF-004 listing 200 files stays under 1s', () async {
    final paths = StoragePaths(rootPath: root.path);
    final docs = Directory(paths.categoryPath(StorageCategory.documents));
    await docs.create(recursive: true);
    for (var i = 0; i < 200; i++) {
      await File(p.join(docs.path, 'file_$i.txt')).writeAsString('$i');
    }
    service.invalidateScanCache();

    final sw = Stopwatch()..start();
    final files = await service.listFiles(const LibraryQuery());
    sw.stop();
    expect(files.length, greaterThanOrEqualTo(200));
    expect(sw.elapsedMilliseconds, lessThan(1000));
  });
}
