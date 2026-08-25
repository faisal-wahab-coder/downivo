import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = ThreadsMockAdapter();
    ThreadsMockAdapter.reset();
  });

  group('Threads HTTP errors', () {
    test('TH-ERR-001 403 returns empty', () async {
      ThreadsMockAdapter.htmlStatus = 403;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-002 404 returns empty', () async {
      ThreadsMockAdapter.htmlStatus = 404;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-003 429 returns empty', () async {
      ThreadsMockAdapter.htmlStatus = 429;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-004 500 returns empty', () async {
      ThreadsMockAdapter.htmlStatus = 500;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-005 502 returns empty', () async {
      ThreadsMockAdapter.htmlStatus = 502;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-006 503 returns empty', () async {
      ThreadsMockAdapter.htmlStatus = 503;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-007 connection error returns empty', () async {
      ThreadsMockAdapter.throwError = true;
      ThreadsMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });

    test('TH-ERR-008 timeout returns empty', () async {
      ThreadsMockAdapter.throwError = true;
      ThreadsMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await ThreadsResolver(
        dio: mockDio,
      ).discover(Uri.parse(threadsPostUrl));
      expect(result, isNull);
    });
  });

  group('Threads user-facing errors', () {
    test('TH-ERR-020 home error', () {
      expect(
        ThreadsResolver.userFacingError(Uri.parse(threadsHomeUrl)),
        contains('home'),
      );
    });

    test('TH-ERR-021 profile error', () {
      expect(
        ThreadsResolver.userFacingError(Uri.parse(threadsProfileUrl)),
        contains('profile'),
      );
    });

    test('TH-ERR-022 invalid path error', () {
      expect(
        ThreadsResolver.userFacingError(Uri.parse(threadsInvalidPathUrl)),
        contains('Unable to identify'),
      );
    });

    test('TH-ERR-023 text-only error', () {
      expect(
        ThreadsResolver.userFacingError(
          Uri.parse(threadsPostUrl),
          html: threadsTextHtml(),
        ),
        contains('no downloadable media'),
      );
    });

    test('TH-ERR-024 unavailable error', () {
      expect(
        ThreadsResolver.userFacingError(
          Uri.parse(threadsPostUrl),
          html: threadsUnavailableHtml(),
        ),
        contains('no longer available'),
      );
    });

    test('TH-ERR-025 restricted error', () {
      expect(
        ThreadsResolver.userFacingError(
          Uri.parse(threadsPostUrl),
          html: threadsPrivateHtml(),
        ),
        contains('restricted'),
      );
    });

    test('TH-ERR-026 authentication error', () {
      expect(
        ThreadsResolver.userFacingError(Uri.parse(threadsLoginUrl)),
        contains('authentication'),
      );
    });

    test('TH-ERR-027 HLS-only error', () {
      expect(
        ThreadsResolver.userFacingError(
          Uri.parse(threadsPostUrl),
          html: threadsHlsHtml(),
        ),
        contains('HLS-only'),
      );
    });
  });
}
