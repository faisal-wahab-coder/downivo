import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

/// Facebook download integration tests: state machine, file naming,
/// MIME types, and Download Engine integration.
void main() {
  group('Facebook download state machine', () {
    test('FB-DL-001 download starts in queued state', () {
      final task = DownloadTask(
        id: 'fb-test-1',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.queued,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.status, DownloadStatus.queued);
      expect(task.progress, 0);
    });

    test('FB-DL-002 download transitions to preparing', () {
      final task = DownloadTask(
        id: 'fb-test-2',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.queued,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final preparing = task.copyWith(status: DownloadStatus.preparing);
      expect(preparing.status, DownloadStatus.preparing);
    });

    test('FB-DL-003 download transitions to downloading', () {
      final task = DownloadTask(
        id: 'fb-test-3',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.preparing,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final downloading = task.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.5,
        bytesReceived: 5000000,
      );
      expect(downloading.status, DownloadStatus.downloading);
      expect(downloading.progress, 0.5);
      expect(downloading.bytesReceived, 5000000);
    });

    test('FB-DL-004 download transitions to completed', () {
      final task = DownloadTask(
        id: 'fb-test-4',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.downloading,
        progress: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completed = task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
      expect(completed.status, DownloadStatus.completed);
      expect(completed.progress, 1.0);
    });

    test('FB-DL-005 download can be paused', () {
      final task = DownloadTask(
        id: 'fb-test-5',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.downloading,
        progress: 0.3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final paused = task.copyWith(status: DownloadStatus.paused);
      expect(paused.status, DownloadStatus.paused);
      expect(paused.progress, 0.3);
    });

    test('FB-DL-006 paused download can resume', () {
      final task = DownloadTask(
        id: 'fb-test-6',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.paused,
        progress: 0.3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final resumed = task.copyWith(status: DownloadStatus.downloading);
      expect(resumed.status, DownloadStatus.downloading);
    });

    test('FB-DL-007 download can be cancelled', () {
      final task = DownloadTask(
        id: 'fb-test-7',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.downloading,
        progress: 0.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cancelled = task.copyWith(status: DownloadStatus.cancelled);
      expect(cancelled.status, DownloadStatus.cancelled);
    });

    test('FB-DL-008 download can fail with error message', () {
      final task = DownloadTask(
        id: 'fb-test-8',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.downloading,
        progress: 0.1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final failed = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: 'Network error',
      );
      expect(failed.status, DownloadStatus.failed);
      expect(failed.errorMessage, 'Network error');
    });

    test('FB-DL-009 failed download can retry', () {
      final task = DownloadTask(
        id: 'fb-test-9',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.failed,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        errorMessage: 'Previous failure',
      );

      final retried = task.copyWith(
        status: DownloadStatus.queued,
        progress: 0,
      );
      expect(retried.status, DownloadStatus.queued);
    });

    test('FB-DL-010 download verifying state exists', () {
      final task = DownloadTask(
        id: 'fb-test-10',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.verifying,
        progress: 1.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.status, DownloadStatus.verifying);
      expect(task.isActive, isTrue);
    });
  });

  group('Facebook download task properties', () {
    test('FB-DL-020 isActive returns true for active states', () {
      for (final status in [
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.verifying,
      ]) {
        final task = DownloadTask(
          id: 'fb-active',
          url: 'https://www.facebook.com/watch/?v=123',
          fileName: 'test.mp4',
          status: status,
          progress: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(task.isActive, isTrue, reason: '$status should be active');
      }
    });

    test('FB-DL-021 isActive returns false for inactive states', () {
      for (final status in [
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.paused,
      ]) {
        final task = DownloadTask(
          id: 'fb-inactive',
          url: 'https://www.facebook.com/watch/?v=123',
          fileName: 'test.mp4',
          status: status,
          progress: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(task.isActive, isFalse, reason: '$status should be inactive');
      }
    });

    test('FB-DL-022 bytesRemaining calculates correctly', () {
      final task = DownloadTask(
        id: 'fb-bytes',
        url: 'https://www.facebook.com/watch/?v=123',
        fileName: 'test.mp4',
        status: DownloadStatus.downloading,
        progress: 0.5,
        fileSize: 10000000,
        bytesReceived: 5000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.bytesRemaining, 5000000);
    });

    test('FB-DL-023 Facebook video task has correct URL', () {
      final task = DownloadTask(
        id: 'fb-url',
        url: 'https://www.facebook.com/watch/?v=123456',
        fileName: 'facebook_video.mp4',
        status: DownloadStatus.queued,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.url, contains('facebook.com'));
    });
  });

  group('Facebook file naming via download', () {
    test('FB-DL-030 video filename resolver produces .mp4', () {
      final name = FileNameResolver.resolve(
        uri: Uri.parse('https://video.xx.fbcdn.net/v/test.mp4?oh=abc'),
        contentType: 'video/mp4',
      );
      expect(name, endsWith('.mp4'));
    });

    test('FB-DL-031 image filename resolver produces .jpg', () {
      final name = FileNameResolver.resolve(
        uri: Uri.parse('https://scontent.xx.fbcdn.net/v/photo.jpg?oh=abc'),
        contentType: 'image/jpeg',
      );
      expect(name, endsWith('.jpg'));
    });

    test('FB-DL-032 no extension defaults to .bin', () {
      final name = FileNameResolver.resolve(
        uri: Uri.parse('https://video.xx.fbcdn.net/v/noext'),
      );
      expect(name, endsWith('.bin'));
    });

    test('FB-DL-033 preferred name is used when provided', () {
      final name = FileNameResolver.resolve(
        uri: Uri.parse('https://video.xx.fbcdn.net/v/cdn_name.mp4'),
        preferredName: 'my_video.mp4',
      );
      expect(name, 'my_video.mp4');
    });
  });

  group('Facebook DownloadStatus storage values', () {
    test('FB-DL-040 all statuses have unique storage values', () {
      final values = DownloadStatus.values.map((s) => s.storageValue).toSet();
      expect(values.length, DownloadStatus.values.length);
    });

    test('FB-DL-041 fromStorage round-trips correctly', () {
      for (final status in DownloadStatus.values) {
        expect(DownloadStatus.fromStorage(status.storageValue), status);
      }
    });

    test('FB-DL-042 unknown storage value defaults to queued', () {
      expect(DownloadStatus.fromStorage('UNKNOWN'), DownloadStatus.queued);
    });
  });
}
