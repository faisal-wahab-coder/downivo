import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads video posts', () {
    test('TH-VID-001 video post is VIDEO', () {
      expect(
        ThreadsResolver.detectMediaType(threadsVideoHtml()),
        ThreadsMediaType.video,
      );
    });

    test('TH-VID-002 video URL, thumbnail, duration, dimensions', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsVideoHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.directUrl, threadsVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
      expect(results.single.thumbnailUrl, threadsThumbUrl);
      expect(results.single.fileName.toLowerCase(), endsWith('.mp4'));

      final info = ThreadsResolver.parsePostInfo(
        html: threadsVideoHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.durationSeconds, 12.5);
      expect(info.width, 1080);
      expect(info.height, 1920);
    });

    test('TH-VID-003 HLS is not a downloadable file', () {
      expect(
        ThreadsResolver.isDirectMediaUrl(threadsHlsUrl),
        isFalse,
      );
      expect(
        ThreadsResolver.parseHtmlResources(
          html: threadsHlsHtml(),
          pageUrl: Uri.parse(threadsPostUrl),
        ),
        isEmpty,
      );
    });

    test('TH-VID-004 author and caption are mapped', () {
      final info = ThreadsResolver.parsePostInfo(
        html: threadsVideoHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.author, threadsDisplayName);
      expect(info.caption, 'A public Threads video');
    });

    test('TH-VID-005 video is not classified as IMAGE', () {
      expect(
        ThreadsResolver.detectMediaType(threadsVideoHtml()),
        isNot(ThreadsMediaType.image),
      );
    });

    test('TH-VID-006 unicode-escaped fna CDN video is decoded', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsUnicodeVideoHtml(),
        pageUrl: Uri.parse(threadsPostComUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsFnaVideoUrl);
      expect(results.single.directUrl, isNot(contains(r'\u002F')));
      expect(results.single.mimeType, 'video/mp4');
    });

    test('TH-VID-007 null carousel plus poster is still VIDEO', () {
      final html = threadsVideoWithNullCarouselHtml();
      expect(ThreadsResolver.detectMediaType(html), ThreadsMediaType.video);
      final results = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(threadsPostComUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsFnaVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
      expect(results.single.directUrl, isNot(threadsFnaImageUrl));
    });
  });
}
