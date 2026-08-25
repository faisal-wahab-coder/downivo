import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  group('WhatsApp metadata mapping', () {
    test('WA-META-001 channel identity and title', () {
      final info = WhatsAppResolver.parseChannelInfo(
        html: whatsappChannelHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
        contentId: 'whatsapp:channel:$whatsappChannelId',
      );
      expect(info.contentId, 'whatsapp:channel:$whatsappChannelId');
      expect(info.channelId, whatsappChannelId);
      expect(info.title, 'QA Public Channel');
      expect(info.description, 'A public WhatsApp Channel');
      expect(info.canonicalUrl, whatsappChannelUrl);
    });

    test('WA-META-002 phone is extracted without sending a message', () {
      final uri = Uri.parse(whatsappChatTextUrl);
      expect(WhatsAppUri.phoneFromUri(uri), whatsappPhone);
      expect(WhatsAppUri.prefilledTextFromUri(uri), 'Hello from QA');
      expect(WhatsAppUri.isDownloadable(uri), isFalse);
    });

    test('WA-META-003 MIME mapping', () {
      expect(WhatsAppResolver.mimeFromUrl(whatsappVideoUrl), 'video/mp4');
      expect(WhatsAppResolver.mimeFromUrl(whatsappImageUrl), 'image/jpeg');
      expect(WhatsAppResolver.mimeFromUrl(whatsappPdfUrl), 'application/pdf');
      expect(WhatsAppResolver.mimeFromUrl(whatsappAudioUrl), 'audio/mpeg');
    });

    test('WA-META-004 pageUrl is preserved on resources', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelHtml(title: 'Sunset'),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results.single.pageUrl, whatsappChannelUrl);
      expect(results.single.platform, 'WhatsApp');
      expect(results.single.title, 'Sunset');
    });

    test('WA-META-005 video duration 75 seconds', () {
      final info = WhatsAppResolver.parseChannelInfo(
        html: whatsappChannelVideoHtml(duration: '75'),
        pageUrl: Uri.parse(whatsappChannelPostUrl),
      );
      expect(info.durationSeconds, 75);
      expect(info.mediaType, WhatsAppMediaType.video);
    });
  });
}
