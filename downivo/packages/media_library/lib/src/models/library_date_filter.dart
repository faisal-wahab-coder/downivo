/// Modified-date filters — PRD FR-045
enum LibraryDateFilter { any, today, thisWeek, thisMonth }

extension LibraryDateFilterLabel on LibraryDateFilter {
  String get label => switch (this) {
    LibraryDateFilter.any => 'Any date',
    LibraryDateFilter.today => 'Today',
    LibraryDateFilter.thisWeek => 'This week',
    LibraryDateFilter.thisMonth => 'This month',
  };

  bool matches(DateTime modifiedAt) {
    if (this == LibraryDateFilter.any) return true;
    final now = DateTime.now();
    final local = modifiedAt.toLocal();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return switch (this) {
      LibraryDateFilter.today => !local.isBefore(startOfToday),
      LibraryDateFilter.thisWeek => !local.isBefore(
        startOfToday.subtract(Duration(days: now.weekday - 1)),
      ),
      LibraryDateFilter.thisMonth =>
        local.year == now.year && local.month == now.month,
      LibraryDateFilter.any => true,
    };
  }
}
