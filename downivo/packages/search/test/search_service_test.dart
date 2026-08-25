import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_types/shared_types.dart';
import 'package:storage/storage.dart';
import 'package:udm_search/search.dart';

void main() {
  test('search matches files and downloads', () {
    const service = AppSearchService();
    final hits = service.search(
      query: 'travel',
      files: [
        LibraryFile(
          path: '/Videos/travel.mp4',
          name: 'travel.mp4',
          category: StorageCategory.videos,
          sizeBytes: 12,
          modifiedAt: DateTime(2026, 1, 1),
        ),
      ],
      downloads: [
        DownloadTask(
          id: '1',
          url: 'https://youtube.com/watch?v=1',
          fileName: 'other.mp4',
          title: 'Travel vlog',
          status: DownloadStatus.completed,
          progress: 1,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    expect(hits, hasLength(2));
    expect(hits.map((h) => h.kind), containsAll([SearchHitKind.file, SearchHitKind.download]));
  });
}
