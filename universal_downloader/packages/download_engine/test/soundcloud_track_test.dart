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

  group('SoundCloud track detection', () {
    test('SC-TRK-001 standard artist/track URL is a track', () {
      final uri = Uri.parse('https://soundcloud.com/flume/never-be-like-you');
      expect(SoundCloudUri.isTrack(uri), isTrue);
      expect(SoundCloudUri.artistFromUri(uri), 'flume');
      expect(SoundCloudUri.trackSlugFromUri(uri), 'never-be-like-you');
    });

    test('SC-TRK-002 trailing slash is still a track', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track/');
      expect(SoundCloudUri.isTrack(uri), isTrue);
    });

    test('SC-TRK-003 query params do not change track classification', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track?utm_source=share&si=abc',
      );
      expect(SoundCloudUri.isTrack(uri), isTrue);
      expect(
        SoundCloudUri.contentIdentity(SoundCloudUri.normalize(uri)),
        'soundcloud:track:artist/track',
      );
    });

    test('SC-TRK-004 mobile host is still a track', () {
      final uri = Uri.parse('https://m.soundcloud.com/artist/track');
      expect(SoundCloudUri.isTrack(uri), isTrue);
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
    });
  });

  group('SoundCloud track resolution', () {
    test('SC-TRK-010 public track resolves audio + metadata', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );

      expect(result, isNotNull);
      expect(result!.title, 'Test Track Title');
      expect(result.directUrl, soundCloudCdnTrack);
      expect(result.mimeType, 'audio/mpeg');
      expect(result.thumbnailUrl, contains('t500x500'));
      expect(result.fileName, endsWith('.mp3'));
    });

    test('SC-TRK-011 two different tracks have different identities', () {
      final a = Uri.parse('https://soundcloud.com/artist/track-one');
      final b = Uri.parse('https://soundcloud.com/artist/track-two');
      expect(
        SoundCloudUri.contentIdentity(a),
        isNot(SoundCloudUri.contentIdentity(b)),
      );
    });

    test('SC-TRK-012 track without custom artwork uses avatar fallback',
        () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/no-artwork'),
      );

      expect(result, isNotNull);
      expect(result!.thumbnailUrl, isNotNull);
      expect(result.thumbnailUrl, contains('avatars'));
    });

    test('SC-TRK-013 official downloadable track prefers download_url',
        () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: soundCloudTrackHtml(
            trackOverrides: {
              'downloadable': true,
              'download_url':
                  'https://api-v2.soundcloud.com/media/official/stream/progressive',
            },
          ),
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, soundCloudCdnOfficial);
    });

    test('SC-TRK-014 SNIP policy track is not downloadable', () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: soundCloudTrackHtml(
            trackOverrides: {'policy': 'SNIP'},
          ),
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-TRK-015 private sharing track is not downloadable', () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: soundCloudTrackHtml(
            trackOverrides: {'sharing': 'private'},
          ),
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });
  });
}
