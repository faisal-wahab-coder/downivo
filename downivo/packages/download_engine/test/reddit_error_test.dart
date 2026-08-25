import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = RedditMockAdapter();
    RedditMockAdapter.reset();
  });

  group('Reddit HTTP errors', () {
    test('RD-ERR-001 HTTP 403 returns null', () async {
      RedditMockAdapter.statusCode = 403;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-002 HTTP 404 returns null', () async {
      RedditMockAdapter.statusCode = 404;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-003 HTTP 429 returns null', () async {
      RedditMockAdapter.statusCode = 429;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-004 HTTP 500 returns null', () async {
      RedditMockAdapter.statusCode = 500;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-005 HTTP 502 returns null', () async {
      RedditMockAdapter.statusCode = 502;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-006 HTTP 503 returns null', () async {
      RedditMockAdapter.statusCode = 503;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-007 network error returns null', () async {
      RedditMockAdapter.throwError = true;
      RedditMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });

    test('RD-ERR-008 timeout returns null', () async {
      RedditMockAdapter.throwError = true;
      RedditMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await RedditResolver(dio: mockDio).discover(
        Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
      );
      expect(result, isNull);
    });
  });

  group('Reddit content errors', () {
    test('RD-ERR-020 removed post returns no media', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/gone1/x/'),
        payload: redditListing(redditRemovedPost()),
      );
      expect(result, isNull);
    });

    test('RD-ERR-021 empty JSON listing returns no media', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
        payload: [
          {
            'data': {'children': <dynamic>[]},
          },
        ],
      );
      expect(result, isNull);
    });

    test('RD-ERR-022 invalid post URL discoverAll is empty', () async {
      final results = await RedditResolver(dio: mockDio).discoverAll(
        Uri.parse('https://reddit.com/INVALID'),
      );
      expect(results, isEmpty);
    });

    test('RD-ERR-023 discoverAll 404 is empty', () async {
      RedditMockAdapter.statusCode = 404;
      final results = await RedditResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.reddit.com/r/test/comments/INVALID/x/'),
      );
      expect(results, isEmpty);
    });
  });

  group('Reddit error formatting', () {
    test('RD-ERR-030 403 message', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 403),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('403'));
    });

    test('RD-ERR-031 404 message', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('404'));
    });

    test('RD-ERR-032 429 message', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 429),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('429'));
    });

    test('RD-ERR-033 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('RD-ERR-034 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('network'),
      );
    });
  });
}
