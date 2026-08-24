import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  group('WhatsApp images', () {
    test('WA-IMG-001 detects IMAGE', () {
      expect(
        WhatsAppResolver.detectMediaType(whatsappChannelHtml()),
        WhatsAppMediaType.image,
      );
    });

    test('WA-IMG-002 extracts dimensions and MIME', () {
      final items = WhatsAppResolver.parseMediaItems(whatsappChannelHtml());
      expect(items, hasLength(1));
      expect(items.single.mimeType, 'image/jpeg');
      expect(items.single.width, 1280);
      expect(items.single.height, 720);
    });

    test('WA-IMG-003 site logo is not treated as channel media', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelTextHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results, isEmpty);
    });

    test('WA-IMG-004 imported JPEG maps to image/jpeg', () {
      expect(WhatsAppResolver.mimeFromUrl('photo.jpg'), 'image/jpeg');
      expect(WhatsAppResolver.mimeFromUrl('photo.png'), 'image/png');
      expect(WhatsAppResolver.mimeFromUrl('photo.webp'), 'image/webp');
    });

    test('WA-IMG-005 thumbnail uses the public image URL', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results.single.thumbnailUrl, whatsappImageUrl);
    });
  });
}
