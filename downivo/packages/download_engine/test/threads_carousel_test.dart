import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads carousel / multi-media', () {
    test('TH-CAR-001 carousel count and order', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsCarouselHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(3));
      expect(results[0].directUrl, threadsImageUrl);
      expect(results[1].directUrl, threadsImageUrlTwo);
      expect(results[2].directUrl, threadsImageUrlThree);
      expect(
        ThreadsResolver.detectMediaType(threadsCarouselHtml()),
        ThreadsMediaType.carousel,
      );
    });

    test('TH-CAR-002 carousel filenames are indexed', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsCarouselHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(results[0].fileName, contains('1'));
      expect(results[1].fileName, contains('2'));
      expect(results[2].fileName, contains('3'));
    });

    test('TH-CAR-003 multi-media image then video', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsMultiMediaHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(2));
      expect(results[0].mimeType, 'image/jpeg');
      expect(results[1].mimeType, 'video/mp4');
      expect(
        ThreadsResolver.detectMediaType(threadsMultiMediaHtml()),
        ThreadsMediaType.multiMedia,
      );
    });

    test('TH-CAR-004 duplicates are collapsed', () {
      final html = '''
<!DOCTYPE html>
<html><body>
<script>{"carousel_media":[
{"image_versions2":{"candidates":[{"url":"$threadsImageUrl","width":1080,"height":1080}]}},
{"image_versions2":{"candidates":[{"url":"$threadsImageUrl","width":1080,"height":1080}]}}
]}</script>
</body></html>''';
      final results = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
    });

    test('TH-CAR-005 carousel items are URL references not in-memory files', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsLargeCarouselHtml(12),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(12));
      expect(
        results.every((r) => r.directUrl.startsWith('https://scontent.')),
        isTrue,
      );
    });
  });
}
