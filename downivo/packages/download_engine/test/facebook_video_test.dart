import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook video-specific tests: video URL extraction from various HTML patterns,
/// HD/SD fallback, CDN URL patterns, escaped URLs.
void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _MockAdapter();
    _MockAdapter.statusCode = 200;
  });

  group('Facebook video extraction patterns', () {
    test('FB-VID-001 extracts HD playable_url with unicode escaping', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:title" content="HD Test" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/thumb.jpg" />
</head><body>
<script>{"playable_url_quality_hd":"https:\\u002F\\u002Fvideo.xx.fbcdn.net\\u002Fv\\u002Fhd_test.mp4?oh=abc\\u0026oe=def"}</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('hd_test.mp4'));
      expect(result.directUrl, isNot(contains('\\u002F')));
    });

    test('FB-VID-002 prefers HD over SD when both present', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/thumb.jpg" />
</head><body>
<script>
{"playable_url_quality_hd":"https://video.xx.fbcdn.net/v/hd.mp4?oh=1","playable_url":"https://video.xx.fbcdn.net/v/sd.mp4?oh=2"}
</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('hd.mp4'));
    });

    test('FB-VID-003 falls back to SD when no HD available', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/thumb.jpg" />
</head><body>
<script>{"playable_url":"https://video.xx.fbcdn.net/v/sd_only.mp4?oh=1"}</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('sd_only.mp4'));
    });

    test('FB-VID-004 extracts from /<page>/videos/<id>/ URL', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/page_video.mp4?oh=abc" />
<meta property="og:title" content="Page Video" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/pagename/videos/123456/'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('page_video.mp4'));
    });

    test('FB-VID-005 extracts from /video.php?v= URL', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/php_video.mp4?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/video.php?v=123456'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('php_video.mp4'));
    });

    test('FB-VID-006 video resource has correct MIME type', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/typed.mp4?oh=abc" />
<meta property="og:video:type" content="video/mp4" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.mimeType, contains('video/mp4'));
    });

    test('FB-VID-007 video resource filename ends in .mp4', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/named.mp4?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.fileName, endsWith('.mp4'));
    });

    test('FB-VID-008 HTML-encoded video URL is decoded', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/encoded.mp4?oh=abc&amp;oe=def" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.directUrl, isNot(contains('&amp;')));
    });
  });

  group('Facebook video CDN URL patterns', () {
    test('FB-VID-010 video.xx.fbcdn.net is valid CDN URL', () async {
      _MockAdapter.htmlResponse = '''
<html><body>
<script>{"playable_url":"https://video.xx.fbcdn.net/v/test.mp4?oh=abc"}</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('video.xx.fbcdn.net'));
    });

    test('FB-VID-011 scontent.xx.fbcdn.net MP4 is valid CDN URL', () async {
      _MockAdapter.htmlResponse = '''
<html><body>
<script>{"browser_native_sd_url":"https://scontent.xx.fbcdn.net/v/test.mp4?oh=abc"}</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=1'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('scontent.xx.fbcdn.net'));
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: htmlResponse,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return ResponseBody.fromString(
      htmlResponse,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
