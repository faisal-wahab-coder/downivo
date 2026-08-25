import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  group('LinkedIn post classification', () {
    test('LI-POST-001 public post is POST', () {
      expect(
        LinkedInResolver.classifyUrl(Uri.parse(linkedinPostUrl)),
        LinkedInContentType.post,
      );
    });

    test('LI-POST-002 text-only post has no downloadable media', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinTextPostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isEmpty);
    });

    test('LI-POST-003 auth wall has no media', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinAuthWallHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isEmpty);
    });

    test('LI-POST-004 post identity is activity id not slug', () {
      expect(
        LinkedInUri.contentIdentity(Uri.parse(linkedinPostUrl)),
        isNot(contains('abcd')),
      );
      expect(
        LinkedInUri.contentIdentity(Uri.parse(linkedinPostUrl)),
        contains(linkedinActivityId),
      );
    });

    test('LI-POST-005 share-copy query maps to same post', () {
      final share = Uri.parse('$linkedinPostUrl?trk=public_post_share-copy');
      expect(
        LinkedInUri.contentIdentity(LinkedInUri.normalize(share)),
        LinkedInUri.contentIdentity(Uri.parse(linkedinFeedUrl)),
      );
    });
  });
}
