import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = LinkedInMockAdapter();
    LinkedInMockAdapter.reset();
  });

  group('LinkedIn HTTP errors', () {
    test('LI-ERR-001 HTTP 403 returns null', () async {
      LinkedInMockAdapter.htmlStatus = 403;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-002 HTTP 404 returns null', () async {
      LinkedInMockAdapter.htmlStatus = 404;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-003 HTTP 429 returns null', () async {
      LinkedInMockAdapter.htmlStatus = 429;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-004 HTTP 500 returns null', () async {
      LinkedInMockAdapter.htmlStatus = 500;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-005 HTTP 502 returns null', () async {
      LinkedInMockAdapter.htmlStatus = 502;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-006 HTTP 503 returns null', () async {
      LinkedInMockAdapter.htmlStatus = 503;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-007 network error returns null', () async {
      LinkedInMockAdapter.throwError = true;
      LinkedInMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-ERR-008 timeout returns null', () async {
      LinkedInMockAdapter.throwError = true;
      LinkedInMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });
  });

  group('LinkedIn invalid / non-media URLs', () {
    test('LI-ERR-010 invalid post discoverAll is empty', () async {
      LinkedInMockAdapter.htmlResponse = '<html>Not found</html>';
      final results = await LinkedInResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.linkedin.com/posts/INVALID/'),
      );
      expect(results, isEmpty);
    });

    test('LI-ERR-011 /posts/ without id is empty', () async {
      final results = await LinkedInResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.linkedin.com/posts/'),
      );
      expect(results, isEmpty);
    });

    test('LI-ERR-012 home discoverAll is empty', () async {
      final results = await LinkedInResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.linkedin.com/'),
      );
      expect(results, isEmpty);
    });

    test('LI-ERR-013 profile discoverAll is empty', () async {
      final results = await LinkedInResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.linkedin.com/in/INVALID/'),
      );
      expect(results, isEmpty);
    });

    test('LI-ERR-014 company discoverAll is empty', () async {
      final results = await LinkedInResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.linkedin.com/company/INVALID/'),
      );
      expect(results, isEmpty);
    });

    test('LI-ERR-015 HLS-only video discoverAll is empty', () async {
      LinkedInMockAdapter.htmlResponse = linkedinHlsOnlyVideoHtml();
      final results = await LinkedInResolver(dio: mockDio).discoverAll(
        Uri.parse(linkedinPostUrl),
      );
      expect(results, isEmpty);
    });
  });

  group('LinkedIn error formatter', () {
    test('LI-ERR-020 403 message', () {
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

    test('LI-ERR-021 404 message', () {
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

    test('LI-ERR-022 429 message', () {
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

    test('LI-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(DownloadErrorFormatter.fromDio(error).toLowerCase(), contains('timed out'));
    });

    test('LI-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(DownloadErrorFormatter.fromDio(error).toLowerCase(), contains('network'));
    });

    test('LI-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });
  });
}
