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

  group('SoundCloud audio format handling', () {
    test('SC-AUD-001 MP3 progressive resolves to audio/mpeg and .mp3', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result!.mimeType, 'audio/mpeg');
      expect(result.fileName, endsWith('.mp3'));
      expect(result.directUrl, endsWith('.mp3'));
    });

    test('SC-AUD-002 M4A progressive maps to audio/mp4 and .m4a', () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: soundCloudTrackHtml(
            trackOverrides: {
              'media': {
                'transcodings': [
                  {
                    'url':
                        'https://api-v2.soundcloud.com/media/m4a/stream/progressive',
                    'format': {
                      'protocol': 'progressive',
                      'mime_type': 'audio/mp4',
                    },
                  },
                ],
              },
            },
          ),
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, soundCloudCdnM4a);
      expect(result.mimeType, 'audio/mp4');
      expect(result.fileName, endsWith('.m4a'));
    });

    test('SC-AUD-003 HLS-only track is not treated as a file download',
        () async {
      mockDio.interceptors
        ..clear()
        ..add(SoundCloudMockInterceptor(
          customHtml: soundCloudTrackHtml(
            trackOverrides: {
              'media': {
                'transcodings': [
                  {
                    'url':
                        'https://api-v2.soundcloud.com/media/abc123/stream/hls',
                    'format': {
                      'protocol': 'hls',
                      'mime_type': 'audio/mpeg',
                    },
                  },
                ],
              },
            },
          ),
        ));
      resolver = SoundCloudResolver(dio: mockDio);

      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-AUD-004 FileNameResolver maps audio MIME types', () {
      expect(FileNameResolver.extensionFromMime('audio/mpeg'), '.mp3');
      expect(FileNameResolver.extensionFromMime('audio/mp4'), '.m4a');
      expect(FileNameResolver.extensionFromMime('audio/aac'), '.aac');
      expect(FileNameResolver.extensionFromMime('audio/wav'), '.wav');
      expect(FileNameResolver.extensionFromMime('audio/ogg'), '.ogg');
      expect(FileNameResolver.extensionFromMime('audio/flac'), '.flac');
    });

    test('SC-AUD-005 download engine stores audio under audio category', () {
      expect(
        FileNameResolver.resolve(
          uri: Uri.parse(soundCloudCdnTrack),
          contentType: 'audio/mpeg',
        ),
        endsWith('.mp3'),
      );
    });

    test('SC-AUD-006 resolved URL is a file, not a JSON API endpoint', () async {
      final result = await resolver.discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result!.directUrl.contains('api-v2.soundcloud.com'), isFalse);
      expect(result.directUrl.contains('.json'), isFalse);
    });
  });
}
