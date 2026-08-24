import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pinterest_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = PinterestMockAdapter();
    PinterestMockAdapter.reset();
  });

  group('Pinterest HTTP errors', () {
    test('PT-ERR-001 HTTP 403 returns null', () async {
      PinterestMockAdapter.htmlStatus = 403;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-002 HTTP 404 returns null', () async {
      PinterestMockAdapter.htmlStatus = 404;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-003 HTTP 429 returns null', () async {
      PinterestMockAdapter.htmlStatus = 429;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-004 HTTP 500 returns null', () async {
      PinterestMockAdapter.htmlStatus = 500;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-005 HTTP 502 returns null', () async {
      PinterestMockAdapter.htmlStatus = 502;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-006 HTTP 503 returns null', () async {
      PinterestMockAdapter.htmlStatus = 503;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-007 network error returns null', () async {
      PinterestMockAdapter.throwError = true;
      PinterestMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-ERR-008 timeout returns null', () async {
      PinterestMockAdapter.throwError = true;
      PinterestMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });
  });

  group('Pinterest invalid / non-media URLs', () {
    test('PT-ERR-010 invalid pin discoverAll is empty', () async {
      PinterestMockAdapter.htmlResponse = '<html>Not found</html>';
      final results = await PinterestResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/pin/INVALID/'),
      );
      expect(results, isEmpty);
    });

    test('PT-ERR-011 /pin/ without id is empty', () async {
      final results = await PinterestResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/pin/'),
      );
      expect(results, isEmpty);
    });

    test('PT-ERR-012 home discoverAll is empty', () async {
      final results = await PinterestResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/'),
      );
      expect(results, isEmpty);
    });

    test('PT-ERR-013 board discoverAll is empty', () async {
      final results = await PinterestResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/user/board/'),
      );
      expect(results, isEmpty);
    });
  });

  group('Pinterest error formatter', () {
    test('PT-ERR-020 403 message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('403'));
    });

    test('PT-ERR-021 404 message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('404'));
    });

    test('PT-ERR-022 429 message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('429'));
    });

    test('PT-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(DownloadErrorFormatter.fromDio(error).toLowerCase(), contains('timed out'));
    });

    test('PT-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(DownloadErrorFormatter.fromDio(error).toLowerCase(), contains('network'));
    });

    test('PT-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });
  });
}
