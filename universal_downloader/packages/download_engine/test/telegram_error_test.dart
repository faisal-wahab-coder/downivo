import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = TelegramMockAdapter();
    TelegramMockAdapter.reset();
  });

  group('Telegram HTTP errors', () {
    test('TG-ERR-001 403 returns empty', () async {
      TelegramMockAdapter.htmlStatus = 403;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-002 404 returns empty', () async {
      TelegramMockAdapter.htmlStatus = 404;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-003 429 returns empty', () async {
      TelegramMockAdapter.htmlStatus = 429;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-004 500 returns empty', () async {
      TelegramMockAdapter.htmlStatus = 500;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-005 502 returns empty', () async {
      TelegramMockAdapter.htmlStatus = 502;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-006 503 returns empty', () async {
      TelegramMockAdapter.htmlStatus = 503;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-007 connection error returns empty', () async {
      TelegramMockAdapter.throwError = true;
      TelegramMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });

    test('TG-ERR-008 timeout returns empty', () async {
      TelegramMockAdapter.throwError = true;
      TelegramMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await TelegramResolver(
        dio: mockDio,
      ).discover(Uri.parse(telegramMessageUrl));
      expect(result, isNull);
    });
  });

  group('Telegram invalid / non-media URLs', () {
    test('TG-ERR-010 invalid channel path is empty', () async {
      TelegramMockAdapter.htmlResponse = '<html>Not found</html>';
      final results = await TelegramResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse('https://t.me/INVALID_CHANNEL_123456789'));
      expect(results, isEmpty);
    });

    test('TG-ERR-011 invalid message path is empty', () async {
      final results = await TelegramResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse('https://t.me/telegram/INVALID_MESSAGE'));
      expect(results, isEmpty);
    });

    test('TG-ERR-012 home is empty', () async {
      final results = await TelegramResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(telegramHomeUrl));
      expect(results, isEmpty);
    });

    test('TG-ERR-013 unavailable HTML is empty', () {
      expect(
        TelegramResolver.parseHtmlResources(
          html: telegramUnavailableHtml(),
          pageUrl: Uri.parse(telegramMessageUrl),
        ),
        isEmpty,
      );
    });
  });

  group('Telegram error formatter', () {
    test('TG-ERR-020 403 message', () {
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

    test('TG-ERR-021 404 message', () {
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

    test('TG-ERR-022 429 message', () {
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

    test('TG-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('TG-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('network'),
      );
    });

    test('TG-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });

    test('TG-ERR-026 home user message', () {
      expect(
        TelegramResolver.userFacingError(Uri.parse(telegramHomeUrl)),
        contains('home'),
      );
    });

    test('TG-ERR-027 text-only user message', () {
      expect(
        TelegramResolver.userFacingError(
          Uri.parse(telegramMessageUrl),
          html: telegramTextHtml(),
        ),
        contains('text-only'),
      );
    });

    test('TG-ERR-028 text-only discover fails without a download', () async {
      TelegramMockAdapter.htmlResponse = telegramTextHtml();
      expect(
        () => TelegramResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(telegramMessageUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('text-only'),
          ),
        ),
      );
    });
  });
}
