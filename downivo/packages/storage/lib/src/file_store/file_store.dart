import 'dart:typed_data';

/// Platform-agnostic file operations — IO on Android, OPFS/IndexedDB on web.
abstract class FileStore {
  Future<void> initialize() async {}

  Future<void> createDirectory(String path);

  Future<bool> directoryExists(String path);

  Future<bool> exists(String path);

  Future<int> length(String path);

  Future<DateTime> modifiedAt(String path);

  Future<void> delete(String path, {bool recursive = false});

  Future<void> writeBytes(String path, List<int> bytes);

  Future<Uint8List> readBytes(String path);

  /// Reads [path] in chunks so large files are not loaded all at once.
  Stream<List<int>> openRead(String path);

  Future<void> copy(String from, String to);

  Future<void> rename(String from, String to);

  Future<List<FileStoreEntry>> list(String path, {bool recursive = false});

  FileStoreSink openWrite(String path, {bool append = false});

  /// Triggers a browser download. No-op when the file is already on disk.
  Future<void> saveToUserDisk(String path, String fileName);
}

class FileStoreEntry {
  const FileStoreEntry({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int sizeBytes;
  final DateTime modifiedAt;
}

abstract class FileStoreSink {
  void add(List<int> chunk);

  Future<void> flush();

  Future<void> close();
}
