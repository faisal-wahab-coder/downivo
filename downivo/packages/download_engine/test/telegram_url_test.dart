import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  group('Phase 1 — Telegram platform detection', () {
    test('TG-URL-001 t.me is Telegram', () {
      final uri = Uri.parse(telegramMessageUrl);
      expect(SocialPlatform.fromUri(uri), SocialPlatform.telegram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Telegram');
    });

    test('TG-URL-002 www.t.me is Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.t.me/telegram/1')),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-003 telegram.me is Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://telegram.me/telegram/1')),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-004 telegram.org is Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://telegram.org/')),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-005 tg:// is Telegram', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('tg://resolve?domain=telegram&post=1'),
        ),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-006 telesco.pe CDN is Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(telegramPhotoUrl)),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-006b cdn.telegram.org is Telegram', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://cdn.telegram.org/file/fixture.jpg'),
        ),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-006c telegram:// is Telegram', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('telegram://resolve?domain=telegram&post=1'),
        ),
        SocialPlatform.telegram,
      );
    });

    test('TG-URL-007 non-Telegram host is rejected', () {
      final uri = Uri.parse('https://example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('TG-URL-008 youtube.com is NOT Telegram', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.youtube.com/watch?v=abc'),
        ),
        isNot(SocialPlatform.telegram),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('TG-URL-020 home is HOME', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse(telegramHomeUrl)),
        TelegramContentType.home,
      );
      expect(
        TelegramResolver.classifyUrl(Uri.parse('https://t.me')),
        TelegramContentType.home,
      );
    });

    test('TG-URL-021 channel is CHANNEL', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse(telegramChannelUrl)),
        TelegramContentType.channel,
      );
    });

    test('TG-URL-022 message is MESSAGE', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse(telegramMessageUrl)),
        TelegramContentType.message,
      );
    });

    test('TG-URL-023 t.me/s channel is PUBLIC_CHANNEL_PREVIEW', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse(telegramPreviewChannelUrl)),
        TelegramContentType.publicChannelPreview,
      );
    });

    test('TG-URL-024 t.me/s message is PUBLIC_MESSAGE_PREVIEW', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse(telegramPreviewUrl)),
        TelegramContentType.publicMessagePreview,
      );
    });

    test('TG-URL-025 t.me/c is PRIVATE_MESSAGE', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('https://t.me/c/1234567890/12')),
        TelegramContentType.privateMessage,
      );
    });

    test('TG-URL-026 invite +hash is INVITE', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('https://t.me/+AbCdEfGhIjKl')),
        TelegramContentType.invite,
      );
    });

    test('TG-URL-027 joinchat is INVITE', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('https://t.me/joinchat/AbCdEf')),
        TelegramContentType.invite,
      );
    });

    test('TG-URL-028 share is SHARE', () {
      expect(
        TelegramUri.classifyUrl(
          Uri.parse('https://t.me/share/url?url=https://example.com'),
        ),
        TelegramContentType.share,
      );
    });

    test('TG-URL-029 stickers is STICKERS', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('https://t.me/addstickers/CoolPack')),
        TelegramContentType.stickers,
      );
    });

    test('TG-URL-030 instant view is INSTANT_VIEW', () {
      expect(
        TelegramUri.classifyUrl(
          Uri.parse('https://t.me/iv?url=https://example.com'),
        ),
        TelegramContentType.instantView,
      );
    });

    test('TG-URL-031 CDN file is DIRECT_MEDIA', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse(telegramPhotoUrl)),
        TelegramContentType.directMedia,
      );
    });

    test('TG-URL-032 invalid message path is NON_CONTENT', () {
      expect(
        TelegramUri.classifyUrl(
          Uri.parse('https://t.me/telegram/INVALID_MESSAGE'),
        ),
        TelegramContentType.nonContent,
      );
    });

    test('TG-URL-033 tg://resolve with post is MESSAGE', () {
      expect(
        TelegramUri.classifyUrl(
          Uri.parse('tg://resolve?domain=telegram&post=1001'),
        ),
        TelegramContentType.message,
      );
    });

    test('TG-URL-034 tg://resolve domain only is CHANNEL', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('tg://resolve?domain=telegram')),
        TelegramContentType.channel,
      );
    });

    test('TG-URL-035 tg://join is INVITE', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('tg://join?invite=AbCdEf')),
        TelegramContentType.invite,
      );
    });

    test('TG-URL-036 tg://invalid is DEEP_LINK', () {
      expect(
        TelegramUri.classifyUrl(Uri.parse('tg://invalid')),
        TelegramContentType.deepLink,
      );
    });
  });

  group('Phase 3 — IDs, normalize, identity', () {
    test('TG-URL-040 extracts channel and message id', () {
      final uri = Uri.parse(telegramMessageUrl);
      expect(TelegramUri.channelFromUri(uri), telegramChannel);
      expect(TelegramUri.messageIdFromUri(uri), telegramMessageId);
    });

    test('TG-URL-041 preview URL extracts the same ids', () {
      final uri = Uri.parse(telegramPreviewUrl);
      expect(TelegramUri.channelFromUri(uri), telegramChannel);
      expect(TelegramUri.messageIdFromUri(uri), telegramMessageId);
    });

    test('TG-URL-042 normalize share and preview to canonical message', () {
      expect(
        TelegramUri.normalize(Uri.parse(telegramPreviewUrl)).toString(),
        telegramMessageUrl,
      );
      expect(
        TelegramUri.normalize(
          Uri.parse('$telegramMessageUrl?utm_source=share&single'),
        ).toString(),
        telegramMessageUrl,
      );
    });

    test('TG-URL-043 telegram.me normalizes to t.me', () {
      expect(
        TelegramUri.normalize(
          Uri.parse('https://telegram.me/telegram/1001'),
        ).toString(),
        telegramMessageUrl,
      );
    });

    test('TG-URL-044 tg://resolve normalizes to t.me message', () {
      expect(
        TelegramUri.tryNormalizeDeepLink(
          Uri.parse('tg://resolve?domain=telegram&post=1001'),
        )?.toString(),
        telegramMessageUrl,
      );
      expect(
        TelegramUri.tryNormalizeDeepLink(
          Uri.parse('telegram://resolve?domain=telegram&post=1001'),
        )?.toString(),
        telegramMessageUrl,
      );
    });

    test('TG-URL-045 invite deep link is not normalized', () {
      expect(
        TelegramUri.tryNormalizeDeepLink(Uri.parse('tg://join?invite=AbCdEf')),
        isNull,
      );
    });

    test('TG-URL-046 content identity is stable across URL variants', () {
      const identity = 'telegram:message:$telegramChannel:$telegramMessageId';
      expect(
        TelegramUri.contentIdentity(Uri.parse(telegramMessageUrl)),
        identity,
      );
      expect(
        TelegramUri.contentIdentity(Uri.parse(telegramPreviewUrl)),
        identity,
      );
      expect(
        TelegramUri.contentIdentity(
          Uri.parse('tg://resolve?domain=telegram&post=1001'),
        ),
        identity,
      );
    });

    test('TG-URL-047 channel is not downloadable', () {
      expect(
        TelegramUri.isDownloadable(Uri.parse(telegramChannelUrl)),
        isFalse,
      );
      expect(TelegramUri.isDownloadable(Uri.parse(telegramHomeUrl)), isFalse);
    });

    test('TG-URL-048 message is downloadable', () {
      expect(TelegramUri.isDownloadable(Uri.parse(telegramMessageUrl)), isTrue);
      expect(TelegramUri.isDownloadable(Uri.parse(telegramPreviewUrl)), isTrue);
    });

    test('TG-URL-049 private and invite are restricted', () {
      expect(
        TelegramUri.isRestricted(Uri.parse('https://t.me/c/1234567890/12')),
        isTrue,
      );
      expect(
        TelegramUri.isRestricted(Uri.parse('https://t.me/+AbCdEfGhIjKl')),
        isTrue,
      );
      expect(TelegramUri.isRestricted(Uri.parse(telegramMessageUrl)), isFalse);
      expect(
        TelegramUri.requiresAuthentication(
          Uri.parse('https://t.me/c/1234567890/12'),
        ),
        isFalse,
      );
      expect(
        TelegramUri.requiresAuthentication(Uri.parse('https://t.me/login')),
        isTrue,
      );
    });

    test('TG-URL-050 home identity', () {
      expect(
        TelegramUri.contentIdentity(Uri.parse(telegramHomeUrl)),
        'telegram:home',
      );
    });
  });
}
