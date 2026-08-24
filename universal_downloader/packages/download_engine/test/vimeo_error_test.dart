import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = VimeoMockAdapter();
    VimeoMockAdapter.reset();
  });

  group('Vimeo HTTP errors', () {
    test('VM-ERR-001 HTTP 403 returns null', () async {
      VimeoMockAdapter.statusCode = 403;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-002 HTTP 404 returns null', () async {
      VimeoMockAdapter.statusCode = 404;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-003 HTTP 429 returns null', () async {
      VimeoMockAdapter.statusCode = 429;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-004 HTTP 500 returns null', () async {
      VimeoMockAdapter.statusCode = 500;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-005 HTTP 502 returns null', () async {
      VimeoMockAdapter.statusCode = 502;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-006 HTTP 503 returns null', () async {
      VimeoMockAdapter.statusCode = 503;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-007 network error returns null', () async {
      VimeoMockAdapter.throwError = true;
      VimeoMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-ERR-008 timeout returns null', () async {
      VimeoMockAdapter.throwError = true;
      VimeoMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });
  });

  group('Vimeo availability errors', () {
    test('VM-ERR-010 password-protected video is not downloaded', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPasswordConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
      expect(
        VimeoResolver.restrictionFromConfig(vimeoPasswordConfig()),
        VimeoRestriction.password,
      );
    });

    test('VM-ERR-011 private video is not downloaded', () {
      expect(
        VimeoResolver.restrictionFromConfig(vimeoPrivateConfig()),
        VimeoRestriction.private,
      );
      expect(VimeoResolver.parseVideoInfo(vimeoPrivateConfig()), isNull);
    });

    test('VM-ERR-012 unavailable video is not downloaded', () {
      expect(
        VimeoResolver.restrictionFromConfig(vimeoUnavailableConfig()),
        VimeoRestriction.unavailable,
      );
    });

    test('VM-ERR-013 DRM config is not downloaded', () {
      expect(
        VimeoResolver.restrictionFromConfig(vimeoDrmConfig()),
        VimeoRestriction.drm,
      );
      expect(VimeoResolver.parseVideoInfo(vimeoDrmConfig()), isNull);
    });

    test('VM-ERR-014 home discoverAll is empty', () async {
      final results = await VimeoResolver(dio: mockDio).discoverAll(
        Uri.parse('https://vimeo.com/'),
      );
      expect(results, isEmpty);
    });

    test('VM-ERR-015 INVALID discoverAll is empty', () async {
      final results = await VimeoResolver(dio: mockDio).discoverAll(
        Uri.parse('https://vimeo.com/INVALID'),
      );
      expect(results, isEmpty);
    });

    test('VM-ERR-016 ondemand discoverAll is empty', () async {
      final results = await VimeoResolver(dio: mockDio).discoverAll(
        Uri.parse('https://vimeo.com/ondemand/film'),
      );
      expect(results, isEmpty);
    });
  });

  group('Vimeo error formatter', () {
    test('VM-ERR-020 403 message', () {
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

    test('VM-ERR-021 404 message', () {
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

    test('VM-ERR-022 429 message', () {
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

    test('VM-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('VM-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('network'),
      );
    });

    test('VM-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });
  });
}
