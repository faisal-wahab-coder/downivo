import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram messages', () {
    test('TG-MSG-001 public post is MESSAGE with ids', () {
      final uri = Uri.parse(telegramMessageUrl);
      expect(TelegramUri.classifyUrl(uri), TelegramContentType.message);
      expect(TelegramUri.channelFromUri(uri), telegramChannel);
      expect(TelegramUri.messageIdFromUri(uri), telegramMessageId);
    });

    test('TG-MSG-002 text-only is TEXT_MESSAGE', () {
      expect(
        TelegramResolver.detectMediaType(telegramTextHtml()),
        TelegramMediaType.textMessage,
      );
      expect(
        TelegramResolver.parseHtmlResources(
          html: telegramTextHtml(),
          pageUrl: Uri.parse(telegramMessageUrl),
        ),
        isEmpty,
      );
    });

    test('TG-MSG-003 caption and author are mapped', () {
      final info = TelegramResolver.parseMessageInfo(
        html: telegramPhotoHtml(caption: 'Hello from channel'),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(info.caption, 'Hello from channel');
      expect(info.author, 'Telegram');
      expect(info.channel, telegramChannel);
      expect(info.messageId, telegramMessageId);
      expect(info.authorUrl, telegramChannelUrl);
    });

    test('TG-MSG-004 Arabic caption is preserved', () {
      const caption = 'مرحبا بالعالم';
      final info = TelegramResolver.parseMessageInfo(
        html: telegramTextHtml(caption: caption),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(info.caption, caption);
    });

    test('TG-MSG-005 share query does not change identity', () {
      final share = Uri.parse('$telegramMessageUrl?utm_source=telegram');
      expect(
        TelegramUri.contentIdentity(TelegramUri.normalize(share)),
        TelegramUri.contentIdentity(Uri.parse(telegramMessageUrl)),
      );
    });
  });
}
