import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram videos', () {
    test('TG-VID-001 detects VIDEO', () {
      expect(
        TelegramResolver.detectMediaType(telegramVideoHtml()),
        TelegramMediaType.video,
      );
    });

    test('TG-VID-002 resolves the exposed MP4', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramVideoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
    });

    test('TG-VID-003 duration and thumbnail are mapped', () {
      final info = TelegramResolver.parseMessageInfo(
        html: telegramVideoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(info.durationSeconds, 75);
      expect(info.thumbnailUrl, telegramThumbUrl);
      expect(info.width, 1280);
      expect(info.height, 720);
    });

    test('TG-VID-004 HLS is not treated as a file', () {
      expect(
        TelegramResolver.isDirectMediaUrl(
          'https://cdn4.telesco.pe/file/stream.m3u8',
        ),
        isFalse,
      );
    });

    test('TG-VID-005 t.me page URL is not a video file', () {
      expect(TelegramResolver.isDirectMediaUrl(telegramMessageUrl), isFalse);
    });

    test('TG-VID-006 source src tag resolves the MP4', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramVideoSourceHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
    });
  });
}
