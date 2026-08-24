import 'dart:io';

import 'package:database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  late AppDatabase db;

  DownloadRecord record({
    required String id,
    required String status,
    String fileName = '',
    String? filePath,
  }) {
    final now = DateTime(2026, 8, 15, 12);
    return DownloadRecord(
      id: id,
      url: 'https://example.com/$id.bin',
      domain: 'example.com',
      fileName: fileName,
      filePath: filePath,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('udm_db_qa_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    db = AppDatabase();
  });

  tearDown(() async {
    await db.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('DB-001 creates schema and marks initialized', () async {
    await db.markInitialized();
    expect(await db.isInitialized(), isTrue);
  });

  test('DB-002 insert getById update delete round-trip', () async {
    await db.insertDownload(
      record(id: 'one', status: 'QUEUED', fileName: 'a.bin'),
    );
    final stored = await db.getDownloadById('one');
    expect(stored?.fileName, 'a.bin');
    expect(stored?.domain, 'example.com');

    await db.updateDownload(
      record(id: 'one', status: 'COMPLETED', fileName: 'a.bin'),
    );
    expect((await db.getDownloadById('one'))?.status, 'COMPLETED');

    await db.deleteDownload('one');
    expect(await db.getDownloadById('one'), isNull);
  });

  test(
    'DB-003 deleteDownloadsWithStatuses removes only matching rows',
    () async {
      await db.insertDownload(record(id: '1', status: 'COMPLETED'));
      await db.insertDownload(record(id: '2', status: 'QUEUED'));

      final removed = await db.deleteDownloadsWithStatuses([
        'COMPLETED',
        'FAILED',
      ]);
      expect(removed, 1);
      expect((await db.getAllDownloads()).single.id, '2');
    },
  );

  test('DB-004 metadata get and set', () async {
    expect(await db.getMetadata('download_queue_order'), isNull);
    await db.setMetadata('download_queue_order', '["a","b"]');
    expect(await db.getMetadata('download_queue_order'), '["a","b"]');
  });

  test('DB-005 upgrades v1 schema and keeps rows', () async {
    await db.close();
    final dbPath = p.join(tempRoot.path, 'universal_downloader.db');
    final v1 = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE downloads (
            id TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            domain TEXT,
            file_name TEXT NOT NULL DEFAULT '',
            file_path TEXT,
            file_size INTEGER,
            mime_type TEXT,
            status TEXT NOT NULL,
            priority TEXT NOT NULL DEFAULT 'NORMAL',
            progress REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            started_at TEXT,
            completed_at TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX idx_downloads_status ON downloads(status)',
        );
      },
    );
    final now = DateTime(2026, 8, 15).toIso8601String();
    await v1.insert('downloads', {
      'id': 'legacy',
      'url': 'https://legacy.test/file.bin',
      'file_name': 'file.bin',
      'status': 'QUEUED',
      'priority': 'NORMAL',
      'progress': 0,
      'created_at': now,
      'updated_at': now,
    });
    await v1.close();

    db = AppDatabase();
    final rows = await db.getAllDownloads();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'legacy');

    final raw = await db.database;
    final indexes = await raw.rawQuery("PRAGMA index_list('downloads')");
    final names = indexes.map((row) => row['name']).toSet();
    expect(names, contains('idx_downloads_created_at'));
    expect(names, contains('idx_downloads_updated_at'));
    expect(names, contains('idx_downloads_file_path'));
  });

  test('DB-006 DownloadRecord.fromMap applies defaults', () {
    final mapped = DownloadRecord.fromMap({
      'id': 'x',
      'url': 'https://x.test',
      'status': 'QUEUED',
      'created_at': '2026-08-15T00:00:00.000',
      'updated_at': '2026-08-15T00:00:00.000',
    });
    expect(mapped.fileName, '');
    expect(mapped.priority, 'NORMAL');
    expect(mapped.progress, 0);
  });

  test('DB-007 updateDownloadFilePath follows library rename', () async {
    await db.insertDownload(
      record(
        id: 'moved',
        status: 'COMPLETED',
        fileName: 'old.bin',
        filePath: '/library/Videos/old.bin',
      ),
    );

    final updated = await db.updateDownloadFilePath(
      oldPath: '/library/Videos/old.bin',
      newPath: '/library/Images/new.bin',
    );
    expect(updated, 1);

    final stored = await db.getDownloadById('moved');
    expect(stored?.filePath, '/library/Images/new.bin');
    expect(stored?.fileName, 'new.bin');
  });

  test('DB-008 clearDownloadFilePath keeps the row', () async {
    await db.insertDownload(
      record(
        id: 'gone',
        status: 'COMPLETED',
        fileName: 'clip.mp4',
        filePath: '/library/Videos/clip.mp4',
      ),
    );

    final updated = await db.clearDownloadFilePath('/library/Videos/clip.mp4');
    expect(updated, 1);

    final stored = await db.getDownloadById('gone');
    expect(stored?.filePath, isNull);
    expect(stored?.fileName, 'clip.mp4');
    expect(stored?.status, 'COMPLETED');
  });
}
