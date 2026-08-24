import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  group('Phase 1 — Snapchat platform detection', () {
    test('SC-URL-001 snapchat.com is Snapchat', () {
      final uri = Uri.parse(snapchatSpotlightUrl);
      expect(SocialPlatform.fromUri(uri), SocialPlatform.snapchat);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Snapchat');
    });

    test('SC-URL-002 www.snapchat.com is Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(snapchatHomeUrl)),
        SocialPlatform.snapchat,
      );
    });

    test('SC-URL-003 t.snapchat.com is Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(snapchatShareUrl)),
        SocialPlatform.snapchat,
      );
    });

    test('SC-URL-004 story.snapchat.com is Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(snapchatStoryUrl)),
        SocialPlatform.snapchat,
      );
    });

    test('SC-URL-005 snapchat:// is Snapchat', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('snapchat://add/$snapchatUsername'),
        ),
        SocialPlatform.snapchat,
      );
    });

    test('SC-URL-006 sc-cdn.net is Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(snapchatVideoUrl)),
        SocialPlatform.snapchat,
      );
    });

    test('SC-URL-006b snap:// is Snapchat', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('snap://spotlight/$snapchatSpotlightId'),
        ),
        SocialPlatform.snapchat,
      );
    });

    test('SC-URL-007 example.com is not Snapchat', () {
      final uri = Uri.parse('https://example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-008 youtube.com is NOT Snapchat', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.youtube.com/watch?v=abc'),
        ),
        isNot(SocialPlatform.snapchat),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('SC-URL-020 home is HOME', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatHomeUrl)),
        SnapchatContentType.home,
      );
      expect(
        SnapchatResolver.classifyUrl(Uri.parse('https://www.snapchat.com')),
        SnapchatContentType.home,
      );
    });

    test('SC-URL-021 @username is PUBLIC_PROFILE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatProfileUrl)),
        SnapchatContentType.publicProfile,
      );
    });

    test('SC-URL-022 /add/username is PUBLIC_PROFILE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatAddUrl)),
        SnapchatContentType.publicProfile,
      );
    });

    test('SC-URL-023 /p/{id} is PUBLIC_PROFILE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatPProfileUrl)),
        SnapchatContentType.publicProfile,
      );
    });

    test('SC-URL-024 spotlight/{id} is SPOTLIGHT', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatSpotlightUrl)),
        SnapchatContentType.spotlight,
      );
    });

    test('SC-URL-024b /@user/spotlight/{id} is SPOTLIGHT not PROFILE', () {
      final uri = Uri.parse(snapchatProfileSpotlightUrl);
      expect(SnapchatUri.classifyUrl(uri), SnapchatContentType.spotlight);
      expect(SnapchatUri.isDownloadable(uri), isTrue);
      expect(SnapchatUri.spotlightIdFromUri(uri), snapchatSpotlightId);
      expect(SnapchatUri.usernameFromUri(uri), snapchatUsername);
    });

    test('SC-URL-024c /@user/spotlight without id is SPOTLIGHT_FEED', () {
      final uri = Uri.parse(
        'https://www.snapchat.com/@$snapchatUsername/spotlight',
      );
      expect(SnapchatUri.classifyUrl(uri), SnapchatContentType.spotlightFeed);
      expect(SnapchatUri.isDownloadable(uri), isFalse);
    });

    test('SC-URL-024d numeric username profile Spotlight is SPOTLIGHT', () {
      const uri = 'https://www.snapchat.com/@rveox213845/spotlight/'
          'W7_FIXTURE_SPOTLIGHT_AAAAAQ';
      expect(
        SnapchatUri.classifyUrl(Uri.parse(uri)),
        SnapchatContentType.spotlight,
      );
      expect(SnapchatUri.isDownloadable(Uri.parse(uri)), isTrue);
    });

    test('SC-URL-025 /spotlight feed is SPOTLIGHT_FEED', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatSpotlightFeedUrl)),
        SnapchatContentType.spotlightFeed,
      );
    });

    test('SC-URL-026 story host is PUBLIC_STORY', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatStoryUrl)),
        SnapchatContentType.publicStory,
      );
    });

    test('SC-URL-027 highlights is SAVED_STORY', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatSavedStoryUrl)),
        SnapchatContentType.savedStory,
      );
    });

    test('SC-URL-028 t.snapchat.com is SHARE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatShareUrl)),
        SnapchatContentType.share,
      );
    });

    test('SC-URL-029 /t/ is SHARE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatMobileShareUrl)),
        SnapchatContentType.share,
      );
    });

    test('SC-URL-030 embed is EMBED', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatEmbedUrl)),
        SnapchatContentType.embed,
      );
    });

    test('SC-URL-031 CDN file is DIRECT_MEDIA', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatPhotoUrl)),
        SnapchatContentType.directMedia,
      );
    });

    test('SC-URL-032 invalid path is NON_CONTENT', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse('https://www.snapchat.com/INVALID')),
        SnapchatContentType.nonContent,
      );
    });

    test('SC-URL-033 chat is PRIVATE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatChatUrl)),
        SnapchatContentType.private,
      );
    });

    test('SC-URL-034 login is AUTHENTICATION', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatLoginUrl)),
        SnapchatContentType.authentication,
      );
    });

    test('SC-URL-035 snapchat://add is PUBLIC_PROFILE', () {
      expect(
        SnapchatUri.classifyUrl(
          Uri.parse('snapchat://add/$snapchatUsername'),
        ),
        SnapchatContentType.publicProfile,
      );
    });

    test('SC-URL-036 snapchat://spotlight is SPOTLIGHT', () {
      expect(
        SnapchatUri.classifyUrl(
          Uri.parse('snapchat://spotlight/$snapchatSpotlightId'),
        ),
        SnapchatContentType.spotlight,
      );
    });

    test('SC-URL-037 snapchat://chat is PRIVATE', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse('snapchat://chat')),
        SnapchatContentType.private,
      );
    });

    test('SC-URL-038 snap/{id} is SNAP', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatSnapUrl)),
        SnapchatContentType.snap,
      );
    });
  });

  group('Phase 3 — IDs, normalize, identity', () {
    test('SC-URL-040 extracts username and spotlight id', () {
      expect(
        SnapchatUri.usernameFromUri(Uri.parse(snapchatAddUrl)),
        snapchatUsername,
      );
      expect(
        SnapchatUri.spotlightIdFromUri(Uri.parse(snapchatSpotlightUrl)),
        snapchatSpotlightId,
      );
    });

    test('SC-URL-041 embed extracts the same spotlight id', () {
      expect(
        SnapchatUri.spotlightIdFromUri(Uri.parse(snapchatEmbedUrl)),
        snapchatSpotlightId,
      );
    });

    test('SC-URL-042 tracking params do not change canonical spotlight', () {
      expect(
        SnapchatUri.normalize(
          Uri.parse('$snapchatSpotlightUrl?utm_source=share&fbclid=1'),
        ).toString(),
        snapchatSpotlightUrl,
      );
    });

    test('SC-URL-043 share URLs normalize to /t/{code}', () {
      expect(
        SnapchatUri.normalize(Uri.parse(snapchatShareUrl)).toString(),
        snapchatMobileShareUrl,
      );
      expect(
        SnapchatUri.normalize(Uri.parse(snapchatMobileShareUrl)).toString(),
        snapchatMobileShareUrl,
      );
    });

    test('SC-URL-044 snapchat://spotlight normalizes to web spotlight', () {
      expect(
        SnapchatUri.tryNormalizeDeepLink(
          Uri.parse('snapchat://spotlight/$snapchatSpotlightId'),
        )?.toString(),
        snapchatSpotlightUrl,
      );
    });

    test('SC-URL-045 private deep link is not normalized', () {
      expect(
        SnapchatUri.tryNormalizeDeepLink(Uri.parse('snapchat://chat')),
        isNull,
      );
    });

    test('SC-URL-046 content identity is stable across URL variants', () {
      const identity = 'snapchat:spotlight:$snapchatSpotlightId';
      expect(
        SnapchatUri.contentIdentity(Uri.parse(snapchatSpotlightUrl)),
        identity,
      );
      expect(
        SnapchatUri.contentIdentity(Uri.parse(snapchatEmbedUrl)),
        identity,
      );
      expect(
        SnapchatUri.contentIdentity(Uri.parse(snapchatProfileSpotlightUrl)),
        identity,
      );
      expect(
        SnapchatUri.contentIdentity(
          Uri.parse('$snapchatSpotlightUrl?utm_source=share'),
        ),
        identity,
      );
    });

    test('SC-URL-046b profile Spotlight fetch targets skip the profile page', () {
      final targets = SnapchatUri.fetchTargets(
        Uri.parse(snapchatProfileSpotlightUrl),
      ).map((uri) => uri.toString()).toList();
      expect(targets, contains(snapchatSpotlightUrl));
      expect(targets, contains(snapchatProfileSpotlightUrl));
      expect(targets, isNot(contains(snapchatProfileUrl)));
      expect(targets, isNot(contains(snapchatEmbedUrl)));
    });

    test('SC-URL-047 profile and home are not downloadable', () {
      expect(SnapchatUri.isDownloadable(Uri.parse(snapchatProfileUrl)), isFalse);
      expect(SnapchatUri.isDownloadable(Uri.parse(snapchatHomeUrl)), isFalse);
      expect(
        SnapchatUri.isDownloadable(Uri.parse(snapchatSpotlightFeedUrl)),
        isFalse,
      );
    });

    test('SC-URL-048 spotlight and share are downloadable', () {
      expect(
        SnapchatUri.isDownloadable(Uri.parse(snapchatSpotlightUrl)),
        isTrue,
      );
      expect(SnapchatUri.isDownloadable(Uri.parse(snapchatShareUrl)), isTrue);
      expect(SnapchatUri.isDownloadable(Uri.parse(snapchatStoryUrl)), isTrue);
    });

    test('SC-URL-049 private and login flags', () {
      expect(SnapchatUri.isRestricted(Uri.parse(snapchatChatUrl)), isTrue);
      expect(SnapchatUri.isRestricted(Uri.parse(snapchatMemoriesUrl)), isTrue);
      expect(
        SnapchatUri.isRestricted(Uri.parse(snapchatSpotlightUrl)),
        isFalse,
      );
      expect(
        SnapchatUri.requiresAuthentication(Uri.parse(snapchatLoginUrl)),
        isTrue,
      );
      expect(
        SnapchatUri.requiresAuthentication(Uri.parse(snapchatChatUrl)),
        isFalse,
      );
    });

    test('SC-URL-050 home identity', () {
      expect(
        SnapchatUri.contentIdentity(Uri.parse(snapchatHomeUrl)),
        'snapchat:home',
      );
    });

    test('SC-URL-051 share identity is stable', () {
      const identity = 'snapchat:share:$snapchatShareCode';
      expect(SnapchatUri.contentIdentity(Uri.parse(snapchatShareUrl)), identity);
      expect(
        SnapchatUri.contentIdentity(Uri.parse(snapchatMobileShareUrl)),
        identity,
      );
    });
  });
}
