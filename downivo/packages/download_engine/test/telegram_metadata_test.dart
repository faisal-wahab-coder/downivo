import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram metadata mapping', () {
    test('TG-META-001 message identity and channel', () {
      final info = TelegramResolver.parseMessageInfo(
        html: telegramPhotoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
        contentId: '$telegramChannel/$telegramMessageId',
      );
      expect(info.contentId, '$telegramChannel/$telegramMessageId');
      expect(info.channel, telegramChannel);
      expect(info.messageId, telegramMessageId);
      expect(info.authorUrl, 'https://t.me/$telegramChannel');
    });

    test('TG-META-002 GIF is classified as animation, served as MP4', () {
      expect(
        TelegramResolver.detectMediaType(telegramGifHtml()),
        TelegramMediaType.gif,
      );
      final results = TelegramResolver.parseHtmlResources(
        html: telegramGifHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramGifUrl);
      expect(results.single.mimeType, 'video/mp4');
    });

    test('TG-META-003 MIME mapping', () {
      expect(TelegramResolver.mimeFromUrl(telegramVideoUrl), 'video/mp4');
      expect(TelegramResolver.mimeFromUrl(telegramPhotoUrl), 'image/jpeg');
      expect(TelegramResolver.mimeFromUrl(telegramPdfUrl), 'application/pdf');
    });

    test('TG-META-004 pageUrl is preserved on resources', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(title: 'Sunset'),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.pageUrl, telegramMessageUrl);
      expect(results.single.platform, 'Telegram');
    });

    test('TG-META-005 clock duration 1:15 is 75 seconds', () {
      final info = TelegramResolver.parseMessageInfo(
        html: telegramVideoHtml(duration: '1:15'),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(info.durationSeconds, 75);
    });
  });
}
