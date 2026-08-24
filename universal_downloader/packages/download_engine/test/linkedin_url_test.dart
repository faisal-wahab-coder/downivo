import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  group('Phase 1 — LinkedIn platform detection', () {
    test('LI-URL-001 www.linkedin.com is LinkedIn', () {
      final uri = Uri.parse(linkedinPostUrl);
      expect(SocialPlatform.fromUri(uri), SocialPlatform.linkedin);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'LinkedIn');
    });

    test('LI-URL-002 linkedin.com without www is LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://linkedin.com/in/someone/')),
        SocialPlatform.linkedin,
      );
    });

    test('LI-URL-003 m.linkedin.com is LinkedIn', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://m.linkedin.com/feed/update/urn:li:activity:$linkedinActivityId'),
        ),
        SocialPlatform.linkedin,
      );
    });

    test('LI-URL-004 lnkd.in short URL is LinkedIn', () {
      final uri = Uri.parse('https://lnkd.in/abc123XY');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.linkedin);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('LI-URL-005 media.licdn.com is LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(linkedinImageUrl)),
        SocialPlatform.linkedin,
      );
    });

    test('LI-URL-006 dms.licdn.com is LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(linkedinVideoMp4)),
        SocialPlatform.linkedin,
      );
    });

    test('LI-URL-007 non-LinkedIn host is rejected', () {
      final uri = Uri.parse('https://example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('LI-URL-008 youtube.com is NOT LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.youtube.com/watch?v=abc')),
        isNot(SocialPlatform.linkedin),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('LI-URL-020 home is HOME', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse('https://www.linkedin.com/')),
        LinkedInContentType.home,
      );
      expect(
        LinkedInResolver.classifyUrl(Uri.parse('https://linkedin.com')),
        LinkedInContentType.home,
      );
    });

    test('LI-URL-021 feed is FEED', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse('https://www.linkedin.com/feed/')),
        LinkedInContentType.feed,
      );
    });

    test('LI-URL-022 posts URL is POST', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse(linkedinPostUrl)),
        LinkedInContentType.post,
      );
    });

    test('LI-URL-023 feed update URN is POST', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse(linkedinFeedUrl)),
        LinkedInContentType.post,
      );
    });

    test('LI-URL-024 ugcPost URN is POST', () {
      expect(
        LinkedInUri.classifyUrl(
          Uri.parse(
            'https://www.linkedin.com/feed/update/urn:li:ugcPost:$linkedinActivityId/',
          ),
        ),
        LinkedInContentType.post,
      );
    });

    test('LI-URL-025 embed is EMBED', () {
      expect(
        LinkedInUri.classifyUrl(
          Uri.parse(
            'https://www.linkedin.com/embed/feed/update/urn:li:share:$linkedinActivityId',
          ),
        ),
        LinkedInContentType.embed,
      );
    });

    test('LI-URL-026 pulse is ARTICLE', () {
      expect(
        LinkedInUri.classifyUrl(
          Uri.parse('https://www.linkedin.com/pulse/how-we-build-software'),
        ),
        LinkedInContentType.article,
      );
    });

    test('LI-URL-027 profile is PROFILE', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse('https://www.linkedin.com/in/someone/')),
        LinkedInContentType.profile,
      );
    });

    test('LI-URL-028 company is COMPANY', () {
      expect(
        LinkedInUri.classifyUrl(
          Uri.parse('https://www.linkedin.com/company/linkedin/'),
        ),
        LinkedInContentType.company,
      );
    });

    test('LI-URL-029 lnkd.in is SHORT_URL', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse('https://lnkd.in/abc123XY')),
        LinkedInContentType.shortUrl,
      );
    });

    test('LI-URL-030 media CDN is DIRECT_MEDIA', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse(linkedinImageUrl)),
        LinkedInContentType.directMedia,
      );
    });

    test('LI-URL-031 /video/ is VIDEO', () {
      expect(
        LinkedInUri.classifyUrl(
          Uri.parse('https://www.linkedin.com/video/live/123456789'),
        ),
        LinkedInContentType.video,
      );
    });

    test('LI-URL-032 /posts/ without slug is non-content', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse('https://www.linkedin.com/posts/')),
        LinkedInContentType.nonContent,
      );
    });

    test('LI-URL-033 jobs is JOBS', () {
      expect(
        LinkedInUri.classifyUrl(Uri.parse('https://www.linkedin.com/jobs/')),
        LinkedInContentType.jobs,
      );
    });

    test('LI-URL-034 mwlite profile is PROFILE', () {
      expect(
        LinkedInUri.classifyUrl(
          Uri.parse('https://www.linkedin.com/mwlite/in/someone/'),
        ),
        LinkedInContentType.profile,
      );
    });
  });

  group('Phase 3 — ID extraction (slug ignored)', () {
    test('LI-URL-040 activity ID from posts slug', () {
      expect(
        LinkedInUri.activityIdFromUri(Uri.parse(linkedinPostUrl)),
        linkedinActivityId,
      );
    });

    test('LI-URL-041 activity ID from feed URN', () {
      expect(
        LinkedInUri.activityIdFromUri(Uri.parse(linkedinFeedUrl)),
        linkedinActivityId,
      );
    });

    test('LI-URL-042 ugcPost ID from encoded URN', () {
      expect(
        LinkedInUri.ugcPostIdFromUri(
          Uri.parse(
            'https://www.linkedin.com/feed/update/urn%3Ali%3AugcPost%3A$linkedinActivityId/',
          ),
        ),
        linkedinActivityId,
      );
    });

    test('LI-URL-043 share ID from embed', () {
      expect(
        LinkedInUri.shareIdFromUri(
          Uri.parse(
            'https://www.linkedin.com/embed/feed/update/urn:li:share:$linkedinActivityId',
          ),
        ),
        linkedinActivityId,
      );
    });

    test('LI-URL-044 home has no content ID', () {
      expect(
        LinkedInUri.contentIdFromUri(Uri.parse('https://www.linkedin.com/')),
        isNull,
      );
    });

    test('LI-URL-045 author vanity from posts URL', () {
      expect(LinkedInUri.authorFromUri(Uri.parse(linkedinPostUrl)), 'linkedin');
    });

    test('LI-URL-046 author from profile URL', () {
      expect(
        LinkedInUri.authorFromUri(Uri.parse('https://www.linkedin.com/in/ada-lovelace/')),
        'ada-lovelace',
      );
    });

    test('LI-URL-047 company slug', () {
      expect(
        LinkedInUri.companyFromUri(
          Uri.parse('https://www.linkedin.com/company/acme-corp/'),
        ),
        'acme-corp',
      );
    });
  });

  group('Phase 4 — Normalization and identity', () {
    test('LI-URL-050 posts and feed URN share identity', () {
      expect(
        LinkedInUri.contentIdentity(Uri.parse(linkedinPostUrl)),
        'linkedin:activity:$linkedinActivityId',
      );
      expect(
        LinkedInUri.contentIdentity(Uri.parse(linkedinFeedUrl)),
        'linkedin:activity:$linkedinActivityId',
      );
    });

    test('LI-URL-051 tracking params do not change identity', () {
      final tracked = Uri.parse(
        '$linkedinPostUrl?trk=public_post_share-copy&utm_source=share',
      );
      expect(
        LinkedInUri.contentIdentity(tracked),
        LinkedInUri.contentIdentity(Uri.parse(linkedinPostUrl)),
      );
    });

    test('LI-URL-052 normalize strips tracking and uses activity URN', () {
      final normalized = LinkedInUri.normalize(
        Uri.parse('$linkedinPostUrl?trk=share&utm_medium=ios'),
      );
      expect(normalized.host, 'www.linkedin.com');
      expect(normalized.path, contains('urn:li:activity:$linkedinActivityId'));
      expect(normalized.query, isEmpty);
    });

    test('LI-URL-053 mobile host normalizes to www', () {
      final normalized = LinkedInUri.normalize(
        Uri.parse(
          'https://m.linkedin.com/feed/update/urn:li:activity:$linkedinActivityId/',
        ),
      );
      expect(normalized.host, 'www.linkedin.com');
      expect(
        LinkedInUri.contentIdentity(normalized),
        'linkedin:activity:$linkedinActivityId',
      );
    });

    test('LI-URL-054 isDownloadable for posts and short links', () {
      expect(LinkedInUri.isDownloadable(Uri.parse(linkedinPostUrl)), isTrue);
      expect(LinkedInUri.isDownloadable(Uri.parse('https://lnkd.in/abc')), isTrue);
      expect(LinkedInUri.isDownloadable(Uri.parse(linkedinImageUrl)), isTrue);
      expect(
        LinkedInUri.isDownloadable(Uri.parse('https://www.linkedin.com/')),
        isFalse,
      );
      expect(
        LinkedInUri.isDownloadable(Uri.parse('https://www.linkedin.com/in/x/')),
        isFalse,
      );
      expect(
        LinkedInUri.isDownloadable(
          Uri.parse('https://www.linkedin.com/company/x/'),
        ),
        isFalse,
      );
      expect(
        LinkedInUri.isDownloadable(
          Uri.parse('https://www.linkedin.com/pulse/an-article'),
        ),
        isFalse,
      );
    });

    test('LI-URL-055 fetch targets include embed', () {
      final targets = LinkedInUri.fetchTargets(Uri.parse(linkedinPostUrl));
      expect(
        targets.any((u) => u.path.contains('/embed/feed/update/')),
        isTrue,
      );
    });

    test('LI-URL-056 share ugcPost URL identity ignores tracking and slug', () {
      final uri = Uri.parse(
        'https://www.linkedin.com/posts/praveenjha79_techhumor-artificialintelligence-claude-ugcPost-7493659222950322176-IJOa/?utm_source=share&utm_medium=member_desktop&rcm=ACoAAApNOxUBrtwRy7_hHR3CedkeV5QceWHUMXA',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.linkedin);
      expect(LinkedInUri.classifyUrl(uri), LinkedInContentType.post);
      expect(LinkedInUri.ugcPostIdFromUri(uri), '7493659222950322176');
      expect(LinkedInUri.authorFromUri(uri), 'praveenjha79');
      expect(
        LinkedInUri.contentIdentity(uri),
        'linkedin:ugcPost:7493659222950322176',
      );
      expect(LinkedInUri.normalize(uri).query, isEmpty);
      expect(
        LinkedInUri.normalize(uri).path,
        contains('urn:li:ugcPost:7493659222950322176'),
      );
      expect(
        LinkedInUri.fetchTargets(uri).any(
          (u) => u.path.contains('embed/feed/update/urn:li:ugcPost:7493659222950322176'),
        ),
        isTrue,
      );
    });
  });
}
