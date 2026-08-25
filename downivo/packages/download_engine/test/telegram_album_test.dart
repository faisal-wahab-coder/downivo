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

  group('Telegram albums / media groups', () {
    test('TG-ALB-001 detects MEDIA_GROUP', () {
      expect(
        TelegramResolver.detectMediaType(telegramAlbumHtml()),
        TelegramMediaType.mediaGroup,
      );
    });

    test('TG-ALB-002 preserves count and order', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramAlbumHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, hasLength(2));
      expect(results[0].directUrl, telegramPhotoUrl);
      expect(results[1].directUrl, telegramPhotoUrlTwo);
    });

    test('TG-ALB-003 duplicates collapse', () {
      final html = telegramAlbumHtml().replaceAll(
        telegramPhotoUrlTwo,
        telegramPhotoUrl,
      );
      final results = TelegramResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, hasLength(1));
    });

    test('TG-ALB-004 indexed filenames for album items', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramAlbumHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results[0].fileName, isNot(equals(results[1].fileName)));
    });

    test('TG-ALB-005 discoverAll returns every item', () async {
      TelegramMockAdapter.htmlResponse = telegramAlbumHtml();
      final results = await TelegramResolver(dio: mockDio).discoverAll(
        Uri.parse(telegramMessageUrl),
      );
      expect(results, hasLength(2));
      expect(results.every((r) => r.platform == 'Telegram'), isTrue);
    });
  });
}
