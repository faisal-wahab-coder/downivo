import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram documents', () {
    test('TG-DOC-001 detects DOCUMENT', () {
      expect(
        TelegramResolver.detectMediaType(telegramDocumentHtml()),
        TelegramMediaType.document,
      );
    });

    test('TG-DOC-002 extracts filename, MIME, and CDN URL', () {
      final items = TelegramResolver.parseMediaItems(telegramDocumentHtml());
      expect(items, hasLength(1));
      expect(items.single.fileName, 'report.pdf');
      expect(items.single.mimeType, 'application/pdf');
      expect(items.single.url, telegramPdfUrl);
    });

    test('TG-DOC-003 document without CDN href is not downloaded', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramDocumentHtml(href: telegramMessageUrl),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results, isEmpty);
    });

    test('TG-DOC-004 MIME mapping for common files', () {
      expect(TelegramResolver.mimeFromUrl('a.pdf'), 'application/pdf');
      expect(TelegramResolver.mimeFromUrl('a.zip'), 'application/zip');
      expect(
        TelegramResolver.mimeFromUrl('app.apk'),
        'application/vnd.android.package-archive',
      );
      expect(TelegramResolver.mimeFromUrl('notes.txt'), 'text/plain');
    });
  });
}
