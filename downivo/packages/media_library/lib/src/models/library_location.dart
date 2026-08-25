import 'package:storage/storage.dart';

/// A navigable point in the managed folder tree.
sealed class LibraryLocation {
  const LibraryLocation();

  bool get isRoot => this is LibraryRootLocation;

  LibraryLocation? get parent => switch (this) {
    LibraryRootLocation() => null,
    LibraryFolderLocation(:final relativeSubPath, :final category) =>
      relativeSubPath.isEmpty
          ? const LibraryRootLocation()
          : LibraryFolderLocation(
              category: category,
              relativeSubPath: _parentPath(relativeSubPath),
            ),
  };

  static String _parentPath(String relativeSubPath) {
    final separator = relativeSubPath.contains('/') ? '/' : '\\';
    final index = relativeSubPath.lastIndexOf(separator);
    if (index <= 0) return '';
    return relativeSubPath.substring(0, index);
  }
}

class LibraryRootLocation extends LibraryLocation {
  const LibraryRootLocation();
}

class LibraryFolderLocation extends LibraryLocation {
  const LibraryFolderLocation({
    required this.category,
    this.relativeSubPath = '',
  });

  final StorageCategory category;
  final String relativeSubPath;

  LibraryFolderLocation child(String folderName) {
    final next = relativeSubPath.isEmpty
        ? folderName
        : '$relativeSubPath/$folderName';
    return LibraryFolderLocation(category: category, relativeSubPath: next);
  }

  String folderLabel() => relativeSubPath.isEmpty
      ? category.folderName
      : relativeSubPath.split('/').last;
}
