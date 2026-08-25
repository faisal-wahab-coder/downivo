import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  group('Phase 1 — WhatsApp platform detection', () {
    test('WA-URL-001 wa.me is WhatsApp', () {
      final uri = Uri.parse(whatsappChatUrl);
      expect(SocialPlatform.fromUri(uri), SocialPlatform.whatsapp);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'WhatsApp');
    });

    test('WA-URL-002 www.whatsapp.com is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(whatsappHomeUrl)),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-003 whatsapp.com is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://whatsapp.com/')),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-004 chat.whatsapp.com is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(whatsappInviteUrl)),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-005 web.whatsapp.com is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(whatsappWebUrl)),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-006 api.whatsapp.com is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://api.whatsapp.com/send?phone=$whatsappPhone'),
        ),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-007 whatsapp:// is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('whatsapp://send?phone=$whatsappPhone'),
        ),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-008 channel URL is WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(whatsappChannelUrl)),
        SocialPlatform.whatsapp,
      );
    });

    test('WA-URL-009 example.com is not WhatsApp', () {
      final uri = Uri.parse('https://example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('WA-URL-010 youtube.com is NOT WhatsApp', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.youtube.com/watch?v=abc'),
        ),
        isNot(SocialPlatform.whatsapp),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('WA-URL-020 home is HOME', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappHomeUrl)),
        WhatsAppContentType.home,
      );
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappWaMeHomeUrl)),
        WhatsAppContentType.home,
      );
    });

    test('WA-URL-021 wa.me phone is CHAT_LINK', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappChatUrl)),
        WhatsAppContentType.chatLink,
      );
    });

    test('WA-URL-022 wa.me with text is CHAT_LINK', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappChatTextUrl)),
        WhatsAppContentType.chatLink,
      );
    });

    test('WA-URL-023 invite is GROUP_INVITE', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappInviteUrl)),
        WhatsAppContentType.groupInvite,
      );
    });

    test('WA-URL-024 channel is PUBLIC_CHANNEL', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappChannelUrl)),
        WhatsAppContentType.publicChannel,
      );
    });

    test('WA-URL-025 channel post is PUBLIC_CHANNEL_POST', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappChannelPostUrl)),
        WhatsAppContentType.publicChannelPost,
      );
    });

    test('WA-URL-026 web is WHATSAPP_WEB', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappWebUrl)),
        WhatsAppContentType.whatsappWeb,
      );
    });

    test('WA-URL-027 wa.me/INVALID is INVALID', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappInvalidWaMeUrl)),
        WhatsAppContentType.invalid,
      );
    });

    test('WA-URL-028 whatsapp.com/INVALID is INVALID', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappInvalidPathUrl)),
        WhatsAppContentType.invalid,
      );
    });

    test('WA-URL-029 mmg CDN is PRIVATE_MEDIA', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappPrivateMediaUrl)),
        WhatsAppContentType.privateMedia,
      );
    });

    test('WA-URL-030 public CDN is DIRECT_MEDIA', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse(whatsappImageUrl)),
        WhatsAppContentType.directMedia,
      );
    });

    test('WA-URL-031 wa.me/message is BUSINESS_CHAT', () {
      expect(
        WhatsAppUri.classifyUrl(Uri.parse('https://wa.me/message/AbCdEf12345')),
        WhatsAppContentType.businessChat,
      );
    });

    test('WA-URL-032 whatsapp://send with phone is CHAT_LINK', () {
      expect(
        WhatsAppUri.classifyUrl(
          Uri.parse('whatsapp://send?phone=$whatsappPhone&text=Hi'),
        ),
        WhatsAppContentType.chatLink,
      );
    });

    test('WA-URL-033 whatsapp://chat is GROUP_INVITE', () {
      expect(
        WhatsAppUri.classifyUrl(
          Uri.parse('whatsapp://chat?code=$whatsappInviteCode'),
        ),
        WhatsAppContentType.groupInvite,
      );
    });

    test('WA-URL-034 call.whatsapp.com is CALL_LINK', () {
      expect(
        WhatsAppUri.classifyUrl(
          Uri.parse('https://call.whatsapp.com/video/abc'),
        ),
        WhatsAppContentType.callLink,
      );
    });
  });

  group('Phase 3 — IDs, normalize, identity', () {
    test('WA-URL-040 extracts phone and text', () {
      final uri = Uri.parse(whatsappChatTextUrl);
      expect(WhatsAppUri.phoneFromUri(uri), whatsappPhone);
      expect(WhatsAppUri.prefilledTextFromUri(uri), 'Hello from QA');
    });

    test('WA-URL-041 api.whatsapp.com send normalizes to wa.me', () {
      expect(
        WhatsAppUri.normalize(
          Uri.parse(
            'https://api.whatsapp.com/send?phone=$whatsappPhone&text=Hello',
          ),
        ).toString(),
        'https://wa.me/$whatsappPhone?text=Hello',
      );
    });

    test('WA-URL-042 tracking params are stripped from chat links', () {
      expect(
        WhatsAppUri.normalize(
          Uri.parse('$whatsappChatUrl?utm_source=share&fbclid=abc'),
        ).toString(),
        whatsappChatUrl,
      );
    });

    test('WA-URL-043 text is kept and tracking is stripped', () {
      expect(
        WhatsAppUri.normalize(
          Uri.parse('$whatsappChatUrl?text=Hello&utm_source=x'),
        ).toString(),
        'https://wa.me/$whatsappPhone?text=Hello',
      );
    });

    test('WA-URL-044 whatsapp://send normalizes to wa.me', () {
      expect(
        WhatsAppUri.tryNormalizeDeepLink(
          Uri.parse('whatsapp://send?phone=$whatsappPhone&text=Hi'),
        )?.toString(),
        'https://wa.me/$whatsappPhone?text=Hi',
      );
    });

    test('WA-URL-045 invite deep link is not normalized', () {
      expect(
        WhatsAppUri.tryNormalizeDeepLink(
          Uri.parse('whatsapp://chat?code=$whatsappInviteCode'),
        ),
        isNull,
      );
    });

    test('WA-URL-046 content identity is stable across URL variants', () {
      const identity = 'whatsapp:chat:$whatsappPhone';
      expect(WhatsAppUri.contentIdentity(Uri.parse(whatsappChatUrl)), identity);
      expect(
        WhatsAppUri.contentIdentity(Uri.parse(whatsappChatTextUrl)),
        identity,
      );
      expect(
        WhatsAppUri.contentIdentity(
          Uri.parse('https://api.whatsapp.com/send?phone=$whatsappPhone'),
        ),
        identity,
      );
    });

    test('WA-URL-047 chat and invite are not downloadable', () {
      expect(WhatsAppUri.isDownloadable(Uri.parse(whatsappChatUrl)), isFalse);
      expect(WhatsAppUri.isDownloadable(Uri.parse(whatsappInviteUrl)), isFalse);
      expect(WhatsAppUri.isDownloadable(Uri.parse(whatsappHomeUrl)), isFalse);
      expect(WhatsAppUri.isDownloadable(Uri.parse(whatsappWebUrl)), isFalse);
    });

    test('WA-URL-048 channel is downloadable only as public metadata', () {
      expect(
        WhatsAppUri.isDownloadable(Uri.parse(whatsappChannelUrl)),
        isTrue,
      );
      expect(
        WhatsAppUri.isDownloadable(Uri.parse(whatsappChannelPostUrl)),
        isTrue,
      );
    });

    test('WA-URL-049 invite is restricted; web requires authentication', () {
      expect(WhatsAppUri.isRestricted(Uri.parse(whatsappInviteUrl)), isTrue);
      expect(WhatsAppUri.isRestricted(Uri.parse(whatsappChatUrl)), isFalse);
      expect(
        WhatsAppUri.requiresAuthentication(Uri.parse(whatsappWebUrl)),
        isTrue,
      );
      expect(
        WhatsAppUri.requiresAuthentication(
          Uri.parse(whatsappPrivateMediaUrl),
        ),
        isTrue,
      );
      expect(
        WhatsAppUri.isDownloadable(Uri.parse(whatsappPrivateMediaUrl)),
        isFalse,
      );
    });

    test('WA-URL-050 home identity', () {
      expect(
        WhatsAppUri.contentIdentity(Uri.parse(whatsappHomeUrl)),
        'whatsapp:home',
      );
      expect(
        WhatsAppUri.contentIdentity(Uri.parse(whatsappWaMeHomeUrl)),
        'whatsapp:home',
      );
    });

    test('WA-URL-051 channel identity is stable with tracking', () {
      const identity = 'whatsapp:channel:$whatsappChannelId';
      expect(
        WhatsAppUri.contentIdentity(Uri.parse(whatsappChannelUrl)),
        identity,
      );
      expect(
        WhatsAppUri.contentIdentity(
          Uri.parse('$whatsappChannelUrl?utm_source=share'),
        ),
        identity,
      );
    });

    test('WA-URL-052 fragment is stripped from channel URLs', () {
      expect(
        WhatsAppUri.normalize(
          Uri.parse('$whatsappChannelUrl#section'),
        ).toString(),
        whatsappChannelUrl,
      );
    });
  });
}
