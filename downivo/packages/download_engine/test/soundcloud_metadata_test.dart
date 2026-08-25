import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/soundcloud_fixtures.dart';

void main() {
  late Dio mockDio;
  late SoundCloudResolver resolver;

  setUp(() {
    mockDio = Dio();
    mockDio.interceptors.add(SoundCloudMockInterceptor());
    resolver = SoundCloudResolver(dio: mockDio);
  });

  group('SoundCloud metadata mapping', () {
    test('SC-META-001 title is taken from hydration, not fabricated', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result!.title, 'Test Track Title');
    });

    test('SC-META-002 platform label is SoundCloud', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result!.platform, 'SoundCloud');
    });

    test('SC-META-003 page URL is the requested track URL', () async {
      final uri = Uri.parse('https://soundcloud.com/test-artist/test-track');
      final result = await resolver.discover(uri);
      expect(result!.pageUrl, uri.toString());
    });

    test('SC-META-004 artwork is upgraded to t500x500', () async {
      expect(
        SoundCloudUri.upgradeArtworkUrl(
          'https://i1.sndcdn.com/artworks-000123-large.jpg',
        ),
        'https://i1.sndcdn.com/artworks-000123-t500x500.jpg',
      );
      expect(
        SoundCloudUri.upgradeArtworkUrl(
          'https://i1.sndcdn.com/artworks-000123-t200x200.jpg',
        ),
        'https://i1.sndcdn.com/artworks-000123-t500x500.jpg',
      );
    });

    test('SC-META-005 missing artwork returns null, no crash', () {
      expect(SoundCloudUri.upgradeArtworkUrl(null), isNull);
      expect(SoundCloudUri.upgradeArtworkUrl(''), isNull);
      expect(SoundCloudUri.upgradeArtworkUrl('null'), isNull);
      expect(SoundCloudUri.upgradeArtworkUrl('not-a-url'), isNull);
    });

    test('SC-META-006 filename includes sanitized title slug', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result!.fileName.toLowerCase(), contains('test'));
      expect(result.fileName, isNot(contains('/')));
    });

    test('SC-META-007 MIME is audio/mpeg for progressive MP3', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result!.mimeType, 'audio/mpeg');
    });

    test('SC-META-008 detectMimeType maps extensions without fabricating', () {
      expect(
        SoundCloudResolver.detectMimeType(
          'https://cdn.example/a.m4a',
          const {},
        ),
        'audio/mp4',
      );
      expect(
        SoundCloudResolver.detectMimeType(
          'https://cdn.example/a.aac',
          const {},
        ),
        'audio/aac',
      );
      expect(
        SoundCloudResolver.detectMimeType(
          'https://cdn.example/a.wav',
          const {},
        ),
        'audio/wav',
      );
      expect(
        SoundCloudResolver.detectMimeType(
          'https://cdn.example/a.flac',
          const {},
        ),
        'audio/flac',
      );
      expect(
        SoundCloudResolver.detectMimeType(
          'https://cdn.example/a.ogg',
          const {},
        ),
        'audio/ogg',
      );
      expect(
        SoundCloudResolver.detectMimeType(
          'https://cdn.example/a.mp3',
          const {},
        ),
        'audio/mpeg',
      );
    });

    test('SC-META-009 client_id is extracted from page text', () {
      expect(
        SoundCloudResolver.extractClientIdFromText(
          'var config={client_id:"$soundCloudTestClientId"};',
        ),
        soundCloudTestClientId,
      );
      expect(
        SoundCloudResolver.extractClientIdFromText(
          '{"client_id":"UMY1dzQ68n2QbCuypNe8JOivmV2FO2Ep"}',
        ),
        'UMY1dzQ68n2QbCuypNe8JOivmV2FO2Ep',
      );
      expect(SoundCloudResolver.extractClientIdFromText('<html></html>'), isNull);
    });

    test('SC-META-010 og:image artwork is upgraded in meta fallback', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/meta-only-track'),
      );
      expect(result, isNotNull);
      expect(result!.thumbnailUrl, contains('t500x500'));
    });
  });
}
