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

  group('SoundCloud playlist URL detection', () {
    test('SC-PL-001 /sets/ slug is a playlist', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/chill');
      expect(SoundCloudUri.isPlaylist(uri), isTrue);
      expect(SoundCloudUri.playlistSlugFromUri(uri), 'chill');
      expect(SoundCloudUri.artistFromUri(uri), 'artist');
    });

    test('SC-PL-002 album uses the same /sets/ path', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/debut-album');
      expect(SoundCloudUri.isPlaylist(uri), isTrue);
    });

    test('SC-PL-003 sets listing is not a playlist', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets');
      expect(SoundCloudUri.isPlaylist(uri), isFalse);
    });

    test('SC-PL-004 playlist identity ignores tracking params', () {
      final a = Uri.parse('https://soundcloud.com/artist/sets/mix');
      final b = Uri.parse(
        'https://soundcloud.com/artist/sets/mix?utm_source=twitter&si=1',
      );
      expect(
        SoundCloudUri.contentIdentity(SoundCloudUri.normalize(a)),
        SoundCloudUri.contentIdentity(SoundCloudUri.normalize(b)),
      );
    });
  });

  group('SoundCloud playlist resolution', () {
    test('SC-PL-010 discoverAll returns all available tracks', () async {
      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );
      expect(results.length, 3);
    });

    test('SC-PL-011 ordering is preserved', () async {
      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );
      expect(results.map((r) => r.title).toList(), [
        'Track One',
        'Track Two',
        'Track Three',
      ]);
    });

    test('SC-PL-012 each track has its own page URL', () async {
      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );
      expect(results[0].pageUrl, contains('track-one'));
      expect(results[1].pageUrl, contains('track-two'));
      expect(results[2].pageUrl, contains('track-three'));
    });

    test('SC-PL-013 stub tracks are hydrated or skipped, not fatal', () async {
      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/mixed'),
      );
      expect(results.length, greaterThanOrEqualTo(3));
      expect(results.every((r) => r.directUrl.startsWith('https://')), isTrue);
    });

    test('SC-PL-014 restricted track in playlist is skipped', () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: soundCloudPlaylistHtml(
            tracks: [
              {
                'id': 1,
                'title': 'Public',
                'permalink_url': 'https://soundcloud.com/test-artist/public',
                'user': {'username': 'Test Artist'},
                'media': {
                  'transcodings': [
                    {
                      'url':
                          'https://api-v2.soundcloud.com/media/track-one/stream/progressive',
                      'format': {
                        'protocol': 'progressive',
                        'mime_type': 'audio/mpeg',
                      },
                    },
                  ],
                },
              },
              {
                'id': 2,
                'title': 'Blocked',
                'policy': 'BLOCK',
                'permalink_url': 'https://soundcloud.com/test-artist/blocked',
                'user': {'username': 'Test Artist'},
                'media': {
                  'transcodings': [
                    {
                      'url':
                          'https://api-v2.soundcloud.com/media/track-two/stream/progressive',
                      'format': {
                        'protocol': 'progressive',
                        'mime_type': 'audio/mpeg',
                      },
                    },
                  ],
                },
              },
              {
                'id': 3,
                'title': 'Also Public',
                'permalink_url':
                    'https://soundcloud.com/test-artist/also-public',
                'user': {'username': 'Test Artist'},
                'media': {
                  'transcodings': [
                    {
                      'url':
                          'https://api-v2.soundcloud.com/media/track-three/stream/progressive',
                      'format': {
                        'protocol': 'progressive',
                        'mime_type': 'audio/mpeg',
                      },
                    },
                  ],
                },
              },
            ],
          ),
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );

      expect(results.length, 2);
      expect(results.map((r) => r.title), ['Public', 'Also Public']);
    });

    test('SC-PL-015 discover() does not treat playlist as a single track',
        () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );
      expect(result, isNull);
    });

    test('SC-PL-016 profile URL discoverAll is empty', () async {
      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist'),
      );
      expect(results, isEmpty);
    });

    test('SC-PL-017 playlist without hydration still resolves via API', () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: '''
<html><body>
<script>window.SC={client_id:"$soundCloudTestClientId"};</script>
</body></html>
''',
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/api-playlist'),
      );
      expect(results.length, 2);
      expect(results[0].title, 'Track One');
      expect(results[1].title, 'Track Two');
    });

    test('SC-PL-018 cover image is not treated as the playlist download', () {
      const html = '''
<html>
<head>
<meta property="og:title" content="HARD Summer 2025">
<meta property="og:image" content="https://i1.sndcdn.com/artworks-playlist-t1080x1080.jpg">
<meta property="og:type" content="music.playlist">
</head>
<body></body>
</html>
''';
      final extracted = MediaExtractor.extract(
        pageUrl: Uri.parse(
          'https://soundcloud.com/soundcloud-the-peak/sets/hard-summer-2025',
        ),
        html: html,
        platform: SocialPlatform.soundcloud,
      );
      expect(extracted, isNull);
    });

    test('SC-PL-019 registry does not queue playlist artwork as audio', () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: '''
<html>
<head>
<meta property="og:title" content="HARD Summer 2025">
<meta property="og:image" content="https://i1.sndcdn.com/artworks-playlist.jpg">
</head>
<body></body>
</html>
''',
        ));
      final registry = ContentProviderRegistry(dio: mockDio);
      final results = await registry.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/cover-only'),
      );
      expect(results, isEmpty);
    });
  });
}
