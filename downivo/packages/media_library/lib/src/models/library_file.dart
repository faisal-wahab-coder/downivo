import 'package:storage/storage.dart';

import '../gallery_media.dart';
import 'library_source_filter.dart';

/// A file discovered under managed storage.
class LibraryFile {
  const LibraryFile({
    required this.path,
    required this.name,
    required this.category,
    required this.sizeBytes,
    required this.modifiedAt,
    this.isFavorite = false,
    this.mimeType,
    this.source = LibrarySourceFilter.unknown,
  });

  final String path;
  final String name;
  final StorageCategory category;
  final int sizeBytes;
  final DateTime modifiedAt;
  final bool isFavorite;
  final String? mimeType;
  final LibrarySourceFilter source;

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return '';
    return name.substring(dot).toLowerCase();
  }

  /// Photos and videos can be copied into the system gallery.
  bool get canSaveToGallery =>
      isGallerySaveable(path: path, mimeType: mimeType);

  bool get isGalleryImage =>
      isGalleryImageMedia(path: path, mimeType: mimeType);

  bool get isGalleryVideo =>
      isGalleryVideoMedia(path: path, mimeType: mimeType);

  LibraryFile copyWith({
    String? path,
    String? name,
    StorageCategory? category,
    int? sizeBytes,
    DateTime? modifiedAt,
    bool? isFavorite,
    String? mimeType,
    LibrarySourceFilter? source,
  }) {
    return LibraryFile(
      path: path ?? this.path,
      name: name ?? this.name,
      category: category ?? this.category,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      mimeType: mimeType ?? this.mimeType,
      source: source ?? this.source,
    );
  }
}
