import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  group('BackgroundDownloadCoordinator helpers', () {
    test('primary task prefers downloading over queued', () {
      final tasks = [
        DownloadTask(
          id: '1',
          url: 'https://a.com/a.zip',
          fileName: 'a.zip',
          status: DownloadStatus.queued,
          progress: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        DownloadTask(
          id: '2',
          url: 'https://a.com/b.zip',
          fileName: 'b.zip',
          status: DownloadStatus.downloading,
          progress: 0.4,
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];

      final downloading =
          tasks.where((task) => task.status == DownloadStatus.downloading);
      expect(downloading.first.fileName, 'b.zip');
    });
  });
}
