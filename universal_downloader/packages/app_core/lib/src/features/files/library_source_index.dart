import 'package:database/database.dart';
import 'package:download_engine/download_engine.dart';
import 'package:media_library/media_library.dart';

/// Builds a path → source map from download records for the file manager filter.
Future<Map<String, LibrarySourceFilter>> downloadLibrarySourceIndex(
  AppDatabase database,
) async {
  final records = await database.getAllDownloads();
  final index = <String, LibrarySourceFilter>{};
  for (final record in records) {
    final path = record.filePath;
    if (path == null || path.trim().isEmpty) continue;
    index[path] = librarySourceFromUrl(record.url);
  }
  return index;
}

LibrarySourceFilter librarySourceFromUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) {
    return LibrarySourceFilter.direct;
  }

  final platform = SocialPlatform.fromUri(uri);
  if (platform == null) return LibrarySourceFilter.direct;

  return switch (platform) {
    SocialPlatform.youtube => LibrarySourceFilter.youtube,
    SocialPlatform.tiktok => LibrarySourceFilter.tiktok,
    SocialPlatform.instagram => LibrarySourceFilter.instagram,
    SocialPlatform.twitter => LibrarySourceFilter.twitter,
    SocialPlatform.facebook => LibrarySourceFilter.facebook,
    SocialPlatform.reddit => LibrarySourceFilter.reddit,
    SocialPlatform.pinterest => LibrarySourceFilter.pinterest,
    SocialPlatform.linkedin => LibrarySourceFilter.linkedin,
    SocialPlatform.threads => LibrarySourceFilter.threads,
    SocialPlatform.soundcloud => LibrarySourceFilter.soundcloud,
    SocialPlatform.vimeo => LibrarySourceFilter.vimeo,
    SocialPlatform.twitch => LibrarySourceFilter.twitch,
    SocialPlatform.telegram => LibrarySourceFilter.telegram,
    SocialPlatform.snapchat => LibrarySourceFilter.snapchat,
    SocialPlatform.whatsapp => LibrarySourceFilter.whatsapp,
    SocialPlatform.dailymotion => LibrarySourceFilter.dailymotion,
  };
}
