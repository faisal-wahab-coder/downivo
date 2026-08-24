import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 1 — Vimeo platform detection', () {
    test('VM-URL-001 vimeo.com video is Vimeo', () {
      final uri = Uri.parse('https://vimeo.com/76979871');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.vimeo);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Vimeo');
    });

    test('VM-URL-002 www.vimeo.com is Vimeo', () {
      final uri = Uri.parse('https://www.vimeo.com/76979871');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.vimeo);
    });

    test('VM-URL-003 player.vimeo.com is Vimeo', () {
      final uri = Uri.parse('https://player.vimeo.com/video/76979871');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.vimeo);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('VM-URL-004 m.vimeo.com is Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://m.vimeo.com/76979871')),
        SocialPlatform.vimeo,
      );
    });

    test('VM-URL-005 vimeo.com home is Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://vimeo.com/')),
        SocialPlatform.vimeo,
      );
    });

    test('VM-URL-006 non-Vimeo host is rejected', () {
      final uri = Uri.parse('https://www.example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('VM-URL-007 youtube.com is NOT Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.youtube.com/watch?v=abc')),
        isNot(SocialPlatform.vimeo),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('VM-URL-020 home page is HOME', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/')),
        VimeoContentType.home,
      );
      expect(
        VimeoResolver.classifyUrl(Uri.parse('https://vimeo.com/')),
        VimeoContentType.home,
      );
    });

    test('VM-URL-021 canonical video is VIDEO', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/76979871')),
        VimeoContentType.video,
      );
    });

    test('VM-URL-022 player URL is PLAYER', () {
      expect(
        VimeoUri.classifyUrl(
          Uri.parse('https://player.vimeo.com/video/76979871'),
        ),
        VimeoContentType.player,
      );
    });

    test('VM-URL-023 channel listing is CHANNEL', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/channels/staffpicks')),
        VimeoContentType.channel,
      );
    });

    test('VM-URL-024 channel video is CHANNEL_VIDEO', () {
      expect(
        VimeoUri.classifyUrl(
          Uri.parse('https://vimeo.com/channels/staffpicks/76979871'),
        ),
        VimeoContentType.channelVideo,
      );
    });

    test('VM-URL-025 group video is GROUP_VIDEO', () {
      expect(
        VimeoUri.classifyUrl(
          Uri.parse('https://vimeo.com/groups/motion/videos/76979871'),
        ),
        VimeoContentType.groupVideo,
      );
    });

    test('VM-URL-026 showcase video is SHOWCASE_VIDEO', () {
      expect(
        VimeoUri.classifyUrl(
          Uri.parse('https://vimeo.com/showcase/123/video/76979871'),
        ),
        VimeoContentType.showcaseVideo,
      );
    });

    test('VM-URL-027 username is USER', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/staff')),
        VimeoContentType.user,
      );
    });

    test('VM-URL-028 INVALID path is USER (not a video id)', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/INVALID')),
        VimeoContentType.user,
      );
    });

    test('VM-URL-029 ondemand is ON_DEMAND', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/ondemand/film')),
        VimeoContentType.onDemand,
      );
    });

    test('VM-URL-030 search is SEARCH', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/search?q=cats')),
        VimeoContentType.search,
      );
    });

    test('VM-URL-031 watch hub is WATCH', () {
      expect(
        VimeoUri.classifyUrl(Uri.parse('https://vimeo.com/watch')),
        VimeoContentType.watch,
      );
    });
  });

  group('Phase 3 — Video ID extraction (slug ignored)', () {
    test('VM-URL-040 extracts ID from canonical URL', () {
      expect(
        VimeoUri.videoIdFromUri(Uri.parse('https://vimeo.com/76979871')),
        '76979871',
      );
    });

    test('VM-URL-041 extracts ID from player URL', () {
      expect(
        VimeoUri.videoIdFromUri(
          Uri.parse('https://player.vimeo.com/video/76979871'),
        ),
        '76979871',
      );
    });

    test('VM-URL-042 extracts ID from unlisted URL without using hash as ID', () {
      final uri = Uri.parse('https://vimeo.com/76979871/abc12def');
      expect(VimeoUri.videoIdFromUri(uri), '76979871');
      expect(VimeoUri.privacyHashFromUri(uri), 'abc12def');
    });

    test('VM-URL-043 extracts ID from channel video', () {
      expect(
        VimeoUri.videoIdFromUri(
          Uri.parse('https://vimeo.com/channels/staffpicks/76979871'),
        ),
        '76979871',
      );
    });

    test('VM-URL-044 extracts ID from query clip_id', () {
      expect(
        VimeoUri.videoIdFromUri(
          Uri.parse('https://vimeo.com/moogaloop.swf?clip_id=76979871'),
        ),
        '76979871',
      );
    });

    test('VM-URL-045 home has no video ID', () {
      expect(VimeoUri.videoIdFromUri(Uri.parse('https://vimeo.com/')), isNull);
    });

    test('VM-URL-046 INVALID has no video ID', () {
      expect(
        VimeoUri.videoIdFromUri(Uri.parse('https://vimeo.com/INVALID')),
        isNull,
      );
    });

    test('VM-URL-047 player INVALID has no video ID', () {
      expect(
        VimeoUri.videoIdFromUri(
          Uri.parse('https://player.vimeo.com/video/INVALID'),
        ),
        isNull,
      );
    });

    test('VM-URL-048 numeric 123 is still treated as an ID', () {
      expect(
        VimeoUri.videoIdFromUri(Uri.parse('https://vimeo.com/123')),
        '123',
      );
    });
  });

  group('Phase 4 — URL normalization', () {
    test('VM-URL-060 strips tracking params', () {
      final uri = Uri.parse(
        'https://vimeo.com/76979871?utm_source=share&utm_medium=ios&fbclid=abc',
      );
      final normalized = VimeoUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('utm_source'), isFalse);
      expect(normalized.queryParameters.containsKey('fbclid'), isFalse);
      expect(VimeoUri.videoIdFromUri(normalized), '76979871');
    });

    test('VM-URL-061 player URL canonicalizes to vimeo.com/{id}', () {
      final normalized = VimeoUri.normalize(
        Uri.parse('https://player.vimeo.com/video/76979871'),
      );
      expect(normalized.host, 'vimeo.com');
      expect(normalized.path, '/76979871');
    });

    test('VM-URL-062 www host canonicalizes', () {
      expect(
        VimeoUri.normalize(Uri.parse('https://www.vimeo.com/76979871')).host,
        'vimeo.com',
      );
    });

    test('VM-URL-063 preserves privacy hash as h=', () {
      final normalized = VimeoUri.normalize(
        Uri.parse('https://vimeo.com/76979871/abc12def'),
      );
      expect(normalized.queryParameters['h'], 'abc12def');
      expect(VimeoUri.videoIdFromUri(normalized), '76979871');
    });

    test('VM-URL-064 player h= is preserved', () {
      final normalized = VimeoUri.normalize(
        Uri.parse('https://player.vimeo.com/video/76979871?h=abc12def'),
      );
      expect(normalized.queryParameters['h'], 'abc12def');
    });

    test('VM-URL-065 SocialUrlUtils uses Vimeo normalize', () {
      final targets = SocialUrlUtils.fetchTargets(
        Uri.parse('https://player.vimeo.com/video/76979871?utm_source=x'),
        SocialPlatform.vimeo,
      );
      expect(targets.any((t) => t.host == 'vimeo.com'), isTrue);
    });
  });

  group('Phase 5 — Duplicate identity', () {
    test('VM-URL-080 canonical and player share identity', () {
      expect(
        VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/76979871')),
        VimeoUri.contentIdentity(
          Uri.parse('https://player.vimeo.com/video/76979871'),
        ),
      );
      expect(
        VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/76979871')),
        'vimeo:video:76979871',
      );
    });

    test('VM-URL-081 tracking params do not change identity', () {
      expect(
        VimeoUri.contentIdentity(
          VimeoUri.normalize(
            Uri.parse('https://vimeo.com/76979871?utm_source=share'),
          ),
        ),
        'vimeo:video:76979871',
      );
    });

    test('VM-URL-082 unlisted hash is not part of identity', () {
      expect(
        VimeoUri.contentIdentity(
          Uri.parse('https://vimeo.com/76979871/abc12def'),
        ),
        VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/76979871')),
      );
    });

    test('VM-URL-083 different videos have different identities', () {
      expect(
        VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/111')),
        isNot(VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/222'))),
      );
    });

    test('VM-URL-084 home identity is not a video', () {
      expect(
        VimeoUri.contentIdentity(Uri.parse('https://vimeo.com/')),
        'vimeo:home',
      );
    });
  });

  group('Phase 6 — Downloadable vs non-downloadable', () {
    test('VM-URL-090 home is not downloadable', () {
      expect(VimeoUri.isDownloadable(Uri.parse('https://vimeo.com/')), isFalse);
    });

    test('VM-URL-091 video is downloadable', () {
      expect(
        VimeoUri.isDownloadable(Uri.parse('https://vimeo.com/76979871')),
        isTrue,
      );
    });

    test('VM-URL-092 player is downloadable', () {
      expect(
        VimeoUri.isDownloadable(
          Uri.parse('https://player.vimeo.com/video/76979871'),
        ),
        isTrue,
      );
    });

    test('VM-URL-093 user profile is not downloadable', () {
      expect(
        VimeoUri.isDownloadable(Uri.parse('https://vimeo.com/staff')),
        isFalse,
      );
    });

    test('VM-URL-094 INVALID is not downloadable', () {
      expect(
        VimeoUri.isDownloadable(Uri.parse('https://vimeo.com/INVALID')),
        isFalse,
      );
    });

    test('VM-URL-095 ondemand is not downloadable', () {
      expect(
        VimeoUri.isDownloadable(Uri.parse('https://vimeo.com/ondemand/film')),
        isFalse,
      );
    });

    test('VM-URL-096 channel listing is not downloadable', () {
      expect(
        VimeoUri.isDownloadable(
          Uri.parse('https://vimeo.com/channels/staffpicks'),
        ),
        isFalse,
      );
    });
  });

  group('Phase 7 — Fetch targets', () {
    test('VM-URL-100 fetch targets include player URL', () {
      final targets = SocialUrlUtils.fetchTargets(
        Uri.parse('https://vimeo.com/76979871'),
        SocialPlatform.vimeo,
      );
      expect(
        targets.any((t) => t.host.contains('player.vimeo.com')),
        isTrue,
      );
    });
  });
}
