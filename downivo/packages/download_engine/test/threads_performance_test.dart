import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads performance / scale', () {
    test('TH-PERF-001 large carousel parse stays URL-only', () {
      final html = threadsLargeCarouselHtml(50);
      final results = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(50));
      expect(
        results.every((r) => r.directUrl.startsWith('https://scontent.')),
        isTrue,
      );
    });

    test('TH-PERF-002 parse is deterministic', () {
      final html = threadsCarouselHtml();
      final pageUrl = Uri.parse(threadsPostUrl);
      final a = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      final b = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
      );
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('TH-PERF-003 image parse does not invent extra files', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
    });

    test('TH-PERF-004 identity is stable under tracking params', () {
      String? last;
      for (var i = 0; i < 20; i++) {
        final uri = Uri.parse('$threadsPostUrl?utm_source=x$i');
        last = ThreadsUri.contentIdentity(ThreadsUri.normalize(uri));
      }
      expect(last, 'threads:post:$threadsPostId');
    });

    test('TH-PERF-005 video parse returns a single URL resource', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsVideoHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsVideoUrl);
    });
  });
}
