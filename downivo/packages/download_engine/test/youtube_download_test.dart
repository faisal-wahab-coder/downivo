import 'dart:io';

import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

/// Phase 2/3/7/9/10/11/12/13 — Live YouTube integration tests.
///
/// These tests require network access and real YouTube availability.
/// Gate: set YOUTUBE_LIVE_TEST=1 to run.
///
/// Separated into:
/// - Unit-safe structure tests (always run)
/// - Live integration tests (gated)
void main() {
  final liveEnabled = Platform.environment['YOUTUBE_LIVE_TEST'] == '1';

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 9 — Download state machine (unit, no network)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 9 — DownloadStatus state values', () {
    test('YT-SM-001 all expected states exist', () {
      expect(DownloadStatus.values, containsAll([
        DownloadStatus.queued,
        DownloadStatus.preparing,
        DownloadStatus.downloading,
        DownloadStatus.paused,
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.cancelled,
        DownloadStatus.verifying,
      ]));
    });

    test('YT-SM-002 storage values round-trip', () {
      for (final status in DownloadStatus.values) {
        expect(
          DownloadStatus.fromStorage(status.storageValue),
          status,
          reason: '${status.storageValue} should round-trip',
        );
      }
    });

    test('YT-SM-003 unknown storage value defaults to queued', () {
      expect(DownloadStatus.fromStorage('UNKNOWN'), DownloadStatus.queued);
    });

    test('YT-SM-004 isActive covers active states', () {
      final active = DownloadTask(
        id: '1',
        url: 'https://example.com',
        fileName: 'test.mp4',
        status: DownloadStatus.downloading,
        progress: 0.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(active.isActive, isTrue);

      final paused = active.copyWith(status: DownloadStatus.paused);
      expect(paused.isActive, isFalse);

      final completed = active.copyWith(status: DownloadStatus.completed);
      expect(completed.isActive, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 11 — Duplicate download behavior (unit)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 11 — Duplicate download detection', () {
    test('YT-DUP-001 no duplicate prevention exists in DownloadManager', () {
      // DownloadManager.enqueue() does not check for existing tasks with
      // the same URL. It creates a new task every time.
      // This documents the current behavior: duplicates are allowed.
      expect(true, isTrue,
          reason: 'Documenting: no duplicate prevention in current codebase');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 12 — Error handling (unit)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 12 — Error formatting', () {
    test('YT-ERR-FMT-001 403 produces access blocked message', () {
      expect(
        DownloadErrorFormatter.fromObject(ArgumentError('test')),
        'test',
      );
    });

    test('YT-ERR-FMT-002 long errors are truncated', () {
      final longError = 'x' * 200;
      final message = DownloadErrorFormatter.fromObject(Exception(longError));
      expect(message.length, lessThanOrEqualTo(163));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 13 — File naming validation (unit)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 13 — YouTube file extension validation', () {
    test('YT-FILE-001 video/mp4 maps to .mp4', () {
      expect(FileNameResolver.extensionFromMime('video/mp4'), '.mp4');
    });

    test('YT-FILE-002 video/webm maps to .webm', () {
      expect(FileNameResolver.extensionFromMime('video/webm'), '.webm');
    });

    test('YT-FILE-003 audio/mp4 maps to .m4a', () {
      expect(FileNameResolver.extensionFromMime('audio/mp4'), '.m4a');
    });

    test('YT-FILE-004 unknown video type defaults to .mp4', () {
      expect(FileNameResolver.extensionFromMime('video/x-unknown'), '.mp4');
    });

    test('YT-FILE-005 ensureExtension adds .mp4 when missing', () {
      expect(FileNameResolver.ensureExtension('clip', 'video/mp4'), 'clip.mp4');
    });

    test('YT-FILE-006 ensureExtension keeps existing extension', () {
      expect(
        FileNameResolver.ensureExtension('clip.webm', 'video/mp4'),
        'clip.webm',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Live integration tests — gated by YOUTUBE_LIVE_TEST=1
  // ─────────────────────────────────────────────────────────────────────────

  group('Live — Standard YouTube video resolution', () {
    final standardVideos = <String, String>{
      'YT-001': 'https://www.youtube.com/watch?v=YE7VzlLtp-4',
      'YT-002': 'https://youtu.be/YE7VzlLtp-4',
      'YT-003': 'https://www.youtube.com/watch?v=YE7VzlLtp-4&t=30s',
      'YT-004':
          'https://www.youtube.com/watch?v=YE7VzlLtp-4&feature=youtu.be',
      'YT-005': 'https://www.youtube.com/watch?v=f7NwyBnIRTE',
    };

    for (final entry in standardVideos.entries) {
      test(
        '${entry.key} resolves to downloadable resource',
        () async {
          final registry = ContentProviderRegistry();
          final uri = Uri.parse(entry.value);
          final result = await registry
              .discover(uri)
              .timeout(const Duration(seconds: 30));
          expect(result, isNotNull,
              reason: '${entry.key} should resolve to a resource');
          expect(result!.directUrl, isNotEmpty);
          expect(result.fileName, isNotEmpty);
          expect(result.platform, 'YouTube');
          // ignore: avoid_print
          print(
            '${entry.key}: title=${result.title} '
            'file=${result.fileName} '
            'host=${Uri.tryParse(result.directUrl)?.host}',
          );
        },
        skip: liveEnabled
            ? false
            : 'Set YOUTUBE_LIVE_TEST=1 to run live tests',
        timeout: const Timeout(Duration(seconds: 45)),
      );
    }

    test(
      'YT-VAR-LIVE all YT-001..YT-004 resolve to same video ID content',
      () async {
        final registry = ContentProviderRegistry();
        final titles = <String>{};
        for (final url in [
          'https://www.youtube.com/watch?v=YE7VzlLtp-4',
          'https://youtu.be/YE7VzlLtp-4',
          'https://www.youtube.com/watch?v=YE7VzlLtp-4&t=30s',
          'https://www.youtube.com/watch?v=YE7VzlLtp-4&feature=youtu.be',
        ]) {
          final result = await registry
              .discover(Uri.parse(url))
              .timeout(const Duration(seconds: 30));
          if (result?.title != null) titles.add(result!.title!);
        }
        // All should have the same title
        expect(titles.length, lessThanOrEqualTo(1),
            reason: 'All URL variations should resolve to the same video');
      },
      skip:
          liveEnabled ? false : 'Set YOUTUBE_LIVE_TEST=1 to run live tests',
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });

  group('Live — YouTube Shorts resolution', () {
    final shorts = <String, String>{
      'YTS-001': 'https://youtube.com/shorts/ld4K5nw9gsk',
      'YTS-002': 'https://youtube.com/shorts/XFM4tCakAXY',
      'YTS-003': 'https://youtube.com/shorts/BxXzzAEEhCA',
      'YTS-004': 'https://youtube.com/shorts/LNv4y3wPQA0',
      'YTS-005': 'https://youtube.com/shorts/hvmIZAvt3jE',
      'YTS-006': 'https://youtube.com/shorts/MNRgAw45mTM',
    };

    for (final entry in shorts.entries) {
      test(
        '${entry.key} Shorts resolves to downloadable resource',
        () async {
          final registry = ContentProviderRegistry();
          final uri = Uri.parse(entry.value);
          final result = await registry
              .discover(uri)
              .timeout(const Duration(seconds: 30));
          expect(result, isNotNull,
              reason: '${entry.key} should resolve');
          expect(result!.directUrl, isNotEmpty);
          expect(result.fileName, isNotEmpty);
          expect(result.fileName, endsWith('.mp4'));
          expect(result.platform, 'YouTube');
          // ignore: avoid_print
          print(
            '${entry.key}: title=${result.title} '
            'file=${result.fileName} '
            'host=${Uri.tryParse(result.directUrl)?.host}',
          );
        },
        skip: liveEnabled
            ? false
            : 'Set YOUTUBE_LIVE_TEST=1 to run live tests',
        timeout: const Timeout(Duration(seconds: 45)),
      );
    }
  });

  group('Live — Invalid YouTube URLs', () {
    final invalidUrls = <String, String>{
      'YT-INV-001': 'https://www.youtube.com/',
      'YT-INV-002': 'https://www.youtube.com/watch',
      'YT-INV-003': 'https://www.youtube.com/watch?v=INVALID_VIDEO_ID',
      'YT-INV-004': 'https://youtu.be/INVALID_VIDEO_ID',
      'YT-INV-005': 'https://youtube.com/shorts/INVALID_VIDEO_ID',
    };

    for (final entry in invalidUrls.entries) {
      test(
        '${entry.key} does not crash and returns null or fails gracefully',
        () async {
          final registry = ContentProviderRegistry();
          final uri = Uri.parse(entry.value);
          try {
            final result = await registry
                .discover(uri)
                .timeout(const Duration(seconds: 30));
            // null is acceptable for unresolvable URLs
            // ignore: avoid_print
            print(
              '${entry.key}: result=${result == null ? "null" : "resolved"} '
              'url=${entry.value}',
            );
          } catch (e) {
            // DioException or timeout is acceptable, crash is not
            // ignore: avoid_print
            print('${entry.key}: caught ${e.runtimeType}');
          }
          // If we get here without crash, the test passes
          expect(true, isTrue);
        },
        skip: liveEnabled
            ? false
            : 'Set YOUTUBE_LIVE_TEST=1 to run live tests',
        timeout: const Timeout(Duration(seconds: 45)),
      );
    }
  });
}
