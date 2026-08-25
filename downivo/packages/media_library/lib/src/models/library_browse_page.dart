import 'library_file.dart';
import 'library_folder.dart';
import 'library_location.dart';

/// Direct children at a browse location.
class LibraryBrowsePage {
  const LibraryBrowsePage({
    required this.location,
    required this.folders,
    required this.files,
  });

  final LibraryLocation location;
  final List<LibraryFolder> folders;
  final List<LibraryFile> files;

  bool get isEmpty => folders.isEmpty && files.isEmpty;
}
