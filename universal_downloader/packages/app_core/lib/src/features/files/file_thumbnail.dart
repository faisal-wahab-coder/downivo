import 'package:flutter/material.dart';
import 'package:media_library/media_library.dart';
import 'package:storage/storage.dart';

import 'file_image_stub.dart' if (dart.library.io) 'file_image_io.dart';

/// Thumbnail or category icon for a library file.
class FileThumbnail extends StatelessWidget {
  const FileThumbnail({
    super.key,
    required this.file,
    this.size = 48,
    this.expand = false,
    this.borderRadius = 8,
  });

  final LibraryFile file;
  final double size;
  final bool expand;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = _icon(context);
    if (!file.isGalleryImage) {
      return fallback;
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (expand) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : size;
          final cacheWidth = (width * dpr).round().clamp(64, 1024);
          final image = libraryFileImage(
            file,
            width: width,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
            cacheWidth: cacheWidth,
            errorFallback: fallback,
          );
          if (image == null) return fallback;
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox.expand(child: image),
          );
        },
      );
    }

    final cacheWidth = (size * dpr).round().clamp(48, 512);
    final image = libraryFileImage(
      file,
      width: size,
      height: size,
      cacheWidth: cacheWidth,
      errorFallback: fallback,
    );
    if (image == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }

  Widget _icon(BuildContext context) {
    return Container(
      width: expand ? null : size,
      height: expand ? null : size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        _iconForFile(),
        size: expand ? 48 : size * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  IconData _iconForFile() {
    if (file.isGalleryImage) return Icons.image_outlined;
    if (file.isGalleryVideo) return Icons.movie_outlined;
    return _iconForCategory(file.category);
  }

  IconData _iconForCategory(StorageCategory category) => switch (category) {
    StorageCategory.videos => Icons.movie_outlined,
    StorageCategory.images => Icons.image_outlined,
    StorageCategory.audio => Icons.audiotrack_outlined,
    StorageCategory.documents => Icons.description_outlined,
    StorageCategory.archives => Icons.folder_zip_outlined,
    StorageCategory.apk => Icons.android_outlined,
    StorageCategory.qrDownloads => Icons.qr_code_2_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
