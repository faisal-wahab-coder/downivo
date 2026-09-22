import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'file_store.dart';

/// In-memory [FileStore] used on web (with IndexedDB persistence) and in tests.
class MemoryFileStore implements FileStore {
  final Map<String, Uint8List> _files = {};
  final Map<String, DateTime> _modified = {};
  final Set<String> _dirs = {};
  Future<void> Function()? onChanged;

  String _norm(String path) {
    final normalized = p.posix.normalize(path.replaceAll('\\', '/'));
    if (normalized == '.') return '/';
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  String _parent(String path) {
    final dir = p.posix.dirname(_norm(path));
    return dir.isEmpty ? '/' : dir;
  }

  void _ensureParentDir(String path) {
    var current = _parent(path);
    while (current != '/' && current.isNotEmpty) {
      _dirs.add(current);
      current = _parent(current);
    }
    _dirs.add('/');
  }

  Future<void> _notify() async {
    await onChanged?.call();
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> createDirectory(String path) async {
    final dir = _norm(path);
    _dirs.add(dir);
    _ensureParentDir(dir);
    await _notify();
  }

  @override
  Future<bool> directoryExists(String path) async {
    final dir = _norm(path);
    if (_dirs.contains(dir)) return true;
    return _files.keys.any((file) => file == dir || file.startsWith('$dir/'));
  }

  @override
  Future<bool> exists(String path) async => _files.containsKey(_norm(path));

  @override
  Future<int> length(String path) async {
    final bytes = _files[_norm(path)];
    if (bytes == null) {
      throw StateError('File not found: $path');
    }
    return bytes.length;
  }

  @override
  Future<DateTime> modifiedAt(String path) async {
    return _modified[_norm(path)] ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final target = _norm(path);
    _files.remove(target);
    _modified.remove(target);
    if (recursive) {
      final prefix = '$target/';
      _files.removeWhere((key, _) => key.startsWith(prefix));
      _modified.removeWhere((key, _) => key.startsWith(prefix));
      _dirs.removeWhere((dir) => dir == target || dir.startsWith(prefix));
    } else {
      _dirs.remove(target);
    }
    await _notify();
  }

  @override
  Future<void> writeBytes(String path, List<int> bytes) async {
    final target = _norm(path);
    _ensureParentDir(target);
    _files[target] = Uint8List.fromList(bytes);
    _modified[target] = DateTime.now();
    await _notify();
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final bytes = _files[_norm(path)];
    if (bytes == null) {
      throw StateError('File not found: $path');
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List> readAt(String path, int offset, int length) async {
    final bytes = _files[_norm(path)];
    if (bytes == null) {
      throw StateError('File not found: $path');
    }
    if (length <= 0 || offset < 0 || offset >= bytes.length) return Uint8List(0);
    final end = math.min(offset + length, bytes.length);
    return Uint8List.sublistView(bytes, offset, end);
  }

  @override
  Stream<List<int>> openRead(String path) async* {
    final bytes = _files[_norm(path)];
    if (bytes == null) {
      throw StateError('File not found: $path');
    }
    const chunkSize = 64 * 1024;
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = math.min(offset + chunkSize, bytes.length);
      yield bytes.sublist(offset, end);
    }
  }

  @override
  Future<void> copy(String from, String to) async {
    final bytes = await readBytes(from);
    await writeBytes(to, bytes);
  }

  @override
  Future<void> rename(String from, String to) async {
    await copy(from, to);
    await delete(from);
  }

  @override
  Future<List<FileStoreEntry>> list(
    String path, {
    bool recursive = false,
  }) async {
    final dir = _norm(path);
    final prefix = dir == '/' ? '/' : '$dir/';
    final entries = <FileStoreEntry>[];
    final seenDirs = <String>{};

    for (final filePath in _files.keys) {
      if (filePath == dir) continue;
      if (!filePath.startsWith(prefix) && dir != '/') continue;
      if (dir == '/' && !filePath.startsWith('/')) continue;

      final relative = filePath.substring(prefix.length);
      if (relative.isEmpty) continue;
      final slash = relative.indexOf('/');
      if (!recursive && slash >= 0) {
        final childDir = '$dir/${relative.substring(0, slash)}';
        if (seenDirs.add(childDir)) {
          entries.add(
            FileStoreEntry(
              path: childDir,
              name: relative.substring(0, slash),
              isDirectory: true,
              sizeBytes: 0,
              modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
        }
        continue;
      }
      if (recursive || slash < 0) {
        if (slash < 0 || recursive) {
          if (slash < 0) {
            entries.add(
              FileStoreEntry(
                path: filePath,
                name: p.posix.basename(filePath),
                isDirectory: false,
                sizeBytes: _files[filePath]!.length,
                modifiedAt: _modified[filePath] ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              ),
            );
          }
        }
      }
    }

    if (recursive) {
      for (final filePath in _files.keys) {
        if (!filePath.startsWith(prefix)) continue;
        entries.removeWhere((e) => e.path == filePath && e.isDirectory);
        if (!entries.any((e) => e.path == filePath && !e.isDirectory)) {
          entries.add(
            FileStoreEntry(
              path: filePath,
              name: p.posix.basename(filePath),
              isDirectory: false,
              sizeBytes: _files[filePath]!.length,
              modifiedAt: _modified[filePath] ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
        }
      }
    }

    for (final storedDir in _dirs) {
      if (storedDir == dir) continue;
      if (!storedDir.startsWith(prefix)) continue;
      final relative = storedDir.substring(prefix.length);
      if (relative.isEmpty) continue;
      if (!recursive && relative.contains('/')) continue;
      if (!entries.any((e) => e.path == storedDir)) {
        entries.add(
          FileStoreEntry(
            path: storedDir,
            name: p.posix.basename(storedDir),
            isDirectory: true,
            sizeBytes: 0,
            modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }
    }

    return entries;
  }

  @override
  FileStoreSink openWrite(String path, {bool append = false}) {
    final target = _norm(path);
    _ensureParentDir(target);
    final builder = BytesBuilder(copy: false);
    if (append && _files.containsKey(target)) {
      builder.add(_files[target]!);
    }
    return _MemorySink(this, target, builder);
  }

  @override
  Future<void> saveToUserDisk(String path, String fileName) async {}

  void hydrate({
    required Map<String, Uint8List> files,
    required Map<String, DateTime> modified,
    required Set<String> dirs,
  }) {
    _files
      ..clear()
      ..addAll(files);
    _modified
      ..clear()
      ..addAll(modified);
    _dirs
      ..clear()
      ..addAll(dirs);
  }

  Map<String, Uint8List> snapshotFiles() => Map<String, Uint8List>.from(_files);

  Map<String, DateTime> snapshotModified() =>
      Map<String, DateTime>.from(_modified);

  Set<String> snapshotDirs() => Set<String>.from(_dirs);

  void writeFileDirect(String path, Uint8List bytes, DateTime modified) {
    final target = _norm(path);
    _ensureParentDir(target);
    _files[target] = bytes;
    _modified[target] = modified;
  }
}

class _MemorySink implements FileStoreSink {
  _MemorySink(this._store, this._path, this._builder);

  final MemoryFileStore _store;
  final String _path;
  final BytesBuilder _builder;

  @override
  void add(List<int> chunk) => _builder.add(chunk);

  @override
  Future<void> flush() async {
    _store.writeFileDirect(
      _path,
      Uint8List.fromList(_builder.toBytes()),
      DateTime.now(),
    );
    await _store._notify();
  }

  @override
  Future<void> close() => flush();
}
