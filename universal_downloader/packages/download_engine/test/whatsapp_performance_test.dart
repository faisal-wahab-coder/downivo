import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  group('WhatsApp performance / scale', () {
    test('WA-PERF-001 large channel HTML stays URL-only', () {
      final html = whatsappLargeChannelHtml(50);
      final results = WhatsAppResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(whatsappChannelUrl),
        contentId: 'whatsapp:channel:$whatsappChannelId',
      );
      expect(results.length, lessThanOrEqualTo(1));
      expect(
        results.every((r) => r.directUrl.startsWith('https://scontent.')),
        isTrue,
      );
    });

    test('WA-PERF-002 parse is deterministic', () {
      final html = whatsappChannelHtml();
      final pageUrl = Uri.parse(whatsappChannelUrl);
      final a = WhatsAppResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      final b = WhatsAppResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('WA-PERF-003 channel image parse does not invent extra files', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results, hasLength(1));
    });

    test('WA-PERF-004 identity is stable under tracking params', () {
      String? last;
      for (var i = 0; i < 20; i++) {
        final uri = Uri.parse('$whatsappChatUrl?utm_source=x$i');
        last = WhatsAppUri.contentIdentity(WhatsAppUri.normalize(uri));
      }
      expect(last, 'whatsapp:chat:$whatsappPhone');
    });

    test('WA-PERF-005 video parse returns a single URL resource', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelVideoHtml(),
        pageUrl: Uri.parse(whatsappChannelPostUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, whatsappVideoUrl);
    });

    test('WA-PERF-006 import classification does not load file bytes', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'VID-20240101-WA0001.mp4',
          mimeType: 'video/mp4',
        ),
        WhatsAppMediaType.video,
      );
    });
  });
}
