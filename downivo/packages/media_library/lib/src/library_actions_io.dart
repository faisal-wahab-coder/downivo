import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storage/storage.dart';

import 'library_gallery_save_result.dart';
import 'library_open_result.dart';
import 'models/library_file.dart';

Future<LibraryOpenResult> openLibraryFileOnPlatform(
  LibraryFile file,
  FileStore store,
) async {
  final result = await OpenFilex.open(file.path);
  return LibraryOpenResult(
    success: result.type == ResultType.done,
    message: result.message,
  );
}

Future<void> shareLibraryFileOnPlatform(LibraryFile file, FileStore store) {
  return SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: file.name),
  );
}

Future<LibraryGallerySaveResult> saveLibraryFileToGalleryOnPlatform(
  LibraryFile file,
) async {
  try {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        return const LibraryGallerySaveResult(
          success: false,
          message: 'Gallery permission denied.',
        );
      }
    }

    const album = StoragePaths.appFolderName;
    if (file.isGalleryVideo) {
      await Gal.putVideo(file.path, album: album);
    } else {
      await Gal.putImage(file.path, album: album);
    }
    return const LibraryGallerySaveResult(
      success: true,
      message: 'Saved to Gallery',
    );
  } on GalException catch (error) {
    return LibraryGallerySaveResult(
      success: false,
      message: error.type.message,
    );
  } catch (error) {
    return LibraryGallerySaveResult(success: false, message: error.toString());
  }
}
