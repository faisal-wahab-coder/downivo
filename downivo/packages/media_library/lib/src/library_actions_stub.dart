import 'package:storage/storage.dart';

import 'library_gallery_save_result.dart';
import 'library_open_result.dart';
import 'models/library_file.dart';

Future<LibraryOpenResult> openLibraryFileWithChooserOnPlatform(
  LibraryFile file,
  FileStore store,
) async {
  return const LibraryOpenResult(
    success: false,
    message: 'Open with is available on Android.',
  );
}

Future<LibraryOpenResult> openLibraryFileOnPlatform(
  LibraryFile file,
  FileStore store,
) async {
  await store.saveToUserDisk(file.path, file.name);
  return const LibraryOpenResult(success: true);
}

Future<void> shareLibraryFileOnPlatform(
  LibraryFile file,
  FileStore store,
) async {}

Future<LibraryGallerySaveResult> saveLibraryFileToGalleryOnPlatform(
  LibraryFile file,
) async {
  return const LibraryGallerySaveResult(
    success: false,
    message: 'Saving to Gallery is not available on this platform.',
  );
}
