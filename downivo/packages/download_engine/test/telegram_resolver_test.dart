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

  group('Telegram resolver', () {
    test('TG-RES-001 photo HTML yields a photo resource', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
        contentId: '$telegramChannel/$telegramMessageId',
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, telegramPhotoUrl);
      expect(results.single.platform, 'Telegram');
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('TG-RES-002 discover uses public preview HTML', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final result = await TelegramResolver(dio: mockDio).discover(
        Uri.parse(telegramMessageUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, telegramPhotoUrl);
    });

    test('TG-RES-003 channel URL is not discovered', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final results = await TelegramResolver(dio: mockDio).discoverAll(
        Uri.parse(telegramChannelUrl),
      );
      expect(results, isEmpty);
    });

    test('TG-RES-004 private /c/ URL is not fetched', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final results = await TelegramResolver(dio: mockDio).discoverAll(
        Uri.parse('https://t.me/c/1234567890/12'),
      );
      expect(results, isEmpty);
    });

    test('TG-RES-005 registry skips non-downloadable Telegram pages', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      expect(
        await registry.discover(Uri.parse(telegramHomeUrl)),
        isNull,
      );
      expect(
        await registry.discover(Uri.parse(telegramChannelUrl)),
        isNull,
      );
    });

    test('TG-RES-006 registry discovers a public message', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final result = await registry.discover(Uri.parse(telegramMessageUrl));
      expect(result, isNotNull);
      expect(result!.platform, 'Telegram');
    });

    test('TG-RES-007 filename is sanitized from title', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(title: 'Hello World'),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.fileName, isNot(contains('/')));
      expect(results.single.fileName.toLowerCase(), contains('.jpg'));
    });

    test('TG-RES-008 direct CDN URL is downloadable', () async {
      final results = await TelegramResolver(dio: mockDio).discoverAll(
        Uri.parse(telegramPhotoUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, telegramPhotoUrl);
    });

    test('TG-RES-009 text-only HTML yields no media', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramTextHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, isEmpty);
      expect(
        TelegramResolver.detectMediaType(telegramTextHtml()),
        TelegramMediaType.textMessage,
      );
    });

    test('TG-RES-010 private HTML is not parsed as media', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPrivateHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, isEmpty);
      expect(
        TelegramResolver.classifyHtml(telegramPrivateHtml()),
        TelegramHtmlStatus.restricted,
      );
    });
  });
}
