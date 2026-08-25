import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook Reel-specific tests: reel URL detection, reel ID extraction,
/// reel content resolution, and reel-specific edge cases.
void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _MockAdapter();
    _MockAdapter.htmlResponse = '';
    _MockAdapter.statusCode = 200;
  });

  group('Facebook reel URL detection', () {
    test('FB-REEL-001 /reel/<id>/ is classified as REEL', () {
      final uri = Uri.parse('https://www.facebook.com/reel/123456789/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.reel);
    });

    test('FB-REEL-002 /reels/<id>/ is classified as REEL', () {
      final uri = Uri.parse('https://www.facebook.com/reels/123456789/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.reel);
    });

    test('FB-REEL-003 reel ID is extracted correctly', () {
      final uri = Uri.parse('https://www.facebook.com/reel/123456789/');
      expect(FacebookUri.contentIdFromUri(uri), '123456789');
    });

    test('FB-REEL-004 reel ID from /reels/ is extracted', () {
      final uri = Uri.parse('https://www.facebook.com/reels/987654321/');
      expect(FacebookUri.contentIdFromUri(uri), '987654321');
    });

    test('FB-REEL-005 isReel returns true for /reel/<id>', () {
      expect(
        FacebookUri.isReel(Uri.parse('https://www.facebook.com/reel/123/')),
        isTrue,
      );
      expect(
        FacebookUri.isReel(Uri.parse('https://www.facebook.com/reel/123456/')),
        isTrue,
      );
    });

    test('FB-REEL-006 mobile reel URL is detected', () {
      final uri = Uri.parse('https://m.facebook.com/reel/123456789/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.reel);
      expect(FacebookUri.contentIdFromUri(uri), '123456789');
    });
  });

  group('Facebook reel resolution', () {
    test('FB-REEL-010 reel resolves to video content', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:title" content="Funny Reel" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/reel_thumb.jpg" />
<meta property="og:video" content="https://video.xx.fbcdn.net/v/reel_video.mp4?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/reel/123456/'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('reel_video.mp4'));
      expect(result.platform, 'Facebook');
      expect(result.mimeType, contains('video'));
    });

    test('FB-REEL-011 reel with playable_url JSON', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:title" content="Reel JSON" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/thumb.jpg" />
</head><body>
<script>{"playable_url":"https://video.xx.fbcdn.net/v/reel_json.mp4?oh=abc"}</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/reel/123456/'));

      expect(result, isNotNull);
      expect(result!.directUrl, contains('reel_json.mp4'));
    });

    test('FB-REEL-012 reel with tracking params still resolves', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/tracked_reel.mp4?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse(
          'https://www.facebook.com/reel/123456/?mibextid=abc&ref=share',
        ),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('tracked_reel.mp4'));
    });

    test('FB-REEL-013 reel resource includes thumbnail', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/reel_thumb.jpg" />
<meta property="og:video" content="https://video.xx.fbcdn.net/v/reel.mp4?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/reel/123456/'));

      expect(result, isNotNull);
      expect(result!.thumbnailUrl, contains('reel_thumb.jpg'));
    });
  });

  group('Facebook reel edge cases', () {
    test('FB-REEL-020 /reel/ without ID returns null for discoverAll', () async {
      final resolver = FacebookResolver(dio: mockDio);
      final uri = Uri.parse('https://www.facebook.com/reel/');
      // classifyUrl returns unknown for /reel/ without numeric ID
      // but discoverAll still tries to fetch and returns empty
      final results = await resolver.discoverAll(uri);
      // No valid content can be found
      expect(results, isEmpty);
    });

    test('FB-REEL-021 /reel/INVALID with non-numeric is unknown', () {
      final uri = Uri.parse('https://www.facebook.com/reel/INVALID/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.unknown);
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
