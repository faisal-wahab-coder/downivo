import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  test('recoverInterruptedTask resets in-flight statuses to queued', () {
    final interrupted = DownloadTask(
      id: '1',
      url: 'https://example.com/file.bin',
      fileName: 'file.bin',
      status: DownloadStatus.downloading,
      progress: 0.42,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final recovered = interrupted.copyWith(
      status: DownloadStatus.queued,
      updatedAt: DateTime(2026, 1, 2),
    );

    expect(recovered.status, DownloadStatus.queued);
    expect(recovered.progress, 0.42);
  });

  test('completed task without a path is removed from the library', () {
    final kept = DownloadTask(
      id: '1',
      url: 'https://example.com/file.bin',
      fileName: 'file.bin',
      filePath: '/Videos/file.bin',
      status: DownloadStatus.completed,
      progress: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(kept.hasManagedFile, isTrue);
    expect(kept.isRemovedFromLibrary, isFalse);

    final removed = kept.copyWith(clearFilePath: true);
    expect(removed.filePath, isNull);
    expect(removed.isRemovedFromLibrary, isTrue);
  });
}
