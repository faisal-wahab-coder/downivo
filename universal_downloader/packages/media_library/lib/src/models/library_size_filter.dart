/// Size bucket filters — docs/17, PRD FR-044
enum LibrarySizeFilter { any, under1Mb, under10Mb, under100Mb, over100Mb }

extension LibrarySizeFilterLabel on LibrarySizeFilter {
  String get label => switch (this) {
    LibrarySizeFilter.any => 'Any size',
    LibrarySizeFilter.under1Mb => 'Under 1 MB',
    LibrarySizeFilter.under10Mb => 'Under 10 MB',
    LibrarySizeFilter.under100Mb => 'Under 100 MB',
    LibrarySizeFilter.over100Mb => 'Over 100 MB',
  };

  bool matches(int bytes) => switch (this) {
    LibrarySizeFilter.any => true,
    LibrarySizeFilter.under1Mb => bytes < 1024 * 1024,
    LibrarySizeFilter.under10Mb => bytes < 10 * 1024 * 1024,
    LibrarySizeFilter.under100Mb => bytes < 100 * 1024 * 1024,
    LibrarySizeFilter.over100Mb => bytes >= 100 * 1024 * 1024,
  };
}
