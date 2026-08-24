import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  group('LinkedIn performance / scale', () {
    test('LI-PERF-001 large carousel does not collapse items', () {
      final urls = [
        for (var i = 0; i < 50; i++)
          'https://media.licdn.com/dms/image/v2/D4E22AQFitem$i/feedshare-shrink_2048_1536/0/$i',
      ];
      final html = '''
<html><body>
${urls.map((u) => '<img src="$u" />').join('\n')}
</body></html>
''';
      final results = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.length, 50);
      expect(results.map((r) => r.directUrl).toSet().length, 50);
      expect(results.map((r) => r.fileName).toSet().length, 50);
    });

    test('LI-PERF-002 parse is deterministic', () {
      final html = linkedinMultiImageHtml();
      final pageUrl = Uri.parse(linkedinPostUrl);
      final a = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
        contentId: linkedinActivityId,
      );
      final b = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
        contentId: linkedinActivityId,
      );
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('LI-PERF-003 small image parse is a single resource', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.length, 1);
    });

    test('LI-PERF-004 identity computation is cheap and stable', () {
      final uri = Uri.parse('$linkedinPostUrl?utm_source=x&trk=share');
      String? last;
      for (var i = 0; i < 50; i++) {
        last = LinkedInUri.contentIdentity(LinkedInUri.normalize(uri));
      }
      expect(last, 'linkedin:activity:$linkedinActivityId');
    });

    test('LI-PERF-005 parse does not load binary media', () {
      final html = linkedinVideoPostHtml();
      final results = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.single.directUrl, startsWith('https://'));
      expect(results.single.directUrl.length, lessThan(500));
    });
  });
}
