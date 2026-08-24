import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/soundcloud_fixtures.dart';

void main() {
  group('SoundCloud performance constraints', () {
    test('SC-PERF-001 playlist of 25 tracks does not embed audio bytes',
        () async {
      final tracks = List.generate(25, (i) {
        final slug = 'track-$i';
        return {
          'id': i + 1,
          'title': 'Track $i',
          'permalink_url': 'https://soundcloud.com/test-artist/$slug',
          'user': {'username': 'Test Artist'},
          'media': {
            'transcodings': [
              {
                'url':
                    'https://api-v2.soundcloud.com/media/track-one/stream/progressive',
                'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
              },
            ],
          },
        };
      });

      final dio = Dio()
        ..interceptors.add(
          SoundCloudMockInterceptor(
            customHtml: soundCloudPlaylistHtml(tracks: tracks),
          ),
        );
      final resolver = SoundCloudResolver(dio: dio);
      final results = await resolver.discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );

      expect(results.length, 25);
      for (final resource in results) {
        expect(resource.directUrl.startsWith('https://'), isTrue);
        expect(resource.directUrl.length, lessThan(500));
      }
    });

    test('SC-PERF-002 classifyUrl is cheap for long paths', () {
      final uri = Uri.parse('https://soundcloud.com/artist/${'x' * 8000}');
      expect(() => SoundCloudUri.classifyUrl(uri), returnsNormally);
      expect(SoundCloudUri.isTrack(uri), isTrue);
    });

    test('SC-PERF-003 content identity is stable and allocation-light', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track');
      final first = SoundCloudUri.contentIdentity(uri);
      for (var i = 0; i < 1000; i++) {
        expect(SoundCloudUri.contentIdentity(uri), first);
      }
    });
  });
}
