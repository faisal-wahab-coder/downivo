import 'dart:io';

import 'package:database/database.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_types/shared_types.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempRoot;
  late AppDatabase appDatabase;
  late DownloadRepository repository;
  late DownloadManager manager;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('udm_history_int');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    appDatabase = AppDatabase();
    await appDatabase.markInitialized();
    repository = DownloadRepository(appDatabase);
    manager = DownloadManager(
      repository: repository,
      storagePaths: StoragePaths(rootPath: p.join(tempRoot.path, 'Downloads')),
    );
  });

  tearDown(() async {
    await manager.dispose();
    await appDatabase.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  DownloadTask _task({
    required String id,
    required DownloadStatus status,
    String? filePath,
  }) {
    final now = DateTime(2026, 8, 15, 12);
    return DownloadTask(
      id: id,
      url: 'https://example.com/$id.bin',
      fileName: '$id.bin',
      filePath: filePath,
      fileSize: 12,
      status: status,
      progress: status == DownloadStatus.completed ? 1 : 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('clearHistory removes finished records but keeps files and active tasks',
      () async {
    final filePath = p.join(tempRoot.path, 'completed.bin');
    await File(filePath).writeAsString('payload');

    await repository.save(
      _task(
        id: 'done',
        status: DownloadStatus.completed,
        filePath: filePath,
      ),
    );
    await repository.save(_task(id: 'failed', status: DownloadStatus.failed));
    await repository.save(
      _task(id: 'active', status: DownloadStatus.paused),
    );

    await manager.loadFromDatabase();
    expect(manager.tasks, hasLength(3));

    final removed = await manager.clearHistory();
    expect(removed, 2);
    expect(manager.tasks, hasLength(1));
    expect(manager.tasks.single.id, 'active');
    expect(await File(filePath).exists(), isTrue);

    final remaining = await repository.getAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.status, DownloadStatus.paused);
  });

  test('enqueue persists task to database', () async {
    await manager.enqueue('https://example.com/file.zip', fileName: 'file.zip');

    final stored = await repository.getAll();
    expect(stored, hasLength(1));
    expect(stored.single.fileName, 'file.zip');
    expect(stored.single.url, 'https://example.com/file.zip');
    expect(manager.tasks, hasLength(1));
  });
}
