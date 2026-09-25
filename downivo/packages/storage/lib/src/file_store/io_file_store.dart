import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'file_store.dart';

class IoFileStore implements FileStore {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  @override
  Future<bool> directoryExists(String path) => Directory(path).exists();

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<int> length(String path) => File(path).length();

  @override
  Future<DateTime> modifiedAt(String path) async {
    final stat = await File(path).stat();
    return stat.modified;
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return;
    }
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: recursive);
    }
  }

  @override
  Future<void> writeBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List> readBytes(String path) => File(path).readAsBytes();

  @override
  Future<Uint8List> readAt(String path, int offset, int length) async {
    if (length <= 0 || offset < 0) return Uint8List(0);
    final file = await File(path).open();
    try {
      await file.setPosition(offset);
      final builder = BytesBuilder(copy: false);
      var remaining = length;
      while (remaining > 0) {
        final chunk = await file.read(remaining > 1024 * 1024 ? 1024 * 1024 : remaining);
        if (chunk.isEmpty) break;
        builder.add(chunk);
        remaining -= chunk.length;
      }
      return builder.toBytes();
    } finally {
      await file.close();
    }
  }

  @override
  Stream<List<int>> openRead(String path) => File(path).openRead();

  @override
  Future<void> copy(String from, String to) async {
    final target = File(to);
    await target.parent.create(recursive: true);
    await File(from).copy(to);
  }

  @override
  Future<void> rename(String from, String to) async {
    final target = File(to);
    await target.parent.create(recursive: true);
    await File(from).rename(to);
  }

  @override
  Future<List<FileStoreEntry>> list(
    String path, {
    bool recursive = false,
  }) async {
    final dir = Directory(path);
    if (!await dir.exists()) return const [];

    final entries = <FileStoreEntry>[];
    await for (final entity in dir.list(
      recursive: recursive,
      followLinks: false,
    )) {
      try {
        final stat = await entity.stat();
        entries.add(
          FileStoreEntry(
            path: entity.path,
            name: p.basename(entity.path),
            isDirectory: entity is Directory,
            sizeBytes: entity is File ? stat.size : 0,
            modifiedAt: stat.modified,
          ),
        );
      } on Object {
        continue;
      }
    }
    return entries;
  }

  @override
  FileStoreSink openWrite(String path, {bool append = false}) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final sink = file.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    return _IoSink(sink);
  }

  @override
  Future<void> saveToUserDisk(String path, String fileName) async {}
}

class _IoSink implements FileStoreSink {
  _IoSink(this._sink);

  final IOSink _sink;

  @override
  void add(List<int> chunk) => _sink.add(chunk);

  @override
  Future<void> flush() => _sink.flush();

  @override
  Future<void> close() => _sink.close();
}
