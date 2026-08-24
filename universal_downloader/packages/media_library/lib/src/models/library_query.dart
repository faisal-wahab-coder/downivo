import 'package:storage/storage.dart';

import 'library_date_filter.dart';
import 'library_size_filter.dart';
import 'library_sort.dart';
import 'library_source_filter.dart';

/// Filter and sort parameters for listing library files.
class LibraryQuery {
  const LibraryQuery({
    this.search = '',
    this.category,
    this.favoritesOnly = false,
    this.sort = LibrarySort.newest,
    this.sizeFilter = LibrarySizeFilter.any,
    this.dateFilter = LibraryDateFilter.any,
    this.sourceFilter = LibrarySourceFilter.any,
  });

  final String search;
  final StorageCategory? category;
  final bool favoritesOnly;
  final LibrarySort sort;
  final LibrarySizeFilter sizeFilter;
  final LibraryDateFilter dateFilter;
  final LibrarySourceFilter sourceFilter;

  bool get hasActiveFilters =>
      sizeFilter != LibrarySizeFilter.any ||
      dateFilter != LibraryDateFilter.any ||
      sourceFilter != LibrarySourceFilter.any ||
      category != null ||
      favoritesOnly;

  LibraryQuery copyWith({
    String? search,
    StorageCategory? category,
    bool? favoritesOnly,
    LibrarySort? sort,
    LibrarySizeFilter? sizeFilter,
    LibraryDateFilter? dateFilter,
    LibrarySourceFilter? sourceFilter,
    bool clearCategory = false,
    bool clearFilters = false,
  }) {
    return LibraryQuery(
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sort: sort ?? this.sort,
      sizeFilter: clearFilters
          ? LibrarySizeFilter.any
          : (sizeFilter ?? this.sizeFilter),
      dateFilter: clearFilters
          ? LibraryDateFilter.any
          : (dateFilter ?? this.dateFilter),
      sourceFilter: clearFilters
          ? LibrarySourceFilter.any
          : (sourceFilter ?? this.sourceFilter),
    );
  }
}
