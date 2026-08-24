import 'package:storage/storage.dart';

/// Sort options for the media library — docs/10.6 §9
enum LibrarySort { newest, oldest, nameAsc, nameDesc, largest, smallest }

extension LibrarySortLabel on LibrarySort {
  String get label => switch (this) {
    LibrarySort.newest => 'Newest',
    LibrarySort.oldest => 'Oldest',
    LibrarySort.nameAsc => 'Name (A–Z)',
    LibrarySort.nameDesc => 'Name (Z–A)',
    LibrarySort.largest => 'Largest',
    LibrarySort.smallest => 'Smallest',
  };
}
