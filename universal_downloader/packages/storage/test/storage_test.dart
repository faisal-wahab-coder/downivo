import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:storage/storage.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ST-001 creates category folders under root', () async {
    final tempRoot = Directory.systemTemp.createTempSync('udm_storage_test');
    addTearDown(() => tempRoot.deleteSync(recursive: true));

    final paths = StoragePaths(
      rootPath: p.join(tempRoot.path, 'Downloads', 'Universal Downloader'),
    );
    final store = createFileStore();
    await store.createDirectory(paths.rootPath);
    for (final category in StorageCategory.values) {
      await store.createDirectory(paths.categoryPath(category));
    }

    for (final category in StorageCategory.values) {
      expect(await store.directoryExists(paths.categoryPath(category)), isTrue);
    }
  });

  test('ST-002 StorageInitializer is idempotent', () async {
    final tempRoot = Directory.systemTemp.createTempSync('udm_storage_init');
    addTearDown(() => tempRoot.deleteSync(recursive: true));
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);

    final initializer = StorageInitializer();
    final first = await initializer.initialize();
    final second = await initializer.initialize();

    expect(first.rootPath, second.rootPath);
    for (final category in StorageCategory.values) {
      expect(
        await initializer.fileStore.directoryExists(first.categoryPath(category)),
        isTrue,
      );
    }
  });

  test('ST-003 resolve uses Downloads/Universal Downloader', () async {
    final tempRoot = Directory.systemTemp.createTempSync('udm_storage_resolve');
    addTearDown(() => tempRoot.deleteSync(recursive: true));
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);

    final paths = await StoragePaths.resolve();
    expect(paths.rootPath, contains(StoragePaths.downloadsSegment));
    expect(paths.rootPath, contains(StoragePaths.appFolderName));
  });

  test('ST-004 allCategoryPaths matches enum length', () {
    final paths = StoragePaths(rootPath: '/tmp/udm');
    expect(paths.allCategoryPaths(), hasLength(StorageCategory.values.length));
  });

  test('ST-005 zero free space uses calculating label', () {
    final info = StorageInfo(
      rootPath: '/tmp/udm',
      freeBytes: 0,
      totalBytes: 0,
    );
    expect(info.formattedFreeSpace, 'Calculating…');
    expect(info.hasVolumeStats, isFalse);
  });

  test('ST-006 load reports volume stats on IO', () async {
    final tempRoot = Directory.systemTemp.createTempSync('udm_storage_info');
    addTearDown(() => tempRoot.deleteSync(recursive: true));
    final info = await StorageInfo.load(StoragePaths(rootPath: tempRoot.path));
    expect(info.rootPath, tempRoot.path);
    expect(info.hasVolumeStats, isTrue);
    expect(info.totalBytes, greaterThan(0));
    expect(info.freeBytes, greaterThan(0));
  });
}
