import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Telegram audio and voice', () {
    test('TG-AUD-001 detects AUDIO', () {
      expect(
        TelegramResolver.detectMediaType(telegramAudioHtml()),
        TelegramMediaType.audio,
      );
    });

    test('TG-AUD-002 resolves audio URL and MIME', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramAudioHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramAudioUrl);
      expect(results.single.mimeType, 'audio/mpeg');
    });

    test('TG-AUD-003 detects VOICE separately from documents', () {
      expect(
        TelegramResolver.detectMediaType(telegramVoiceHtml()),
        TelegramMediaType.voice,
      );
      final results = TelegramResolver.parseHtmlResources(
        html: telegramVoiceHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramVoiceUrl);
      expect(results.single.mimeType, 'audio/ogg');
    });

    test('TG-AUD-004 voice duration is parsed', () {
      final info = TelegramResolver.parseMessageInfo(
        html: telegramVoiceHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(info.durationSeconds, 12);
    });

    test('TG-AUD-005 MIME mapping for voice and audio files', () {
      expect(TelegramResolver.mimeFromUrl(telegramVoiceUrl), 'audio/ogg');
      expect(TelegramResolver.mimeFromUrl(telegramAudioUrl), 'audio/mpeg');
      expect(TelegramResolver.mimeFromUrl('file.opus'), 'audio/opus');
    });

    test('TG-AUD-006 audio src tag is classified as VOICE', () {
      expect(
        TelegramResolver.detectMediaType(telegramVoiceAudioSrcHtml()),
        TelegramMediaType.voice,
      );
      final results = TelegramResolver.parseHtmlResources(
        html: telegramVoiceAudioSrcHtml(),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.directUrl, telegramVoiceUrl);
      expect(results.single.mimeType, 'audio/ogg');
    });
  });
}
