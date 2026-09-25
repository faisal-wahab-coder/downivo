import 'package:storage/storage.dart';

import 'library_gallery_save_result.dart';
import 'library_open_result.dart';
import 'models/library_file.dart';
import 'library_actions_stub.dart'
    if (dart.library.io) 'library_actions_io.dart'
    if (dart.library.html) 'library_actions_web.dart';

Future<LibraryOpenResult> openLibraryFile(LibraryFile file, FileStore store) =>
    openLibraryFileOnPlatform(file, store);

Future<LibraryOpenResult> openLibraryFileWithChooser(
  LibraryFile file,
  FileStore store,
) => openLibraryFileWithChooserOnPlatform(file, store);

/// Rejects empty names and path separators. Shared by folder creation.
String validatedFolderName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('Folder name cannot be empty.');
  }
  if (trimmed == '.' ||
      trimmed == '..' ||
      trimmed.contains('/') ||
      trimmed.contains('\\')) {
    throw ArgumentError('Folder name cannot include / or \\.');
  }
  if (trimmed.length > 120) {
    throw ArgumentError('Folder name is too long.');
  }
  return trimmed;
}

Future<void> shareLibraryFile(LibraryFile file, FileStore store) =>
    shareLibraryFileOnPlatform(file, store);

Future<LibraryGallerySaveResult> saveLibraryFileToGallery(LibraryFile file) =>
    saveLibraryFileToGalleryOnPlatform(file);
