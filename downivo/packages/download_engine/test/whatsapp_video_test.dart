import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  group('WhatsApp video', () {
    test('WA-VID-001 detects VIDEO', () {
      expect(
        WhatsAppResolver.detectMediaType(whatsappChannelVideoHtml()),
        WhatsAppMediaType.video,
      );
    });

    test('WA-VID-002 extracts MP4 URL, MIME, and thumbnail', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelVideoHtml(),
        pageUrl: Uri.parse(whatsappChannelPostUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, whatsappVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
      expect(results.single.thumbnailUrl, whatsappThumbUrl);
    });

    test('WA-VID-003 duration is parsed from Open Graph', () {
      final info = WhatsAppResolver.parseChannelInfo(
        html: whatsappChannelVideoHtml(duration: '75'),
        pageUrl: Uri.parse(whatsappChannelPostUrl),
      );
      expect(info.durationSeconds, 75);
      expect(info.width, 1280);
      expect(info.height, 720);
    });

    test('WA-VID-004 HLS is not a direct media URL', () {
      expect(
        WhatsAppResolver.isDirectMediaUrl(
          'https://scontent.xx.fbcdn.net/v/clip.m3u8',
        ),
        isFalse,
      );
    });

    test('WA-VID-005 imported MP4 is VIDEO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'VID-20240101-WA0001.mp4',
        ),
        WhatsAppMediaType.video,
      );
    });
  });
}
