import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  DownloadTask task({
    required String id,
    required DownloadStatus status,
    double progress = 0,
    String url = 'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
    String fileName = 'twitch.mp4',
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

  group('Twitch download state machine', () {
    test('TW-DL-001 queued → preparing → downloading → verifying → completed', () {
      var t = task(id: 'tw-1', status: DownloadStatus.queued);
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

    test('TW-DL-002 downloading → paused → downloading → completed', () {
      var t = task(
        id: 'tw-2',
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

    test('TW-DL-003 downloading → cancelled', () {
      final t = task(
        id: 'tw-3',
        status: DownloadStatus.downloading,
      ).copyWith(status: DownloadStatus.cancelled);
      expect(t.status, DownloadStatus.cancelled);
    });

    test('TW-DL-004 failed → retry queued', () {
      var t = task(
        id: 'tw-4',
        status: DownloadStatus.failed,
        error: 'Network error',
      );
      t = t.copyWith(status: DownloadStatus.queued, progress: 0);
      expect(t.status, DownloadStatus.queued);
    });
  });

  group('Twitch download task properties', () {
    test('TW-DL-010 isActive for in-flight states', () {
      for (final status in [
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.verifying,
      ]) {
        expect(task(id: 'a', status: status).isActive, isTrue);
      }
    });

    test('TW-DL-011 isActive false for terminal/paused', () {
      for (final status in [
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.paused,
      ]) {
        expect(task(id: 'a', status: status).isActive, isFalse);
      }
    });

    test('TW-DL-012 bytesRemaining', () {
      final t = task(
        id: 'b',
        status: DownloadStatus.downloading,
        fileSize: 1000,
        bytesReceived: 250,
      );
      expect(t.bytesRemaining, 750);
    });
  });

  group('Twitch file naming via download resolver', () {
    test('TW-DL-020 video MIME → .mp4', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse(
            'https://production.assets.clips.twitchcdn.net/file.mp4',
          ),
          contentType: 'video/mp4',
        ),
        endsWith('.mp4'),
      );
    });

    test('TW-DL-021 quality is encoded in discovered filename', () {
      expect(
        TwitchResolver.buildFileName(
          id: 'clip1',
          title: 'Perfect dodge',
          quality: '1080p',
          mimeType: 'video/mp4',
        ),
        allOf(contains('1080p'), endsWith('.mp4')),
      );
    });
  });

  group('Twitch DownloadStatus storage', () {
    test('TW-DL-030 storage round-trip', () {
      for (final status in DownloadStatus.values) {
        expect(DownloadStatus.fromStorage(status.storageValue), status);
      }
    });
  });

  group('Twitch duplicate identity for downloads', () {
    test('TW-DL-040 canonical and share map to the same identity', () {
      expect(
        TwitchUri.contentIdentity(
          Uri.parse(
            'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        TwitchUri.contentIdentity(
          Uri.parse(
            'https://www.twitch.tv/lirik/clip/AwkwardHelplessSalamanderSwiftRage?tt_medium=share',
          ),
        ),
      );
    });
  });
}
