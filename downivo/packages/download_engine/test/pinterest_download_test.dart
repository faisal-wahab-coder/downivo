import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  DownloadTask task({
    required String id,
    required DownloadStatus status,
    double progress = 0,
    String url = 'https://www.pinterest.com/pin/123/',
    String fileName = 'pin.jpg',
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

  group('Pinterest download state machine', () {
    test('PT-DL-001 queued → preparing → downloading → verifying → completed', () {
      var t = task(id: 'pt-1', status: DownloadStatus.queued);
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

    test('PT-DL-002 downloading → paused → downloading → completed', () {
      var t = task(
        id: 'pt-2',
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

    test('PT-DL-003 downloading → cancelled', () {
      final t = task(
        id: 'pt-3',
        status: DownloadStatus.downloading,
      ).copyWith(status: DownloadStatus.cancelled);
      expect(t.status, DownloadStatus.cancelled);
    });

    test('PT-DL-004 failed → retry queued', () {
      var t = task(
        id: 'pt-4',
        status: DownloadStatus.failed,
        error: 'Network error',
      );
      t = t.copyWith(status: DownloadStatus.queued, progress: 0);
      expect(t.status, DownloadStatus.queued);
    });

    test('PT-DL-005 idea pin items have independent states', () {
      final items = [
        task(id: 'g-1', status: DownloadStatus.completed, fileName: 'a.jpg'),
        task(
          id: 'g-2',
          status: DownloadStatus.failed,
          fileName: 'b.jpg',
          error: '404',
        ),
        task(id: 'g-3', status: DownloadStatus.completed, fileName: 'c.mp4'),
      ];
      expect(items.where((i) => i.status == DownloadStatus.completed).length, 2);
      expect(items.where((i) => i.status == DownloadStatus.failed).length, 1);
      expect(items.every((i) => i.status == DownloadStatus.completed), isFalse);
    });
  });

  group('Pinterest download task properties', () {
    test('PT-DL-010 isActive for in-flight states', () {
      for (final status in [
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.verifying,
      ]) {
        expect(task(id: 'a', status: status).isActive, isTrue);
      }
    });

    test('PT-DL-011 isActive false for terminal/paused', () {
      for (final status in [
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.paused,
      ]) {
        expect(task(id: 'a', status: status).isActive, isFalse);
      }
    });

    test('PT-DL-012 bytesRemaining', () {
      final t = task(
        id: 'b',
        status: DownloadStatus.downloading,
        fileSize: 1000,
        bytesReceived: 250,
      );
      expect(t.bytesRemaining, 750);
    });
  });

  group('Pinterest file naming via download resolver', () {
    test('PT-DL-020 video MIME → .mp4', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://v1.pinimg.com/videos/mc/720p/x.mp4'),
          contentType: 'video/mp4',
        ),
        endsWith('.mp4'),
      );
    });

    test('PT-DL-021 image/jpeg MIME → .jpg', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://i.pinimg.com/originals/x'),
          contentType: 'image/jpeg',
        ),
        endsWith('.jpg'),
      );
    });

    test('PT-DL-022 image/webp MIME → .webp', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://i.pinimg.com/originals/x'),
          contentType: 'image/webp',
        ),
        endsWith('.webp'),
      );
    });

    test('PT-DL-023 image/png MIME → .png', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://i.pinimg.com/originals/x'),
          contentType: 'image/png',
        ),
        endsWith('.png'),
      );
    });
  });

  group('Pinterest DownloadStatus storage', () {
    test('PT-DL-030 storage round-trip', () {
      for (final status in DownloadStatus.values) {
        expect(DownloadStatus.fromStorage(status.storageValue), status);
      }
    });
  });
}
