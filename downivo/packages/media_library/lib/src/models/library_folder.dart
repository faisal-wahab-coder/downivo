import 'library_location.dart';

/// A subfolder entry inside a browse page.
class LibraryFolder {
  const LibraryFolder({
    required this.name,
    required this.path,
    required this.location,
    required this.itemCount,
  });

  final String name;
  final String path;
  final LibraryFolderLocation location;
  final int itemCount;
}
