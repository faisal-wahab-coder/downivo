import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram photos', () {
    test('TG-PH-001 detects PHOTO', () {
      expect(
        TelegramResolver.detectMediaType(telegramPhotoHtml()),
        TelegramMediaType.photo,
      );
    });

    test('TG-PH-002 resolves photo URL and JPEG MIME', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramPhotoUrl);
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('TG-PH-003 maps dimensions from Open Graph', () {
      final info = TelegramResolver.parseMessageInfo(
        html: telegramPhotoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(info.width, 1280);
      expect(info.height, 720);
    });

    test('TG-PH-004 thumbnail is the exposed image', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.thumbnailUrl, telegramPhotoUrl);
    });

    test('TG-PH-005 site icons are not treated as photos', () {
      final html = telegramTextHtml().replaceAll(
        '</head>',
        '<meta property="og:image" content="https://telegram.org/img/telegram_logo.png" /></head>',
      );
      final results = TelegramResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, isEmpty);
    });
  });
}
