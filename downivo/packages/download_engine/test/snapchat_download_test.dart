import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  DownloadTask task({
    required String id,
    required DownloadStatus status,
    double progress = 0,
    String url = 'https://www.snapchat.com/spotlight/W7_FIXTURE_SPOTLIGHT_AAAAAQ',
    String fileName = 'snapchat.mp4',
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

  group('Snapchat download state machine', () {
    test('SC-DL-001 queued → preparing → downloading → verifying → completed', () {
      var t = task(id: 'sc-1', status: DownloadStatus.queued);
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

    test('SC-DL-002 downloading → paused → downloading → completed', () {
      var t = task(
        id: 'sc-2',
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

    test('SC-DL-003 downloading → cancelled', () {
      final t = task(
        id: 'sc-3',
        status: DownloadStatus.downloading,
      ).copyWith(status: DownloadStatus.cancelled);
      expect(t.status, DownloadStatus.cancelled);
    });

    test('SC-DL-004 failed → retry queued', () {
      var t = task(
        id: 'sc-4',
        status: DownloadStatus.failed,
        error: 'Network error',
      );
      t = t.copyWith(status: DownloadStatus.queued, progress: 0);
      expect(t.status, DownloadStatus.queued);
    });

    test('SC-DL-005 story snaps have independent states', () {
      final items = [
        task(id: 'g-1', status: DownloadStatus.completed, fileName: 'a.jpg'),
        task(
          id: 'g-2',
          status: DownloadStatus.failed,
          fileName: 'b.jpg',
          error: '404',
        ),
        task(id: 'g-3', status: DownloadStatus.completed, fileName: 'c.jpg'),
      ];
      expect(items.where((i) => i.status == DownloadStatus.completed).length, 2);
      expect(items.where((i) => i.status == DownloadStatus.failed).length, 1);
    });
  });

  group('Snapchat download task properties', () {
    test('SC-DL-010 isActive for in-flight states', () {
      for (final status in [
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.verifying,
      ]) {
        expect(task(id: 'a', status: status).isActive, isTrue);
      }
    });

    test('SC-DL-011 isActive false for terminal/paused', () {
      for (final status in [
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.paused,
      ]) {
        expect(task(id: 'a', status: status).isActive, isFalse);
      }
    });

    test('SC-DL-012 bytesRemaining', () {
      final t = task(
        id: 'b',
        status: DownloadStatus.downloading,
        fileSize: 1000,
        bytesReceived: 250,
      );
      expect(t.bytesRemaining, 750);
    });

    test('SC-DL-013 video MIME stays video/mp4', () {
      final t = task(
        id: 'v',
        status: DownloadStatus.completed,
        fileName: 'clip.mp4',
      ).copyWith(mimeType: 'video/mp4');
      expect(t.mimeType, 'video/mp4');
    });

    test('SC-DL-014 photo MIME stays image/jpeg', () {
      final t = task(
        id: 'd',
        status: DownloadStatus.completed,
        fileName: 'snap.jpg',
      ).copyWith(mimeType: 'image/jpeg');
      expect(t.mimeType, 'image/jpeg');
    });
  });
}
