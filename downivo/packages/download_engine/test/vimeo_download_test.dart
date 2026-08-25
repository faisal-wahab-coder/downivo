import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  DownloadTask task({
    required String id,
    required DownloadStatus status,
    double progress = 0,
    String url = 'https://vimeo.com/76979871',
    String fileName = 'vimeo.mp4',
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

  group('Vimeo download state machine', () {
    test('VM-DL-001 queued → preparing → downloading → verifying → completed', () {
      var t = task(id: 'vm-1', status: DownloadStatus.queued);
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

    test('VM-DL-002 downloading → paused → downloading → completed', () {
      var t = task(
        id: 'vm-2',
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

    test('VM-DL-003 downloading → cancelled', () {
      final t = task(
        id: 'vm-3',
        status: DownloadStatus.downloading,
      ).copyWith(status: DownloadStatus.cancelled);
      expect(t.status, DownloadStatus.cancelled);
    });

    test('VM-DL-004 failed → retry queued', () {
      var t = task(
        id: 'vm-4',
        status: DownloadStatus.failed,
        error: 'Network error',
      );
      t = t.copyWith(status: DownloadStatus.queued, progress: 0);
      expect(t.status, DownloadStatus.queued);
    });
  });

  group('Vimeo download task properties', () {
    test('VM-DL-010 isActive for in-flight states', () {
      for (final status in [
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.verifying,
      ]) {
        expect(task(id: 'a', status: status).isActive, isTrue);
      }
    });

    test('VM-DL-011 isActive false for terminal/paused', () {
      for (final status in [
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.paused,
      ]) {
        expect(task(id: 'a', status: status).isActive, isFalse);
      }
    });

    test('VM-DL-012 bytesRemaining', () {
      final t = task(
        id: 'b',
        status: DownloadStatus.downloading,
        fileSize: 1000,
        bytesReceived: 250,
      );
      expect(t.bytesRemaining, 750);
    });
  });

  group('Vimeo file naming via download resolver', () {
    test('VM-DL-020 video MIME → .mp4', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://vod-progressive.akamaized.net/file.mp4'),
          contentType: 'video/mp4',
        ),
        endsWith('.mp4'),
      );
    });

    test('VM-DL-021 quality is encoded in discovered filename', () {
      expect(
        VimeoResolver.buildFileName(
          videoId: '76979871',
          title: 'The New Vimeo Player',
          quality: '1080p',
          mimeType: 'video/mp4',
        ),
        allOf(contains('1080p'), endsWith('.mp4')),
      );
    });
  });

  group('Vimeo DownloadStatus storage', () {
    test('VM-DL-030 storage round-trip', () {
      for (final status in DownloadStatus.values) {
        expect(DownloadStatus.fromStorage(status.storageValue), status);
      }
    });
  });

  group('Vimeo duplicate identity for downloads', () {
    test('VM-DL-040 canonical and player map to the same identity', () {
      expect(
        VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/76979871')),
        VimeoUri.contentIdentity(
          Uri.parse('https://player.vimeo.com/video/76979871?autoplay=1'),
        ),
      );
    });
  });
}
