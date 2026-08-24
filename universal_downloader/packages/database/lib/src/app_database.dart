import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'models/download_record.dart';
import 'sqflite_init.dart';

/// SQLite v1 schema — docs/13.6, ADR-002 (Drift planned for M2 codegen).
class AppDatabase {
  AppDatabase({Database? database}) : _database = database;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  static const schemaVersion = 4;

  Future<Database> _open() async {
    await ensureSqfliteInitialized();
    final path = await resolveDatabasePath();
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
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
            updated_at TEXT NOT NULL,
            thumbnail_url TEXT,
            platform TEXT,
            title TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_downloads_status ON downloads(status)',
        );
        await db.execute(
          'CREATE INDEX idx_downloads_created_at ON downloads(created_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_downloads_updated_at ON downloads(updated_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_downloads_file_path ON downloads(file_path)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_downloads_created_at ON downloads(created_at DESC)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_downloads_updated_at ON downloads(updated_at DESC)',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_downloads_file_path ON downloads(file_path)',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE downloads ADD COLUMN thumbnail_url TEXT',
          );
          await db.execute('ALTER TABLE downloads ADD COLUMN platform TEXT');
          await db.execute('ALTER TABLE downloads ADD COLUMN title TEXT');
        }
      },
    );
  }

  Future<void> markInitialized() async {
    final db = await database;
    await db.insert('app_metadata', {
      'key': 'db_initialized',
      'value': 'true',
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isInitialized() async {
    final db = await database;
    final rows = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['db_initialized'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['value'] == 'true';
  }

  Future<void> insertDownload(DownloadRecord record) async {
    final db = await database;
    await db.insert(
      'downloads',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DownloadRecord>> getAllDownloads() async {
    final db = await database;
    final rows = await db.query('downloads', orderBy: 'created_at DESC');
    return rows.map(DownloadRecord.fromMap).toList();
  }

  Future<DownloadRecord?> getDownloadById(String id) async {
    final db = await database;
    final rows = await db.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DownloadRecord.fromMap(rows.first);
  }

  Future<void> updateDownload(DownloadRecord record) async {
    final db = await database;
    await db.update(
      'downloads',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Keeps download metadata attached after a library rename or move.
  Future<int> updateDownloadFilePath({
    required String oldPath,
    required String newPath,
  }) async {
    if (oldPath.isEmpty || newPath.isEmpty || oldPath == newPath) return 0;
    final db = await database;
    return db.update(
      'downloads',
      {
        'file_path': newPath,
        'file_name': _fileNameFromPath(newPath),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'file_path = ?',
      whereArgs: [oldPath],
    );
  }

  /// Detaches download rows from a library file that was deleted.
  /// History stays; [file_path] is cleared so UI can show Removed from Files.
  Future<int> clearDownloadFilePath(String path) async {
    if (path.isEmpty) return 0;
    final db = await database;
    return db.update(
      'downloads',
      {
        'file_path': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'file_path = ?',
      whereArgs: [path],
    );
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }

  Future<void> deleteDownload(String id) async {
    final db = await database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  /// Removes download records by status — does not touch files on disk.
  Future<int> deleteDownloadsWithStatuses(List<String> statuses) async {
    if (statuses.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(statuses.length, '?').join(', ');
    return db.delete(
      'downloads',
      where: 'status IN ($placeholders)',
      whereArgs: statuses,
    );
  }

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert('app_metadata', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
