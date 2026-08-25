import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram performance / scale', () {
    test('TG-PERF-001 large album parse stays URL-only', () {
      final html = telegramLargeAlbumHtml(50);
      final results = TelegramResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(telegramMessageUrl),
        contentId: '$telegramChannel/$telegramMessageId',
      );
      expect(results, hasLength(50));
      expect(
        results.every((r) => r.directUrl.startsWith('https://cdn4.telesco.pe/')),
        isTrue,
      );
    });

    test('TG-PERF-002 parse is deterministic', () {
      final html = telegramAlbumHtml();
      final pageUrl = Uri.parse(telegramMessageUrl);
      final a = TelegramResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      final b = TelegramResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('TG-PERF-003 photo parse does not invent extra files', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, hasLength(1));
    });

    test('TG-PERF-004 identity is stable under tracking params', () {
      String? last;
      for (var i = 0; i < 20; i++) {
        final uri = Uri.parse('$telegramMessageUrl?utm_source=x$i');
        last = TelegramUri.contentIdentity(TelegramUri.normalize(uri));
      }
      expect(last, 'telegram:message:$telegramChannel:$telegramMessageId');
    });

    test('TG-PERF-005 video parse returns a single URL resource', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramVideoHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, telegramVideoUrl);
    });
  });
}
