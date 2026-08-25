/// Content-source filters for the file manager — PRD FR-045A, docs/17 §18.
enum LibrarySourceFilter {
  any,
  youtube,
  tiktok,
  instagram,
  twitter,
  facebook,
  reddit,
  pinterest,
  linkedin,
  threads,
  soundcloud,
  vimeo,
  twitch,
  telegram,
  snapchat,
  whatsapp,
  dailymotion,
  direct,
  unknown,
}

extension LibrarySourceFilterLabel on LibrarySourceFilter {
  String get label => switch (this) {
    LibrarySourceFilter.any => 'Any source',
    LibrarySourceFilter.youtube => 'YouTube',
    LibrarySourceFilter.tiktok => 'TikTok',
    LibrarySourceFilter.instagram => 'Instagram',
    LibrarySourceFilter.twitter => 'X (Twitter)',
    LibrarySourceFilter.facebook => 'Facebook',
    LibrarySourceFilter.reddit => 'Reddit',
    LibrarySourceFilter.pinterest => 'Pinterest',
    LibrarySourceFilter.linkedin => 'LinkedIn',
    LibrarySourceFilter.threads => 'Threads',
    LibrarySourceFilter.soundcloud => 'SoundCloud',
    LibrarySourceFilter.vimeo => 'Vimeo',
    LibrarySourceFilter.twitch => 'Twitch',
    LibrarySourceFilter.telegram => 'Telegram',
    LibrarySourceFilter.snapchat => 'Snapchat',
    LibrarySourceFilter.whatsapp => 'WhatsApp',
    LibrarySourceFilter.dailymotion => 'Dailymotion',
    LibrarySourceFilter.direct => 'Direct URL',
    LibrarySourceFilter.unknown => 'Imported',
  };

  bool matches(LibrarySourceFilter source) =>
      this == LibrarySourceFilter.any || this == source;

  /// Chip order: Any, platforms A–Z, Direct URL, Imported.
  static List<LibrarySourceFilter> get chipOrder {
    final platforms =
        LibrarySourceFilter.values
            .where(
              (value) =>
                  value != LibrarySourceFilter.any &&
                  value != LibrarySourceFilter.direct &&
                  value != LibrarySourceFilter.unknown,
            )
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return [
      LibrarySourceFilter.any,
      ...platforms,
      LibrarySourceFilter.direct,
      LibrarySourceFilter.unknown,
    ];
  }
}

/// Maps a library file path to the content source it was downloaded from.
typedef LibrarySourceIndex =
    Future<Map<String, LibrarySourceFilter>> Function();

/// Called when a managed file is renamed or moved so download metadata can follow.
typedef LibraryPathMoved = Future<void> Function(String from, String to);

/// Called when a managed file is deleted so download rows can drop the path.
typedef LibraryPathDeleted = Future<void> Function(String path);
