import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook photo-specific tests: photo URL detection, image extraction,
/// MIME handling, and photo-specific edge cases.
void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _MockAdapter();
    _MockAdapter.htmlResponse = '';
    _MockAdapter.statusCode = 200;
  });

  group('Facebook photo URL detection', () {
    test('FB-PHOTO-001 /photo/?fbid= is classified as PHOTO', () {
      final uri =
          Uri.parse('https://www.facebook.com/photo/?fbid=123456');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });

    test('FB-PHOTO-002 /photo.php?fbid= is classified as PHOTO', () {
      final uri =
          Uri.parse('https://www.facebook.com/photo.php?fbid=123456');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });

    test('FB-PHOTO-003 /<page>/photos/<album>/<id>/ is classified as PHOTO', () {
      final uri = Uri.parse(
        'https://www.facebook.com/page/photos/a.123/456/',
      );
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });

    test('FB-PHOTO-004 photo ID is extracted from fbid=', () {
      final uri =
          Uri.parse('https://www.facebook.com/photo/?fbid=987654321');
      expect(FacebookUri.contentIdFromUri(uri), '987654321');
    });

    test('FB-PHOTO-005 isPhoto returns true for /photo/', () {
      expect(
        FacebookUri.isPhoto(
          Uri.parse('https://www.facebook.com/photo/?fbid=123'),
        ),
        isTrue,
      );
    });

    test('FB-PHOTO-006 isPhoto returns true for /photos/', () {
      expect(
        FacebookUri.isPhoto(
          Uri.parse('https://www.facebook.com/page/photos/a.1/2/'),
        ),
        isTrue,
      );
    });
  });

  group('Facebook photo extraction', () {
    test('FB-PHOTO-010 extracts photo from og:image', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/photo_full.jpg?oh=abc" />
<meta property="og:title" content="Beach Photo" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('photo_full.jpg'));
      expect(result.platform, 'Facebook');
      expect(result.mimeType, 'image/jpeg');
    });

    test('FB-PHOTO-011 photo resource has correct MIME type', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/pic.jpg?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.mimeType, 'image/jpeg');
    });

    test('FB-PHOTO-012 photo filename has image extension', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/pic.jpg?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(
        result!.fileName.endsWith('.jpg') || result.fileName.endsWith('.jpeg'),
        isTrue,
      );
    });

    test('FB-PHOTO-013 photo resource includes thumbnail', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/beautiful.jpg?oh=abc" />
<meta property="og:title" content="Beautiful Photo" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.thumbnailUrl, contains('beautiful.jpg'));
    });

    test('FB-PHOTO-014 PNG photo is handled', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/infographic.png?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('.png'));
    });

    test('FB-PHOTO-015 WebP photo is handled', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/modern.webp?oh=abc" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('.webp'));
    });
  });

  group('Facebook photo edge cases', () {
    test('FB-PHOTO-020 photo page with no image returns null', () async {
      _MockAdapter.htmlResponse = '''
<html><head><title>No Image</title></head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNull);
    });

    test('FB-PHOTO-021 photo URL prefers the image over a preview video', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/mixed.mp4?oh=abc" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/thumb.jpg?oh=def" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('thumb.jpg'));
      expect(result.mimeType, 'image/jpeg');
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
