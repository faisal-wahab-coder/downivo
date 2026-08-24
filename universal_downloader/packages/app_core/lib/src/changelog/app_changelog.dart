/// User-facing release notes shown after an app update.
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.highlights,
  });

  final String version;
  final List<String> highlights;
}

/// Newest version first. Keep in sync with `CHANGELOG.md` and pubspec version.
const changelogEntries = <ChangelogEntry>[
  ChangelogEntry(
    version: '1.2.0',
    highlights: [
      "What's new after an update, and from Settings → About.",
    ],
  ),
  ChangelogEntry(
    version: '1.1.0',
    highlights: [
      'Save photos and videos to the Gallery album Universal Downloader.',
      'In-app photo viewer: tap a photo in Files, swipe between images, and open details from the viewer.',
      'Social and media URL resolvers: YouTube, TikTok, Instagram, Facebook, Twitter/X, Reddit, Vimeo, Dailymotion, Twitch, Pinterest, LinkedIn, Snapchat, SoundCloud, Telegram, WhatsApp, and Threads.',
    ],
  ),
  ChangelogEntry(
    version: '1.0.0',
    highlights: [
      'Five-tab app shell with Material Design 3 theme and onboarding.',
      'Download engine: queue, pause/resume, cancel, retry, and background downloads.',
      'Managed storage, in-app browser, file manager, and clipboard / share / QR intake.',
    ],
  ),
];

String get latestChangelogVersion => changelogEntries.first.version;

/// Notes the user has not acknowledged yet.
///
/// * First launch after this feature ships (`lastSeenVersion` is null): latest
///   version only.
/// * After a later update: every entry newer than [lastSeenVersion].
/// * Unknown stored version: latest only, so history is not dumped.
List<ChangelogEntry> unreadChangelogEntries(String? lastSeenVersion) {
  if (changelogEntries.isEmpty) return const [];
  if (lastSeenVersion == null) return [changelogEntries.first];
  if (lastSeenVersion == latestChangelogVersion) return const [];

  final unread = <ChangelogEntry>[];
  for (final entry in changelogEntries) {
    if (entry.version == lastSeenVersion) break;
    unread.add(entry);
  }
  if (unread.length == changelogEntries.length) {
    return [changelogEntries.first];
  }
  return unread;
}
