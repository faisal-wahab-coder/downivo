import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads metadata mapping', () {
    test('TH-META-001 post identity author and caption', () {
      final info = ThreadsResolver.parsePostInfo(
        html: threadsVideoHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(info.postId, threadsPostId);
      expect(info.author, threadsDisplayName);
      expect(info.username, threadsUsername);
      expect(info.authorId, threadsAuthorId);
      expect(info.canonicalUrl, threadsPostUrl);
    });

    test('TH-META-002 Arabic caption is preserved', () {
      const caption = 'مرحبا بالعالم';
      final info = ThreadsResolver.parsePostInfo(
        html: threadsImageHtml(caption: caption),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.caption, caption);
    });

    test('TH-META-003 MIME mapping', () {
      expect(ThreadsResolver.mimeFromUrl(threadsVideoUrl), 'video/mp4');
      expect(ThreadsResolver.mimeFromUrl(threadsImageUrl), 'image/jpeg');
      expect(
        ThreadsResolver.mimeFromUrl(threadsHlsUrl),
        'application/vnd.apple.mpegurl',
      );
    });

    test('TH-META-004 pageUrl is preserved on resources', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(title: 'Sunset'),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.pageUrl, threadsPostUrl);
      expect(results.single.platform, 'Threads');
    });

    test('TH-META-005 missing metadata is null not fabricated', () {
      final info = ThreadsResolver.parsePostInfo(
        html: '<html><body></body></html>',
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.caption, isNull);
      expect(info.durationSeconds, isNull);
      expect(info.publishedAt, isNull);
    });

    test('TH-META-006 published date is parsed when present', () {
      final info = ThreadsResolver.parsePostInfo(
        html: threadsImageHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.publishedAt, isNotNull);
    });

    test('TH-META-007 emoji caption is preserved', () {
      const caption = 'Hello 🧵🔥';
      final info = ThreadsResolver.parsePostInfo(
        html: threadsImageHtml(caption: caption),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.caption, caption);
    });
  });
}
