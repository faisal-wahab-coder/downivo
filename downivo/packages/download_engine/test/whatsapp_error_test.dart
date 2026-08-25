import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = WhatsAppMockAdapter();
    WhatsAppMockAdapter.reset();
  });

  group('WhatsApp HTTP errors', () {
    test('WA-ERR-001 403 returns empty', () async {
      WhatsAppMockAdapter.htmlStatus = 403;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-002 404 returns empty', () async {
      WhatsAppMockAdapter.htmlStatus = 404;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-003 429 returns empty', () async {
      WhatsAppMockAdapter.htmlStatus = 429;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-004 500 returns empty', () async {
      WhatsAppMockAdapter.htmlStatus = 500;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-005 502 returns empty', () async {
      WhatsAppMockAdapter.htmlStatus = 502;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-006 503 returns empty', () async {
      WhatsAppMockAdapter.htmlStatus = 503;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-007 connection error returns empty', () async {
      WhatsAppMockAdapter.throwError = true;
      WhatsAppMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });

    test('WA-ERR-008 timeout returns empty', () async {
      WhatsAppMockAdapter.throwError = true;
      WhatsAppMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await WhatsAppResolver(
        dio: mockDio,
      ).discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNull);
    });
  });

  group('WhatsApp invalid / non-media URLs', () {
    test('WA-ERR-010 invalid wa.me is empty', () async {
      final results = await WhatsAppResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(whatsappInvalidWaMeUrl));
      expect(results, isEmpty);
    });

    test('WA-ERR-011 invalid whatsapp.com path is empty', () async {
      final results = await WhatsAppResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(whatsappInvalidPathUrl));
      expect(results, isEmpty);
    });

    test('WA-ERR-012 home is empty', () async {
      final results = await WhatsAppResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(whatsappHomeUrl));
      expect(results, isEmpty);
    });

    test('WA-ERR-013 unavailable HTML is empty', () {
      expect(
        WhatsAppResolver.parseHtmlResources(
          html: whatsappUnavailableHtml(),
          pageUrl: Uri.parse(whatsappChannelUrl),
        ),
        isEmpty,
      );
    });
  });

  group('WhatsApp error formatter', () {
    test('WA-ERR-020 403 message', () {
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

    test('WA-ERR-021 404 message', () {
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

    test('WA-ERR-022 429 message', () {
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

    test('WA-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('WA-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('network'),
      );
    });

    test('WA-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });

    test('WA-ERR-026 home user message', () {
      expect(
        WhatsAppResolver.userFacingError(Uri.parse(whatsappHomeUrl)),
        contains('home'),
      );
    });

    test('WA-ERR-027 chat link user message', () {
      expect(
        WhatsAppResolver.userFacingError(Uri.parse(whatsappChatUrl)),
        contains('WhatsApp link detected'),
      );
    });

    test('WA-ERR-028 text-only channel discover fails without a download', () async {
      WhatsAppMockAdapter.htmlResponse = whatsappChannelTextHtml();
      expect(
        () => WhatsAppResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(whatsappChannelUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('does not expose'),
          ),
        ),
      );
    });

    test('WA-ERR-029 invite user message', () {
      expect(
        WhatsAppResolver.userFacingError(Uri.parse(whatsappInviteUrl)),
        contains('group invitation'),
      );
    });

    test('WA-ERR-030 web user message is authentication', () {
      expect(
        WhatsAppResolver.userFacingError(Uri.parse(whatsappWebUrl)),
        contains('authentication'),
      );
    });

    test('WA-ERR-031 invalid URL message', () {
      expect(
        WhatsAppResolver.userFacingError(Uri.parse(whatsappInvalidWaMeUrl)),
        contains('Invalid WhatsApp URL'),
      );
    });

    test('WA-ERR-032 disappeared content is unavailable', () {
      expect(
        WhatsAppResolver.classifyHtml(whatsappDisappearedHtml()),
        WhatsAppHtmlStatus.unavailable,
      );
      expect(
        WhatsAppResolver.userFacingError(
          Uri.parse(whatsappChannelUrl),
          html: whatsappDisappearedHtml(),
        ),
        contains('unavailable'),
      );
    });

    test('WA-ERR-033 login HTML is not downloaded', () async {
      WhatsAppMockAdapter.htmlResponse = whatsappAuthHtml();
      expect(
        () => WhatsAppResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(whatsappChannelUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('authentication'),
          ),
        ),
      );
    });
  });
}
