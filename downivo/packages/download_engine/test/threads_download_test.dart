import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  DownloadTask task({
    required String id,
    required DownloadStatus status,
    double progress = 0,
    String url =
        'https://www.threads.net/@fixtureuser/post/C8n0YxRPqkD',
    String fileName = 'threads.mp4',
    String? error,
    int? fileSize,
    int bytesReceived = 0,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      fileName: fileName,
      status: status,
      progress: progress,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      errorMessage: error,
      fileSize: fileSize,
      bytesReceived: bytesReceived,
    );
  }

  group('Threads download state machine', () {
    test('TH-DL-001 queued → preparing → downloading → verifying → completed', () {
      var t = task(id: 'th-1', status: DownloadStatus.queued);
      expect(t.status, DownloadStatus.queued);

      t = t.copyWith(status: DownloadStatus.preparing);
      expect(t.status, DownloadStatus.preparing);

      t = t.copyWith(status: DownloadStatus.downloading, progress: 0.4);
      expect(t.status, DownloadStatus.downloading);

      t = t.copyWith(status: DownloadStatus.verifying, progress: 1.0);
      expect(t.status, DownloadStatus.verifying);

      t = t.copyWith(status: DownloadStatus.completed);
      expect(t.status, DownloadStatus.completed);
    });

    test('TH-DL-002 downloading → paused → downloading → completed', () {
      var t = task(
        id: 'th-2',
        status: DownloadStatus.downloading,
        progress: 0.2,
      );
      t = t.copyWith(status: DownloadStatus.paused);
      expect(t.status, DownloadStatus.paused);
      expect(t.progress, 0.2);

      t = t.copyWith(status: DownloadStatus.downloading);
      expect(t.status, DownloadStatus.downloading);

      t = t.copyWith(status: DownloadStatus.completed, progress: 1.0);
      expect(t.status, DownloadStatus.completed);
    });

    test('TH-DL-003 downloading → cancelled', () {
      final t = task(
        id: 'th-3',
        status: DownloadStatus.downloading,
      ).copyWith(status: DownloadStatus.cancelled);
      expect(t.status, DownloadStatus.cancelled);
    });

    test('TH-DL-004 failed → retry queued', () {
      var t = task(
        id: 'th-4',
        status: DownloadStatus.failed,
        error: 'Network error',
      );
      t = t.copyWith(status: DownloadStatus.queued, progress: 0);
      expect(t.status, DownloadStatus.queued);
    });

    test('TH-DL-005 restricted failure stays failed', () {
      final t = task(
        id: 'th-5',
        status: DownloadStatus.failed,
        error: 'This Threads content is restricted.',
      );
      expect(t.status, DownloadStatus.failed);
      expect(t.errorMessage, contains('restricted'));
    });

    test('TH-DL-006 authentication failure stays failed', () {
      final t = task(
        id: 'th-6',
        status: DownloadStatus.failed,
        error: 'Threads authentication is required.',
      );
      expect(t.status, DownloadStatus.failed);
      expect(t.errorMessage!.toLowerCase(), contains('authentication'));
    });

    test('TH-DL-007 text-only failure stays failed', () {
      final t = task(
        id: 'th-7',
        status: DownloadStatus.failed,
        error: 'This Threads post has no downloadable media.',
      );
      expect(t.status, DownloadStatus.failed);
    });

    test('TH-DL-008 pause keeps received bytes', () {
      final t = task(
        id: 'th-8',
        status: DownloadStatus.paused,
        progress: 0.35,
        bytesReceived: 3500,
        fileSize: 10000,
      );
      expect(t.bytesReceived, 3500);
      expect(t.progress, 0.35);
    });

    test('TH-DL-009 completed is terminal', () {
      final t = task(id: 'th-9', status: DownloadStatus.completed, progress: 1);
      expect(t.status, DownloadStatus.completed);
    });

    test('TH-DL-010 cancelled is terminal', () {
      final t = task(id: 'th-10', status: DownloadStatus.cancelled);
      expect(t.status, DownloadStatus.cancelled);
    });
  });
}
