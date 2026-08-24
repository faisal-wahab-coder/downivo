import 'package:download_engine/download_engine.dart';
import 'package:media_library/media_library.dart';

import 'search_hit.dart';

class AppSearchService {
  const AppSearchService();

  List<SearchHit> search({
    required String query,
    required List<LibraryFile> files,
    required List<DownloadTask> downloads,
  }) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final hits = <SearchHit>[];
    for (final file in files) {
      final haystack = [
        file.name,
        file.mimeType ?? '',
        file.source.label,
        file.category.folderName,
      ].join(' ').toLowerCase();
      if (!haystack.contains(needle)) continue;
      hits.add(
        SearchHit(
          id: 'file:${file.path}',
          kind: SearchHitKind.file,
          title: file.name,
          subtitle: file.source.label,
          path: file.path,
        ),
      );
    }
    for (final task in downloads) {
      final haystack = [
        task.fileName,
        task.title ?? '',
        task.platform ?? '',
        task.url,
      ].join(' ').toLowerCase();
      if (!haystack.contains(needle)) continue;
      hits.add(
        SearchHit(
          id: 'download:${task.id}',
          kind: SearchHitKind.download,
          title: task.title?.trim().isNotEmpty == true
              ? task.title!
              : task.fileName,
          subtitle: task.platform ?? task.status.storageValue,
          thumbnailUrl: task.thumbnailUrl,
          downloadId: task.id,
          path: task.filePath,
        ),
      );
    }
    return hits;
  }
}
