import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/soundcloud_fixtures.dart';

/// SoundCloud resolver tests using mock HTML/API responses.
/// No live network calls.
void main() {
  late Dio mockDio;
  late SoundCloudResolver resolver;

  setUp(() {
    mockDio = Dio();
    mockDio.interceptors.add(SoundCloudMockInterceptor());
    resolver = SoundCloudResolver(dio: mockDio);
  });

  group('Phase 1 — Track resolution from hydration', () {
    test('SC-RES-001 resolves track from __sc_hydration', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.platform, 'SoundCloud');
      expect(result.title, 'Test Track Title');
      expect(result.directUrl, soundCloudCdnTrack);
      expect(result.mimeType, 'audio/mpeg');
      expect(result.thumbnailUrl, isNotNull);
      expect(result.pageUrl, uri.toString());
    });

    test('SC-RES-002 filename is sanitized', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.fileName, isNotEmpty);
      expect(result.fileName.contains('/'), isFalse);
      expect(result.fileName.contains('\\'), isFalse);
    });

    test('SC-RES-003 artwork URL uses high-res version', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.thumbnailUrl, contains('t500x500'));
    });

    test('SC-RES-004 transcoding API is resolved to CDN audio', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.directUrl, isNot(contains('api-v2.soundcloud.com')));
      expect(result.directUrl, endsWith('.mp3'));
    });

    test('SC-RES-005 download headers include SoundCloud referer', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.requestHeaders, isNotNull);
      expect(result.requestHeaders!['Referer'], contains('soundcloud.com'));
    });
  });

  group('Phase 2 — Non-track URL handling', () {
    test('SC-RES-010 profile URL returns null', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });

    test('SC-RES-011 home page returns null', () async {
      final uri = Uri.parse('https://soundcloud.com/');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });

    test('SC-RES-012 playlist URL returns null from discover()', () async {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/playlist');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });

    test('SC-RES-013 system page returns null', () async {
      final uri = Uri.parse('https://soundcloud.com/discover');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });
  });

  group('Phase 3 — Playlist resolution', () {
    test('SC-RES-020 discoverAll resolves playlist tracks', () async {
      final uri =
          Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist');
      final results = await resolver.discoverAll(uri);

      expect(results, isNotEmpty);
      expect(results.length, 3);
      for (final r in results) {
        expect(r.platform, 'SoundCloud');
        expect(r.directUrl, startsWith('https://cf-media.sndcdn.com/'));
        expect(r.title, isNotNull);
      }
    });

    test('SC-RES-021 playlist tracks are ordered', () async {
      final uri =
          Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist');
      final results = await resolver.discoverAll(uri);

      expect(results[0].title, 'Track One');
      expect(results[1].title, 'Track Two');
      expect(results[2].title, 'Track Three');
    });

    test('SC-RES-022 single track URL via discoverAll returns one item',
        () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final results = await resolver.discoverAll(uri);

      expect(results.length, 1);
      expect(results[0].title, 'Test Track Title');
    });
  });

  group('Phase 4 — Fallback to OpenGraph meta', () {
    test('SC-RES-030 falls back to og:audio when no hydration', () async {
      final uri =
          Uri.parse('https://soundcloud.com/test-artist/meta-only-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.directUrl, soundCloudCdnFallback);
      expect(result.mimeType, 'audio/mpeg');
    });
  });

  group('Phase 5 — Error handling', () {
    test('SC-RES-040 404 page returns null gracefully', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/not-found');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });

    test('SC-RES-041 empty HTML returns null', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/empty-page');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });

    test('SC-RES-042 malformed hydration returns null gracefully', () async {
      final uri =
          Uri.parse('https://soundcloud.com/test-artist/malformed-hydration');
      final result = await resolver.discover(uri);
      expect(result, isNull);
    });
  });

  group('Phase 6 — Audio format detection', () {
    test('SC-RES-050 prefers progressive MP3 CDN URL', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.mimeType, 'audio/mpeg');
      expect(result.directUrl, soundCloudCdnTrack);
    });

    test('SC-RES-051 file extension matches audio format', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(
        result!.fileName.endsWith('.mp3') ||
            result.fileName.endsWith('.m4a') ||
            result.fileName.endsWith('.ogg'),
        isTrue,
      );
    });
  });

  group('Phase 7 — Registry integration', () {
    test('SC-RES-060 registry discover uses SoundCloud resolver', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      final result = await registry.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'SoundCloud');
      expect(result.directUrl, soundCloudCdnTrack);
    });

    test('SC-RES-070 resolves via public API when hydration is missing', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/api-only-track');
      final result = await resolver.discover(uri);

      expect(result, isNotNull);
      expect(result!.title, 'API Only Track');
      expect(result.directUrl, soundCloudCdnTrack);
      expect(result.mimeType, 'audio/mpeg');
    });

    test('SC-RES-071 registry discover uses API fallback', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      final result = await registry.discover(
        Uri.parse('https://soundcloud.com/test-artist/api-only-track'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, soundCloudCdnTrack);
    });
  });
}
