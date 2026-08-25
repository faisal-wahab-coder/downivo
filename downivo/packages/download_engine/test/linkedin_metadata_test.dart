import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  group('LinkedIn metadata mapping', () {
    test('LI-META-001 image post fields', () {
      final info = LinkedInResolver.parsePostInfo(
        html: linkedinImagePostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(info.contentId, linkedinActivityId);
      expect(info.title, contains('Public LinkedIn photo'));
      expect(info.description, 'A public image post');
      expect(info.author, 'Ada Lovelace');
      expect(info.authorUrl, 'https://www.linkedin.com/in/linkedin/');
      expect(info.thumbnailUrl, isNotNull);
    });

    test('LI-META-002 video duration from JSON-LD', () {
      final info = LinkedInResolver.parsePostInfo(
        html: linkedinVideoPostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(info.durationSeconds, 12.5);
    });

    test('LI-META-003 missing title is not fabricated', () {
      final info = LinkedInResolver.parsePostInfo(
        html: '<html><body></body></html>',
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(info.title, isNull);
    });

    test('LI-META-004 company from company URL', () {
      expect(
        LinkedInUri.companyFromUri(
          Uri.parse('https://www.linkedin.com/company/acme/'),
        ),
        'acme',
      );
      expect(
        LinkedInUri.companyUrlFromUri(
          Uri.parse('https://www.linkedin.com/company/acme/'),
        ),
        'https://www.linkedin.com/company/acme/',
      );
    });

    test('LI-META-005 resource title and platform', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(title: 'Sunset photo'),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.single.title, 'Sunset photo');
      expect(results.single.platform, 'LinkedIn');
      expect(results.single.pageUrl, linkedinPostUrl);
    });

    test('LI-META-006 MIME mapping from URL', () {
      expect(LinkedInResolver.mimeFromUrl(linkedinVideoMp4), 'video/mp4');
      expect(LinkedInResolver.mimeFromUrl(linkedinImageUrl), 'image/jpeg');
      expect(LinkedInResolver.mimeFromUrl(linkedinPdfUrl), 'application/pdf');
    });

    test('LI-META-007 author URL from profile', () {
      expect(
        LinkedInUri.authorUrlFromUri(
          Uri.parse('https://www.linkedin.com/in/ada-lovelace/'),
        ),
        'https://www.linkedin.com/in/ada-lovelace/',
      );
    });
  });
}
