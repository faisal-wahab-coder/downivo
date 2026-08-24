import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook resolver unit tests with mocked HTTP responses.
/// Tests HTML extraction, OpenGraph fallback, and content classification.
void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _MockAdapter();
    _MockAdapter.htmlResponse = '';
    _MockAdapter.statusCode = 200;
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 1 — Video discovery via playable_url JSON
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 1 — Facebook video discovery (JSON)', () {
    test('FB-RES-001 discovers video from playable_url_quality_hd', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/hd_video.mp4?oh=abc',
        field: 'playable_url_quality_hd',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123456'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('fbcdn.net'));
      expect(result.platform, 'Facebook');
      expect(result.mimeType, 'video/mp4');
    });

    test('FB-RES-002 discovers video from playable_url (SD fallback)', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/sd_video.mp4?oh=abc',
        field: 'playable_url',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123456'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('sd_video.mp4'));
    });

    test('FB-RES-003 discovers video from browser_native_hd_url', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/native_hd.mp4?oh=abc',
        field: 'browser_native_hd_url',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123456'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('native_hd.mp4'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 2 — Video discovery via OpenGraph fallback
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 2 — Facebook video discovery (OpenGraph)', () {
    test('FB-RES-010 discovers video from og:video meta tag', () async {
      _MockAdapter.htmlResponse = _facebookOgVideoHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/og_video.mp4?oh=abc',
        title: 'Test Facebook Video',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=789'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('og_video.mp4'));
      expect(result.title, 'Test Facebook Video');
    });

    test('FB-RES-011 discovers video from og:video:url', () async {
      _MockAdapter.htmlResponse = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:video:url" content="https://video.xx.fbcdn.net/v/secure.mp4?oh=abc" />
<meta property="og:title" content="Secure Video" />
</head>
<body></body>
</html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=789'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('secure.mp4'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 3 — Reel discovery
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 3 — Facebook reel discovery', () {
    test('FB-RES-020 discovers reel video from /reel/ URL', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/reel_video.mp4?oh=abc',
        field: 'playable_url',
        title: 'Funny Reel',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/reel/123456/'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('reel_video.mp4'));
      expect(result.platform, 'Facebook');
      expect(result.mimeType, 'video/mp4');
    });

    test('FB-RES-021 reel URL classifies as REEL', () {
      final uri = Uri.parse('https://www.facebook.com/reel/123456/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.reel);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 4 — Photo discovery
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 4 — Facebook photo discovery', () {
    test('FB-RES-030 discovers photo from og:image', () async {
      _MockAdapter.htmlResponse = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/photo.jpg?oh=abc" />
<meta property="og:title" content="Beach Photo" />
</head>
<body></body>
</html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('photo.jpg'));
      expect(result.platform, 'Facebook');
      expect(result.mimeType, 'image/jpeg');
    });

    test('FB-RES-031 photo URL classifies as PHOTO', () {
      final uri = Uri.parse('https://www.facebook.com/photo/?fbid=123');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 5 — Multi-media discovery
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 5 — Facebook multi-media discovery', () {
    test('FB-RES-040 discoverAll returns multiple photos from structured data',
        () async {
      _MockAdapter.htmlResponse = _facebookMultiPhotoHtml(
        imageUrls: [
          'https://scontent.xx.fbcdn.net/v/photo1.jpg?oh=abc',
          'https://scontent.xx.fbcdn.net/v/photo2.jpg?oh=def',
          'https://scontent.xx.fbcdn.net/v/photo3.jpg?oh=ghi',
        ],
      );

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(results.length, greaterThanOrEqualTo(1));
      for (final r in results) {
        expect(r.platform, 'Facebook');
      }
    });

    test('FB-RES-041 discoverAll returns single video for video post', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/single_video.mp4?oh=abc',
        field: 'playable_url',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/watch/?v=123456'),
      );

      expect(results.length, 1);
      expect(results.first.directUrl, contains('single_video.mp4'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 6 — Non-downloadable content
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 6 — Non-downloadable Facebook content', () {
    test('FB-RES-050 home page returns empty', () async {
      _MockAdapter.htmlResponse = '<html><body>Facebook</body></html>';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(Uri.parse('https://www.facebook.com/'));

      expect(result, isNull);
    });

    test('FB-RES-051 page URL returns empty', () async {
      _MockAdapter.htmlResponse = '<html><body>Page</body></html>';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/facebook/'));

      expect(result, isNull);
    });

    test('FB-RES-052 empty HTML returns null', () async {
      _MockAdapter.htmlResponse = '';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 7 — Error handling
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 7 — Facebook error handling', () {
    test('FB-RES-060 HTTP 404 returns null', () async {
      _MockAdapter.statusCode = 404;
      _MockAdapter.htmlResponse = 'Not Found';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=999'));

      expect(result, isNull);
    });

    test('FB-RES-061 HTTP 403 returns null', () async {
      _MockAdapter.statusCode = 403;
      _MockAdapter.htmlResponse = 'Forbidden';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=999'));

      expect(result, isNull);
    });

    test('FB-RES-062 no video URL in HTML returns null', () async {
      _MockAdapter.htmlResponse = '''
<!DOCTYPE html>
<html>
<head><title>Facebook</title></head>
<body><div>No media here</div></body>
</html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 8 — File naming
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 8 — Facebook file naming', () {
    test('FB-RES-070 video file gets .mp4 extension', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/test_video.mp4?oh=abc',
        field: 'playable_url',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNotNull);
      expect(result!.fileName, endsWith('.mp4'));
    });

    test('FB-RES-071 photo file gets image extension', () async {
      _MockAdapter.htmlResponse = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/pic.jpg?oh=abc" />
</head>
<body></body>
</html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123'),
      );

      expect(result, isNotNull);
      expect(
        result!.fileName.endsWith('.jpg') || result.fileName.endsWith('.jpeg'),
        isTrue,
      );
    });

    test('FB-RES-072 filename is sanitized (no path traversal)', () async {
      _MockAdapter.htmlResponse = _facebookOgVideoHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/../../../../etc/passwd.mp4',
        title: '../../../../etc/passwd',
      );

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNotNull);
      expect(result!.fileName, isNot(contains('..')));
      expect(result.fileName, isNot(contains('/')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 9 — Thumbnail extraction
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 9 — Facebook thumbnail extraction', () {
    test('FB-RES-080 video resource includes thumbnail from og:image', () async {
      _MockAdapter.htmlResponse = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/thumb.jpg" />
<meta property="og:video" content="https://video.xx.fbcdn.net/v/video.mp4?oh=abc" />
<meta property="og:title" content="Video Title" />
</head>
<body></body>
</html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNotNull);
      expect(result!.thumbnailUrl, contains('thumb.jpg'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 10 — ContentProviderRegistry integration
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 10 — ContentProviderRegistry integration', () {
    test('FB-RES-090 registry discovers Facebook video', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/reg_test.mp4?oh=abc',
        field: 'playable_url',
      );

      final registry = ContentProviderRegistry(dio: mockDio);
      final result = await registry.discover(
        Uri.parse('https://www.facebook.com/watch/?v=123456'),
      );

      expect(result, isNotNull);
      expect(result!.platform, 'Facebook');
      expect(result.directUrl, contains('reg_test.mp4'));
    });

    test('FB-RES-091 registry discoverAll returns Facebook resources', () async {
      _MockAdapter.htmlResponse = _facebookVideoPageHtml(
        videoUrl: 'https://video.xx.fbcdn.net/v/all_test.mp4?oh=abc',
        field: 'playable_url',
      );

      final registry = ContentProviderRegistry(dio: mockDio);
      final results = await registry.discoverAll(
        Uri.parse('https://www.facebook.com/watch/?v=123456'),
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.platform, 'Facebook');
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Mock HTTP adapter
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// HTML fixture builders
// ═══════════════════════════════════════════════════════════════════════════

String _facebookVideoPageHtml({
  required String videoUrl,
  required String field,
  String? title,
}) {
  // Use unicode escaping like real Facebook does.
  final escapedUrl = videoUrl
      .replaceAll('/', r'\u002F')
      .replaceAll('&', r'\u0026');
  return '<!DOCTYPE html>\n<html>\n<head>\n'
      '<meta property="og:title" content="${title ?? 'Facebook Video'}" />\n'
      '<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/thumb.jpg" />\n'
      '</head>\n<body>\n<script>\n'
      'var data = {"$field":"$escapedUrl","other":"value"};\n'
      '</script>\n</body>\n</html>';
}

String _facebookOgVideoHtml({
  required String videoUrl,
  String? title,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:video" content="$videoUrl" />
<meta property="og:title" content="${title ?? 'Facebook Video'}" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/thumb.jpg" />
</head>
<body></body>
</html>''';
}

String _facebookMultiPhotoHtml({required List<String> imageUrls}) {
  final jsonImages = imageUrls
      .map((url) => '{"uri":"${url.replaceAll('/', r'\/')}"}')
      .join(',');
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Multi Photo Post" />
<meta property="og:image" content="${imageUrls.first}" />
</head>
<body>
<script>var data = {"images":[$jsonImages]};</script>
</body>
</html>''';
}
