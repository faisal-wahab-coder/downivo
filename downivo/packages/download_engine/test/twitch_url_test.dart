import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 1 — Twitch platform detection', () {
    test('TW-URL-001 twitch.tv channel is Twitch', () {
      final uri = Uri.parse('https://www.twitch.tv/shroud');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.twitch);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Twitch');
    });

    test('TW-URL-002 twitch.tv without www is Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://twitch.tv/shroud')),
        SocialPlatform.twitch,
      );
    });

    test('TW-URL-003 m.twitch.tv is Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://m.twitch.tv/shroud')),
        SocialPlatform.twitch,
      );
    });

    test('TW-URL-004 clips.twitch.tv is Twitch', () {
      final uri = Uri.parse(
        'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.twitch);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('TW-URL-005 player.twitch.tv is Twitch', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://player.twitch.tv/?video=123456789'),
        ),
        SocialPlatform.twitch,
      );
    });

    test('TW-URL-006 home is Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.twitch.tv/')),
        SocialPlatform.twitch,
      );
    });

    test('TW-URL-007 non-Twitch host is rejected', () {
      final uri = Uri.parse('https://example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('TW-URL-008 youtube.com is NOT Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.youtube.com/watch?v=abc')),
        isNot(SocialPlatform.twitch),
      );
    });

    test('TW-URL-009 vimeo.com is NOT Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://vimeo.com/76979871')),
        isNot(SocialPlatform.twitch),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('TW-URL-020 home page is HOME', () {
      expect(
        TwitchUri.classifyUrl(Uri.parse('https://www.twitch.tv/')),
        TwitchContentType.home,
      );
      expect(
        TwitchResolver.classifyUrl(Uri.parse('https://twitch.tv')),
        TwitchContentType.home,
      );
    });

    test('TW-URL-021 channel is CHANNEL', () {
      expect(
        TwitchUri.classifyUrl(Uri.parse('https://www.twitch.tv/shroud')),
        TwitchContentType.channel,
      );
    });

    test('TW-URL-022 VOD is VOD', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse('https://www.twitch.tv/videos/123456789'),
        ),
        TwitchContentType.vod,
      );
    });

    test('TW-URL-023 channel VOD path is VOD', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse('https://www.twitch.tv/shroud/video/123456789'),
        ),
        TwitchContentType.vod,
      );
    });

    test('TW-URL-024 clip host is CLIP', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse(
            'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        TwitchContentType.clip,
      );
    });

    test('TW-URL-025 channel clip path is CLIP', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse(
            'https://www.twitch.tv/lirik/clip/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        TwitchContentType.clip,
      );
    });

    test('TW-URL-026 directory is DIRECTORY', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse('https://www.twitch.tv/directory/game/Just%20Chatting'),
        ),
        TwitchContentType.directory,
      );
    });

    test('TW-URL-027 player video is VOD', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse('https://player.twitch.tv/?video=123456789'),
        ),
        TwitchContentType.vod,
      );
    });

    test('TW-URL-028 player channel is CHANNEL', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse('https://player.twitch.tv/?channel=shroud'),
        ),
        TwitchContentType.channel,
      );
    });

    test('TW-URL-029 player clip is CLIP', () {
      expect(
        TwitchUri.classifyUrl(
          Uri.parse(
            'https://player.twitch.tv/?clip=AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        TwitchContentType.clip,
      );
    });

    test('TW-URL-030 search is NON_CONTENT', () {
      expect(
        TwitchUri.classifyUrl(Uri.parse('https://www.twitch.tv/search?term=x')),
        TwitchContentType.nonContent,
      );
    });
  });

  group('Phase 3 — ID extraction', () {
    test('TW-URL-040 VOD id from /videos/{id}', () {
      expect(
        TwitchUri.videoIdFromUri(
          Uri.parse('https://www.twitch.tv/videos/123456789'),
        ),
        '123456789',
      );
    });

    test('TW-URL-041 VOD id strips v prefix', () {
      expect(
        TwitchUri.videoIdFromUri(
          Uri.parse('https://player.twitch.tv/?video=v123456789'),
        ),
        '123456789',
      );
    });

    test('TW-URL-042 clip slug from clips host', () {
      expect(
        TwitchUri.clipIdFromUri(
          Uri.parse(
            'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        'AwkwardHelplessSalamanderSwiftRage',
      );
    });

    test('TW-URL-043 clip slug from channel path', () {
      expect(
        TwitchUri.clipIdFromUri(
          Uri.parse(
            'https://www.twitch.tv/lirik/clip/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        'AwkwardHelplessSalamanderSwiftRage',
      );
    });

    test('TW-URL-044 channel login is lowercased', () {
      expect(
        TwitchUri.channelLoginFromUri(Uri.parse('https://www.twitch.tv/Shroud')),
        'shroud',
      );
    });

    test('TW-URL-045 INVALID VOD path has no video id', () {
      expect(
        TwitchUri.videoIdFromUri(
          Uri.parse('https://www.twitch.tv/videos/INVALID'),
        ),
        isNull,
      );
    });

    test('TW-URL-046 home has no channel login', () {
      expect(
        TwitchUri.channelLoginFromUri(Uri.parse('https://www.twitch.tv/')),
        isNull,
      );
    });
  });

  group('Phase 4 — Normalization and identity', () {
    test('TW-URL-050 clip share params collapse to clips host', () {
      final normalized = TwitchUri.normalize(
        Uri.parse(
          'https://www.twitch.tv/lirik/clip/AwkwardHelplessSalamanderSwiftRage'
          '?tt_medium=clipboard_copy&utm_source=share',
        ),
      );
      expect(
        normalized.toString(),
        'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
      );
    });

    test('TW-URL-051 VOD tracking params collapse to canonical videos URL', () {
      final normalized = TwitchUri.normalize(
        Uri.parse('https://www.twitch.tv/videos/123456789?ref=share&t=1h2m'),
      );
      expect(normalized.toString(), 'https://www.twitch.tv/videos/123456789');
    });

    test('TW-URL-052 channel query params collapse', () {
      final normalized = TwitchUri.normalize(
        Uri.parse('https://m.twitch.tv/Shroud?fbclid=abc'),
      );
      expect(normalized.toString(), 'https://www.twitch.tv/shroud');
    });

    test('TW-URL-053 clip identity ignores tracking', () {
      expect(
        TwitchUri.contentIdentity(
          Uri.parse(
            'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage?utm_source=x',
          ),
        ),
        'twitch:clip:AwkwardHelplessSalamanderSwiftRage',
      );
      expect(
        TwitchUri.contentIdentity(
          Uri.parse(
            'https://www.twitch.tv/lirik/clip/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        'twitch:clip:AwkwardHelplessSalamanderSwiftRage',
      );
    });

    test('TW-URL-054 VOD identity is numeric id', () {
      expect(
        TwitchUri.contentIdentity(
          Uri.parse('https://player.twitch.tv/?video=v123456789'),
        ),
        'twitch:video:123456789',
      );
    });

    test('TW-URL-055 channel identity is login', () {
      expect(
        TwitchUri.contentIdentity(Uri.parse('https://www.twitch.tv/Shroud')),
        'twitch:channel:shroud',
      );
    });

    test('TW-URL-056 home identity', () {
      expect(
        TwitchUri.contentIdentity(Uri.parse('https://www.twitch.tv/')),
        'twitch:home',
      );
    });

    test('TW-URL-057 isDownloadable only for clips', () {
      expect(
        TwitchUri.isDownloadable(
          Uri.parse(
            'https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage',
          ),
        ),
        isTrue,
      );
      expect(
        TwitchUri.isDownloadable(
          Uri.parse('https://www.twitch.tv/videos/123456789'),
        ),
        isFalse,
      );
      expect(
        TwitchUri.isDownloadable(Uri.parse('https://www.twitch.tv/shroud')),
        isFalse,
      );
      expect(
        TwitchUri.isDownloadable(Uri.parse('https://www.twitch.tv/')),
        isFalse,
      );
    });
  });
}
