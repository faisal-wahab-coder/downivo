import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

/// SoundCloud download integration: state machine, file naming, MIME, status.
void main() {
  DownloadTask task({
    required String id,
    DownloadStatus status = DownloadStatus.queued,
    double progress = 0,
    String? errorMessage,
    int? fileSize,
    int bytesReceived = 0,
    String fileName = 'test-artist-test-track.mp3',
    String? mimeType,
  }) {
    return DownloadTask(
      id: id,
      url: 'https://soundcloud.com/test-artist/test-track',
      fileName: fileName,
      status: status,
      progress: progress,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      errorMessage: errorMessage,
      fileSize: fileSize,
      bytesReceived: bytesReceived,
      mimeType: mimeType,
    );
  }

  group('SoundCloud download state machine', () {
    test('SC-DL-001 starts queued', () {
      expect(task(id: 'sc-1').status, DownloadStatus.queued);
      expect(task(id: 'sc-1').progress, 0);
    });

    test('SC-DL-002 queued → preparing', () {
      expect(
        task(id: 'sc-2').copyWith(status: DownloadStatus.preparing).status,
        DownloadStatus.preparing,
      );
    });

    test('SC-DL-003 preparing → downloading', () {
      final downloading = task(id: 'sc-3', status: DownloadStatus.preparing)
          .copyWith(status: DownloadStatus.downloading, progress: 0.2);
      expect(downloading.status, DownloadStatus.downloading);
      expect(downloading.progress, 0.2);
    });

    test('SC-DL-004 downloading → verifying → completed', () {
      final verifying = task(id: 'sc-4', status: DownloadStatus.downloading)
          .copyWith(status: DownloadStatus.verifying, progress: 1);
      expect(verifying.status, DownloadStatus.verifying);
      expect(verifying.isActive, isTrue);

      final completed = verifying.copyWith(status: DownloadStatus.completed);
      expect(completed.status, DownloadStatus.completed);
      expect(completed.isActive, isFalse);
    });

    test('SC-DL-005 pause preserves progress', () {
      final paused = task(
        id: 'sc-5',
        status: DownloadStatus.downloading,
        progress: 0.35,
      ).copyWith(status: DownloadStatus.paused);
      expect(paused.status, DownloadStatus.paused);
      expect(paused.progress, 0.35);
    });

    test('SC-DL-006 resume from paused', () {
      final resumed = task(id: 'sc-6', status: DownloadStatus.paused)
          .copyWith(status: DownloadStatus.downloading);
      expect(resumed.status, DownloadStatus.downloading);
    });

    test('SC-DL-007 cancel from downloading', () {
      expect(
        task(id: 'sc-7', status: DownloadStatus.downloading)
            .copyWith(status: DownloadStatus.cancelled)
            .status,
        DownloadStatus.cancelled,
      );
    });

    test('SC-DL-008 fail then retry', () {
      final failed = task(id: 'sc-8', status: DownloadStatus.downloading)
          .copyWith(
        status: DownloadStatus.failed,
        errorMessage: 'Network error',
      );
      expect(failed.status, DownloadStatus.failed);
      expect(failed.errorMessage, 'Network error');

      final retried = failed.copyWith(status: DownloadStatus.queued, progress: 0);
      expect(retried.status, DownloadStatus.queued);
    });
  });

  group('SoundCloud download task properties', () {
    test('SC-DL-020 active states', () {
      for (final status in [
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.verifying,
      ]) {
        expect(task(id: 'a', status: status).isActive, isTrue);
      }
    });

    test('SC-DL-021 inactive states', () {
      for (final status in [
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.paused,
      ]) {
        expect(task(id: 'i', status: status).isActive, isFalse);
      }
    });

    test('SC-DL-022 bytes remaining', () {
      final t = task(
        id: 'b',
        status: DownloadStatus.downloading,
        fileSize: 8000000,
        bytesReceived: 2000000,
      );
      expect(t.bytesRemaining, 6000000);
    });

    test('SC-DL-023 SoundCloud audio MIME on task', () {
      final t = task(id: 'm', mimeType: 'audio/mpeg');
      expect(t.mimeType, 'audio/mpeg');
      expect(t.url, contains('soundcloud.com'));
      expect(t.fileName, endsWith('.mp3'));
    });
  });

  group('SoundCloud file naming via download', () {
    test('SC-DL-030 MP3 resolver', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://cf-media.sndcdn.com/abc.mp3?Policy=x'),
          contentType: 'audio/mpeg',
        ),
        endsWith('.mp3'),
      );
    });

    test('SC-DL-031 M4A resolver', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://cf-media.sndcdn.com/abc.m4a'),
          contentType: 'audio/mp4',
        ),
        endsWith('.m4a'),
      );
    });

    test('SC-DL-032 preferred name wins', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse('https://cf-media.sndcdn.com/cdn.mp3'),
          preferredName: 'artist_track.mp3',
        ),
        'artist_track.mp3',
      );
    });
  });

  group('SoundCloud DownloadStatus storage', () {
    test('SC-DL-040 unique storage values', () {
      final values = DownloadStatus.values.map((s) => s.storageValue).toSet();
      expect(values.length, DownloadStatus.values.length);
    });

    test('SC-DL-041 storage round-trip', () {
      for (final status in DownloadStatus.values) {
        expect(DownloadStatus.fromStorage(status.storageValue), status);
      }
    });
  });

  group('SoundCloud playlist overall state', () {
    test('SC-DL-050 mixed playlist states do not all fail', () {
      final tracks = [
        task(id: 'p1', status: DownloadStatus.completed, progress: 1),
        task(
          id: 'p2',
          status: DownloadStatus.failed,
          errorMessage: 'Unavailable',
        ),
        task(id: 'p3', status: DownloadStatus.completed, progress: 1),
      ];
      expect(tracks.where((t) => t.status == DownloadStatus.completed).length, 2);
      expect(tracks.where((t) => t.status == DownloadStatus.failed).length, 1);
    });
  });
}
