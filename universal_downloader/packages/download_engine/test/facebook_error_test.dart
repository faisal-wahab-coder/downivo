import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook error handling tests: HTTP errors, missing content, invalid HTML,
/// network failures, and graceful degradation.
void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _MockAdapter();
    _MockAdapter.statusCode = 200;
    _MockAdapter.htmlResponse = '';
    _MockAdapter.throwError = false;
  });

  group('Facebook HTTP error handling', () {
    test('FB-ERR-001 HTTP 403 returns null, no crash', () async {
      _MockAdapter.statusCode = 403;
      _MockAdapter.htmlResponse = 'Forbidden';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-002 HTTP 404 returns null, no crash', () async {
      _MockAdapter.statusCode = 404;
      _MockAdapter.htmlResponse = 'Not Found';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-003 HTTP 429 returns null, no crash', () async {
      _MockAdapter.statusCode = 429;
      _MockAdapter.htmlResponse = 'Rate Limited';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-004 HTTP 500 returns null, no crash', () async {
      _MockAdapter.statusCode = 500;
      _MockAdapter.htmlResponse = 'Server Error';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-005 HTTP 502 returns null, no crash', () async {
      _MockAdapter.statusCode = 502;
      _MockAdapter.htmlResponse = 'Bad Gateway';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-006 HTTP 503 returns null, no crash', () async {
      _MockAdapter.statusCode = 503;
      _MockAdapter.htmlResponse = 'Service Unavailable';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });
  });

  group('Facebook content error handling', () {
    test('FB-ERR-010 empty HTML returns null', () async {
      _MockAdapter.htmlResponse = '';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-011 HTML with no media returns null', () async {
      _MockAdapter.htmlResponse = '''
<html><head><title>No Media</title></head>
<body><p>Just a regular page</p></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-012 malformed HTML does not crash', () async {
      _MockAdapter.htmlResponse =
          '<html><head><meta property="og:video" content=""><<<<>>>>>'
          'not valid html at all {{{}}} "broken json": [[[';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      // Should not throw, may return null
      expect(result, isNull);
    });

    test('FB-ERR-013 login page HTML returns null', () async {
      _MockAdapter.htmlResponse =
          '<html><head><title>Log in to Facebook<\/title><\/head>'
          '<body><form action="/login.php">Login required<\/form><\/body><\/html>';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });

    test('FB-ERR-014 deleted content returns null', () async {
      _MockAdapter.htmlResponse =
          '<html><head>'
          '<meta property="og:title" content="Content Not Available" />'
          '<\/head><body>This content is no longer available.<\/body><\/html>';

      final resolver = FacebookResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.facebook.com/watch/?v=123'));

      expect(result, isNull);
    });
  });

  group('Facebook non-downloadable content', () {
    test('FB-ERR-020 home page returns empty list', () async {
      final resolver = FacebookResolver(dio: mockDio);
      final results =
          await resolver.discoverAll(Uri.parse('https://www.facebook.com/'));

      expect(results, isEmpty);
    });

    test('FB-ERR-021 page URL returns empty list', () async {
      final resolver = FacebookResolver(dio: mockDio);
      final results =
          await resolver.discoverAll(Uri.parse('https://www.facebook.com/facebook/'));

      expect(results, isEmpty);
    });
  });

  group('Facebook error formatting', () {
    test('FB-ERR-030 403 error formats correctly', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
      final message = DownloadErrorFormatter.fromDio(error);
      expect(message, contains('403'));
    });

    test('FB-ERR-031 404 error formats correctly', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      final message = DownloadErrorFormatter.fromDio(error);
      expect(message, contains('404'));
    });

    test('FB-ERR-032 429 error formats correctly', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );
      final message = DownloadErrorFormatter.fromDio(error);
      expect(message, contains('429'));
    });

    test('FB-ERR-033 connection timeout formats correctly', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      final message = DownloadErrorFormatter.fromDio(error);
      expect(message.toLowerCase(), contains('timed out'));
    });

    test('FB-ERR-034 connection error formats correctly', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
      final message = DownloadErrorFormatter.fromDio(error);
      expect(message.toLowerCase(), contains('network'));
    });
  });

  group('Facebook discoverAll error handling', () {
    test('FB-ERR-040 discoverAll with 404 returns empty', () async {
      _MockAdapter.statusCode = 404;

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/watch/?v=123'),
      );

      expect(results, isEmpty);
    });

    test('FB-ERR-041 discoverAll with empty HTML returns empty', () async {
      _MockAdapter.htmlResponse = '';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/watch/?v=123'),
      );

      expect(results, isEmpty);
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static int statusCode = 200;
  static bool throwError = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Network unreachable',
      );
    }
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
