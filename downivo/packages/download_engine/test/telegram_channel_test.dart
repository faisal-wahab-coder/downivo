import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = TelegramMockAdapter();
    TelegramMockAdapter.reset();
  });

  group('Telegram channel / preview', () {
    test('TG-CH-001 channel URL is CHANNEL and not downloadable', () {
      final uri = Uri.parse(telegramChannelUrl);
      expect(TelegramUri.classifyUrl(uri), TelegramContentType.channel);
      expect(TelegramUri.isDownloadable(uri), isFalse);
      expect(TelegramUri.channelFromUri(uri), telegramChannel);
    });

    test('TG-CH-002 public preview is PUBLIC_CHANNEL_PREVIEW', () {
      final uri = Uri.parse(telegramPreviewChannelUrl);
      expect(
        TelegramUri.classifyUrl(uri),
        TelegramContentType.publicChannelPreview,
      );
      expect(TelegramUri.isDownloadable(uri), isFalse);
      expect(
        TelegramUri.contentIdentity(uri),
        'telegram:preview:$telegramChannel',
      );
    });

    test('TG-CH-003 channel is not auto-downloaded', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final results = await ContentProviderRegistry(dio: mockDio).discoverAll(
        Uri.parse(telegramChannelUrl),
      );
      expect(results, isEmpty);
    });

    test('TG-CH-004 preview channel is not auto-downloaded', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final results = await ContentProviderRegistry(dio: mockDio).discoverAll(
        Uri.parse(telegramPreviewChannelUrl),
      );
      expect(results, isEmpty);
    });

    test('TG-CH-005 user error explains channel is not a message', () {
      expect(
        TelegramResolver.userFacingError(Uri.parse(telegramChannelUrl)),
        contains('channel'),
      );
      expect(
        TelegramResolver.userFacingError(Uri.parse(telegramPreviewChannelUrl)),
        contains('preview'),
      );
    });
  });
}
