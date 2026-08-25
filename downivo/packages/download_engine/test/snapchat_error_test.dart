import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = SnapchatMockAdapter();
    SnapchatMockAdapter.reset();
  });

  group('Snapchat HTTP errors', () {
    test('SC-ERR-001 403 returns empty', () async {
      SnapchatMockAdapter.htmlStatus = 403;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-002 404 returns empty', () async {
      SnapchatMockAdapter.htmlStatus = 404;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-003 429 returns empty', () async {
      SnapchatMockAdapter.htmlStatus = 429;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-004 500 returns empty', () async {
      SnapchatMockAdapter.htmlStatus = 500;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-005 502 returns empty', () async {
      SnapchatMockAdapter.htmlStatus = 502;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-006 503 returns empty', () async {
      SnapchatMockAdapter.htmlStatus = 503;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-007 connection error returns empty', () async {
      SnapchatMockAdapter.throwError = true;
      SnapchatMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });

    test('SC-ERR-008 timeout returns empty', () async {
      SnapchatMockAdapter.throwError = true;
      SnapchatMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await SnapchatResolver(
        dio: mockDio,
      ).discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNull);
    });
  });

  group('Snapchat invalid / non-media URLs', () {
    test('SC-ERR-010 invalid path is empty', () async {
      final results = await SnapchatResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse('https://www.snapchat.com/INVALID'));
      expect(results, isEmpty);
    });

    test('SC-ERR-011 invalid profile path is empty', () async {
      final results = await SnapchatResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse('https://www.snapchat.com/p/INVALID'));
      expect(results, isEmpty);
    });

    test('SC-ERR-012 home is empty', () async {
      final results = await SnapchatResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(snapchatHomeUrl));
      expect(results, isEmpty);
    });

    test('SC-ERR-013 unavailable HTML is empty', () {
      expect(
        SnapchatResolver.parseHtmlResources(
          html: snapchatUnavailableHtml(),
          pageUrl: Uri.parse(snapchatSpotlightUrl),
        ),
        isEmpty,
      );
    });
  });

  group('Snapchat error formatter', () {
    test('SC-ERR-020 403 message', () {
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

    test('SC-ERR-021 404 message', () {
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

    test('SC-ERR-022 429 message', () {
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

    test('SC-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('SC-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('network'),
      );
    });

    test('SC-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });

    test('SC-ERR-026 home user message', () {
      expect(
        SnapchatResolver.userFacingError(Uri.parse(snapchatHomeUrl)),
        contains('home'),
      );
    });

    test('SC-ERR-027 HLS-only user message', () {
      expect(
        SnapchatResolver.userFacingError(
          Uri.parse(snapchatSpotlightUrl),
          html: snapchatHlsHtml(),
        ),
        contains('HLS-only'),
      );
    });

    test('SC-ERR-028 unavailable HTML is not downloaded', () async {
      SnapchatMockAdapter.htmlResponse = snapchatUnavailableHtml();
      expect(
        () => SnapchatResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(snapchatSpotlightUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('no longer available'),
          ),
        ),
      );
    });
  });
}
