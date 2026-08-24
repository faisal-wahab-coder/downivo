import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  group('Snapchat performance / scale', () {
    test('SC-PERF-001 large story parse stays URL-only', () {
      final html = snapchatLargeStoryHtml(50);
      final results = SnapchatResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(snapchatStoryUrl),
        contentId: snapchatUsername,
      );
      expect(results, hasLength(50));
      expect(
        results.every((r) => r.directUrl.startsWith('https://cf-st.sc-cdn.net/')),
        isTrue,
      );
    });

    test('SC-PERF-002 parse is deterministic', () {
      final html = snapchatStoryHtml();
      final pageUrl = Uri.parse(snapchatStoryUrl);
      final a = SnapchatResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      final b = SnapchatResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('SC-PERF-003 photo parse does not invent extra files', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results, hasLength(1));
    });

    test('SC-PERF-004 identity is stable under tracking params', () {
      String? last;
      for (var i = 0; i < 20; i++) {
        final uri = Uri.parse('$snapchatSpotlightUrl?utm_source=x$i');
        last = SnapchatUri.contentIdentity(SnapchatUri.normalize(uri));
      }
      expect(last, 'snapchat:spotlight:$snapchatSpotlightId');
    });

    test('SC-PERF-005 video parse returns a single URL resource', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatVideoHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatVideoUrl);
    });
  });
}
