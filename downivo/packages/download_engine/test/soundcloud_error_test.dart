import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/soundcloud_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _StatusAdapter();
    _StatusAdapter.statusCode = 200;
    _StatusAdapter.html = soundCloudTrackHtml();
    _StatusAdapter.throwError = false;
  });

  group('SoundCloud HTTP error handling', () {
    test('SC-ERR-001 HTTP 403 returns null', () async {
      _StatusAdapter.statusCode = 403;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-002 HTTP 404 returns null', () async {
      _StatusAdapter.statusCode = 404;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-003 HTTP 429 returns null', () async {
      _StatusAdapter.statusCode = 429;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-004 HTTP 500 returns null', () async {
      _StatusAdapter.statusCode = 500;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-005 HTTP 502 returns null', () async {
      _StatusAdapter.statusCode = 502;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-006 HTTP 503 returns null', () async {
      _StatusAdapter.statusCode = 503;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-007 network error returns null', () async {
      _StatusAdapter.throwError = true;
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/test-artist/test-track'),
      );
      expect(result, isNull);
    });
  });

  group('SoundCloud content errors', () {
    test('SC-ERR-010 invalid track URL discover is null', () async {
      mockDio = Dio()..interceptors.add(SoundCloudMockInterceptor());
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/INVALID/INVALID'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-011 home page is not downloadable', () async {
      mockDio = Dio()..interceptors.add(SoundCloudMockInterceptor());
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-012 profile is not downloadable', () async {
      mockDio = Dio()..interceptors.add(SoundCloudMockInterceptor());
      final result = await SoundCloudResolver(dio: mockDio).discover(
        Uri.parse('https://soundcloud.com/some-artist'),
      );
      expect(result, isNull);
    });

    test('SC-ERR-013 discoverAll on 404 playlist is empty', () async {
      _StatusAdapter.statusCode = 404;
      final results = await SoundCloudResolver(dio: mockDio).discoverAll(
        Uri.parse('https://soundcloud.com/test-artist/sets/test-playlist'),
      );
      expect(results, isEmpty);
    });
  });

  group('SoundCloud error formatting', () {
    test('SC-ERR-030 403 message is user-facing', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 403),
        type: DioExceptionType.badResponse,
      );
      final message = DownloadErrorFormatter.fromDio(error);
      expect(message, contains('403'));
      expect(message.toLowerCase(), isNot(contains('stack')));
    });

    test('SC-ERR-031 404 message is user-facing', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('404'));
    });

    test('SC-ERR-032 429 message is user-facing', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 429),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('429'));
    });

    test('SC-ERR-033 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('SC-ERR-034 network message', () {
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

class _StatusAdapter implements HttpClientAdapter {
  static String html = '';
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
          data: html,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return ResponseBody.fromString(
      html,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
