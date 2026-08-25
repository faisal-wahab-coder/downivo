import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _masterPlaylist = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=460560,CODECS="mp4a.40.2,avc1.42001e",RESOLUTION=360x640,NAME="380"
https://vod3.cf.dmcdn.net/sec2(token380)/video/fmp4/1/h264_aac_vert/2/manifest.m3u8#cell=cf3
#EXT-X-STREAM-INF:BANDWIDTH=2149280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=720x1280,NAME="720"
https://vod3.cf.dmcdn.net/sec2(token720)/video/fmp4/1/h264_aac_hd_vert/2/manifest.m3u8#cell=cf3
''';

const _mediaPlaylist = '''
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:3
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-MAP:URI="init.mp4"
#EXTINF:3.000000,
0.m4s
#EXTINF:2.000000,
1.m4s
#EXT-X-ENDLIST
''';

void main() {
  group('DailymotionUri', () {
    test('detects video and short links', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.dailymotion.com/video/x8abcd')),
        SocialPlatform.dailymotion,
      );
      expect(
        DailymotionUri.videoIdFromUri(Uri.parse('https://dai.ly/x8abcd')),
        'x8abcd',
      );
      expect(
        ContentProviderRegistry.canHandle(
          Uri.parse('https://www.dailymotion.com/video/x8abcd'),
        ),
        isTrue,
      );
    });

    test('does not treat HLS CDN playlists as page URLs', () {
      expect(
        DailymotionUri.isDownloadable(
          Uri.parse(
            'https://www.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8',
          ),
        ),
        isFalse,
      );
      expect(
        DailymotionUri.videoIdFromUri(
          Uri.parse(
            'https://cdndirector.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8',
          ),
        ),
        'xaz1ney',
      );
      expect(
        DailymotionUri.isCdnHost('vod3.cf.dmcdn.net'),
        isTrue,
      );
    });

    test('maps metadata to a resource with formats', () {
      final resource = DailymotionResolver.resourceFromMetadata(
        {
          'title': 'Demo',
          'duration': 42,
          'owner': {'screenname': 'Ada'},
          'posters': [
            {'url': 'https://s1.dmcdn.net/thumb.jpg'},
          ],
          'qualities': {
            '380': [
              {'type': 'video/mp4', 'url': 'https://cdn.example/380.mp4'},
            ],
            '720': [
              {'type': 'video/mp4', 'url': 'https://cdn.example/720.mp4'},
            ],
          },
        },
        pageUrl: Uri.parse('https://www.dailymotion.com/video/x8abcd'),
        id: 'x8abcd',
      );
      expect(resource, isNotNull);
      expect(resource!.title, 'Demo');
      expect(resource.author, 'Ada');
      expect(resource.durationSeconds, 42);
      expect(resource.formats.length, 2);
      expect(resource.directUrl, contains('720.mp4'));
    });

    test('CDN helper strips Cookie from request headers', () {
      expect(
        DailymotionCdnHttp.withoutCookie({
          'User-Agent': 'UA',
          'Cookie': 'v1st=wrong',
          'Accept-Encoding': 'gzip',
          'Referer': 'https://www.dailymotion.com/',
        }),
        {
          'User-Agent': 'UA',
          'Referer': 'https://www.dailymotion.com/',
        },
      );
    });

    test('CDN request target keeps signed query and sec2 path', () {
      expect(
        DailymotionCdnHttp.requestTarget(
          'https://cdndirector.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8'
          '?sec=abc-def_ghi&dmTs=1&dmV1st=ABCDEF',
        ),
        '/cdn/manifest/video/xaz1ney.m3u8?sec=abc-def_ghi&dmTs=1&dmV1st=ABCDEF',
      );
      expect(
        DailymotionCdnHttp.requestTarget(
          'https://vod3.cf.dmcdn.net/sec2(token720)/video/fmp4/manifest.m3u8#cell=cf3',
        ),
        '/sec2(token720)/video/fmp4/manifest.m3u8',
      );
    });

    test('stream headers omit Cookie so the CDN is not sent a mismatched v1st', () {
      final headers = DailymotionResolver.streamHeaders(
        'https://cdndirector.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8'
        '?sec=abc&dmTs=1&dmV1st=ABCDEF',
      );
      expect(headers.containsKey('Cookie'), isFalse);
      expect(headers['Referer'], 'https://www.dailymotion.com/');
      expect(headers['Origin'], 'https://www.dailymotion.com');
    });

    test('HLS-only metadata has no progressive resource without playlist fetch', () {
      final resource = DailymotionResolver.resourceFromMetadata(
        {
          'title': 'HLS clip',
          'qualities': {
            'auto': [
              {
                'type': 'application/x-mpegURL',
                'url':
                    'https://cdndirector.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8',
              },
            ],
          },
        },
        pageUrl: Uri.parse('https://www.dailymotion.com/video/xaz1ney'),
        id: 'xaz1ney',
      );
      expect(resource, isNull);
    });
  });

  group('HlsFmp4Stitcher parsing', () {
    test('parses master variants highest-first and strips fragments', () {
      final variants = HlsFmp4Stitcher.parseMaster(
        _masterPlaylist,
        playlistUrl:
            'https://cdndirector.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8',
      );
      expect(variants, hasLength(2));
      expect(variants.first.label, '720p');
      expect(variants.first.height, 1280);
      expect(variants.first.width, 720);
      expect(variants.first.url, contains('token720'));
      expect(variants.first.url.contains('#'), isFalse);
    });

    test('parses init map and media segments', () {
      final urls = HlsFmp4Stitcher.parseMediaSegmentUrls(
        _mediaPlaylist,
        playlistUrl:
            'https://vod3.cf.dmcdn.net/sec2(token)/video/fmp4/1/h264_aac_hd_vert/2/manifest.m3u8',
      );
      expect(urls, hasLength(3));
      expect(urls[0], endsWith('/init.mp4'));
      expect(urls[1], endsWith('/0.m4s'));
      expect(urls[2], endsWith('/1.m4s'));
    });
  });

  group('Dailymotion HLS discovery', () {
    late Dio mockDio;

    setUp(() {
      mockDio = Dio();
      mockDio.httpClientAdapter = _DailymotionMockAdapter();
      _DailymotionMockAdapter.reset();
    });

    test('resolves HLS-only video into mp4 formats', () async {
      _DailymotionMockAdapter.metadata = {
        'title': '6 warning signs',
        'duration': 80,
        'owner': {'screenname': 'Masrawy'},
        'thumbnails': {
          '60': 'https://s2.dmcdn.net/v/thumb/x60',
          '1080': 'https://s2.dmcdn.net/v/thumb/x1080',
        },
        'qualities': {
          'auto': [
            {
              'type': 'application/x-mpegURL',
              'url':
                  'https://cdndirector.dailymotion.com/cdn/manifest/video/xaz1ney.m3u8',
            },
          ],
        },
      };
      _DailymotionMockAdapter.masterPlaylist = _masterPlaylist;

      final result = await DailymotionResolver(dio: mockDio).discover(
        Uri.parse('https://www.dailymotion.com/video/xaz1ney'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Dailymotion');
      expect(result.mimeType, 'video/mp4');
      expect(result.fileName, endsWith('.mp4'));
      expect(result.directUrl, contains('token720'));
      expect(result.formats.map((f) => f.label), ['720p', '380p']);
      expect(result.thumbnailUrl, contains('x1080'));
      expect(result.author, 'Masrawy');
    });
  });
}

class _DailymotionMockAdapter implements HttpClientAdapter {
  static Map<String, dynamic>? metadata;
  static String masterPlaylist = '';

  static void reset() {
    metadata = null;
    masterPlaylist = '';
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    if (url.contains('/player/metadata/video/')) {
      return ResponseBody.fromString(
        jsonEncode(metadata ?? {}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'set-cookie': ['v1st=abc; Path=/'],
        },
      );
    }
    if (url.contains('.m3u8')) {
      return ResponseBody.fromString(
        masterPlaylist,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/vnd.apple.mpegurl'],
        },
      );
    }
    return ResponseBody.fromString('not found', 404);
  }
}
